"""Keep Xcode UI source discovery and fail-closed shard selection in agreement."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "native_test_shards.py"
SPEC = importlib.util.spec_from_file_location("native_test_shards", SCRIPT)
native_test_shards = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(native_test_shards)


class NativeTestShardTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.workflow = self.root / ".github/workflows/ios-prototype.yml"
        self.workflow.parent.mkdir(parents=True)
        self.workflow.write_text("jobs:\n  ui:\n    matrix:\n      shard: [first, second]\n", encoding="utf-8")
        self.source("First.swift", "FirstUITests")
        self.source("Second.swift", "SecondUITests")
        self.shards = {"first": ("FirstUITests",), "second": ("SecondUITests",)}
        self.diagnostics = {}
        for name, value in (("ROOT", self.root), ("SHARDS", self.shards), ("DIAGNOSTIC_SHARDS", self.diagnostics)):
            replacement = patch.object(native_test_shards, name, value)
            replacement.start()
            self.addCleanup(replacement.stop)

    def source(self, relative_path, name):
        path = self.root / "UITests" / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"import XCTest\nfinal class {name}: XCTestCase {{\n    func testExample() {{}}\n}}\n", encoding="utf-8")
        return path

    def test_assigned_class_moved_to_nested_directory_remains_covered(self):
        (self.root / "UITests/First.swift").unlink()
        self.source("Library/Recovery/First.swift", "FirstUITests")
        self.assertEqual(native_test_shards.check(), {"FirstUITests", "SecondUITests"})

    def test_new_unassigned_nested_class_stops_verification(self):
        self.source("Library/Recovery/New.swift", "NewUITests")
        with self.assertRaisesRegex(ValueError, "Missing UI classes.*NewUITests"):
            native_test_shards.check()

    def test_duplicate_class_across_directories_stops_verification(self):
        self.source("Library/Recovery/Copy.swift", "FirstUITests")
        with self.assertRaisesRegex(ValueError, "Duplicate XCTestCase: FirstUITests"):
            native_test_shards.check()

    def test_removed_class_leaves_invalid_stale_assignment(self):
        (self.root / "UITests/First.swift").unlink()
        with self.assertRaisesRegex(ValueError, "stale assignments.*FirstUITests"):
            native_test_shards.check()

    def test_class_cannot_run_in_two_shards(self):
        self.shards["second"] += ("FirstUITests",)
        with self.assertRaisesRegex(ValueError, "assigned to more than one shard"):
            native_test_shards.check()

    def test_missing_unknown_and_duplicate_workflow_shards_fail_closed(self):
        for matrix in ("first", "first, second, unknown", "first, second, second"):
            with self.subTest(matrix=matrix):
                self.workflow.write_text(f"shard: [{matrix}]\n", encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "matrix does not match selectors"):
                    native_test_shards.check()
        self.workflow.write_text("jobs: {}\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Native UI matrix missing"):
            native_test_shards.check()

    def test_unrecognized_test_container_requires_explicit_support(self):
        path = self.root / "UITests/Other.swift"
        for method in ("testExample", "test"):
            with self.subTest(method=method):
                path.write_text(f"struct OtherTests {{ func {method}() {{}} }}\n", encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "outside a recognized XCTestCase"):
                    native_test_shards.check()

    def test_empty_suite_cannot_report_success(self):
        for path in (self.root / "UITests").rglob("*.swift"):
            path.unlink()
        with self.assertRaisesRegex(ValueError, "No UI test classes discovered"):
            native_test_shards.check()

    def test_native_unit_target_and_ui_selectors_remain_distinct(self):
        for command, expected in (
            ("unit", "-only-testing:KeyAndFillTests\n"),
            ("first", "-only-testing:KeyAndFillUITests/FirstUITests\n"),
            ("second", "-only-testing:KeyAndFillUITests/SecondUITests\n"),
        ):
            with self.subTest(command=command):
                output = io.StringIO()
                with patch("sys.argv", [str(SCRIPT), command]), contextlib.redirect_stdout(output):
                    native_test_shards.main()
                self.assertEqual(output.getvalue(), expected)

    def test_unknown_selector_emits_no_unrestricted_test_command(self):
        output = io.StringIO()
        with patch("sys.argv", [str(SCRIPT), "unknown"]), contextlib.redirect_stdout(output):
            with self.assertRaisesRegex(ValueError, "Unknown native test shard"):
                native_test_shards.main()
        self.assertEqual(output.getvalue(), "")

    def diagnostic_source(self):
        self.source("Platform.swift", "PlatformUITests")
        self.diagnostics["platform-audit"] = ("PlatformUITests",)
        workflow = self.root / ".github/workflows/platform-accessibility-diagnostics.yml"
        workflow.write_text("on:\n  workflow_dispatch:\njobs:\n  audit:\n    env:\n      TEST_SHARD: platform-audit\n", encoding="utf-8")
        return workflow

    def test_platform_audit_remains_assigned_and_explicitly_selectable(self):
        self.diagnostic_source()
        self.assertEqual(native_test_shards.check(), {"FirstUITests", "SecondUITests", "PlatformUITests"})
        output = io.StringIO()
        with patch("sys.argv", [str(SCRIPT), "platform-audit"]), contextlib.redirect_stdout(output):
            native_test_shards.main()
        self.assertEqual(output.getvalue(), "-only-testing:KeyAndFillUITests/PlatformUITests\n")

    def test_diagnostic_cannot_be_automatic_unassigned_or_duplicate(self):
        workflow = self.diagnostic_source()
        base = workflow.read_text()
        for source in (base.replace("workflow_dispatch:", "push:"), base + "  schedule:\n",
                       base.replace("platform-audit", "unknown")):
            with self.subTest(source=source), self.assertRaises(ValueError):
                workflow.write_text(source)
                native_test_shards.check()
        workflow.write_text(base)
        self.shards["first"] += ("PlatformUITests",)
        with self.assertRaisesRegex(ValueError, "assigned to more than one"):
            native_test_shards.check()

    def test_required_and_diagnostic_shard_names_cannot_collide(self):
        self.diagnostics["first"] = ("FirstUITests",)
        with self.assertRaisesRegex(ValueError, "both required and diagnostic"):
            native_test_shards.check()

    def execution_log(self, events, target="KeyAndFillUITests"):
        path = self.root / "execution.log"
        path.write_text("\n".join(f"Test Case '-[{target}.{name} {method}]' {event}."
                                  for name, method, event in events), encoding="utf-8")
        return path

    def test_execution_requires_one_start_and_one_pass_for_selected_methods(self):
        path = self.execution_log([("FirstUITests", "testExample", event) for event in ("started", "passed")])
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(native_test_shards.verify_log("first", path), {"FirstUITests.testExample"})

    def test_incomplete_failed_skipped_duplicate_and_unexpected_events_fail(self):
        for events in ([], ["started"], ["passed"], ["started", "failed"],
                       ["started", "skipped"], ["started", "started", "passed"],
                       ["started", "passed", "passed"], ["passed", "started"],
                       ["failed", "started", "passed"], ["skipped", "started", "passed"],
                       ["started", "passed", "cancelled"]):
            with self.subTest(events=events), self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
                native_test_shards.verify_log("first", self.execution_log(
                    [("FirstUITests", "testExample", event) for event in events]))
        events = [(name, "testExample", event) for name in ("FirstUITests", "SecondUITests")
                  for event in ("started", "passed")]
        with self.assertRaisesRegex(ValueError, "SecondUITests"):
            native_test_shards.verify_log("first", self.execution_log(events))

    def test_interleaved_methods_keep_their_individual_order(self):
        source = self.root / "UITests/First.swift"
        source.write_text("class FirstUITests: XCTestCase { func testExample() {} func testOther() {} }")
        path = self.execution_log([
            ("FirstUITests", "testExample", "started"),
            ("FirstUITests", "testOther", "started"),
            ("FirstUITests", "testOther", "passed"),
            ("FirstUITests", "testExample", "passed"),
        ])
        # XCTest can include timestamps and elapsed durations around events.
        content = path.read_text().replace("passed.", "passed (0.123 seconds).")
        path.write_text("Test Suite 'Selected tests' started.\n" +
                        "\n".join("2026-11-25 12:00:00 " + line for line in content.splitlines()))
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(native_test_shards.verify_log("first", path),
                             {"FirstUITests.testExample", "FirstUITests.testOther"})

    def test_foreign_target_cannot_hide_alongside_a_complete_selected_suite(self):
        for target in ("KeyAndFillTests", "OtherTests", "KeyAndFillUITestsExtra"):
            for event in ("started", "passed", "failed", "skipped", "cancelled"):
                with self.subTest(target=target, event=event):
                    path = self.execution_log([
                        ("FirstUITests", "testExample", status) for status in ("started", "passed")
                    ])
                    path.write_text(path.read_text() +
                                    f"\nTest Case '-[{target}.FirstUITests testExample]' {event}.")
                    with self.assertRaisesRegex(ValueError, "Unexpected XCTest target"):
                        native_test_shards.verify_log("first", path)

    def test_foreign_target_cannot_supply_a_missing_selected_event(self):
        path = self.execution_log([("FirstUITests", "testExample", "started")])
        path.write_text(path.read_text() +
                        "\nTest Case '-[OtherTests.FirstUITests testExample]' passed.")
        report_path = self.root / "accounting.json"
        with self.assertRaisesRegex(ValueError, "Unexpected XCTest target"):
            native_test_shards.verify_log("first", path, report_path)
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["passed"], [])
        self.assertEqual(report["started"], ["FirstUITests.testExample"])

    def test_unrecognized_case_lines_fail_even_after_all_selected_methods_pass(self):
        malformed = (
            "Test Case 'FirstUITests.testExample()' passed (0.000 seconds).",
            "Test Case '-[KeyAndFillUITests.FirstUITests testExample]' passed unexpectedly.",
            "Test Case '-[KeyAndFillUITests.FirstUITests testExample]'",
            "Test Case without a recognizable identity",
        )
        for line in malformed:
            with self.subTest(line=line):
                path = self.execution_log([
                    ("FirstUITests", "testExample", event) for event in ("started", "passed")
                ])
                path.write_text(path.read_text() + "\n" + line)
                report_path = self.root / "accounting.json"
                with self.assertRaisesRegex(ValueError, "Unrecognized Test Case line"):
                    native_test_shards.verify_log("first", path, report_path)
                report = json.loads(report_path.read_text())
                self.assertEqual(report["status"], "failed")
                self.assertEqual(report["invalid"], [{
                    "line": 3, "text": line, "reason": "Unrecognized Test Case line",
                }])

    def test_unrecognized_event_and_non_test_method_are_not_ignored(self):
        for method, event in (("testExample", "cancelled"), ("helper", "passed")):
            with self.subTest(method=method, event=event):
                path = self.execution_log([
                    ("FirstUITests", "testExample", "started"),
                    ("FirstUITests", "testExample", "passed"),
                    ("FirstUITests", method, event),
                ])
                with self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
                    native_test_shards.verify_log("first", path)

    def test_report_preserves_expected_passed_failed_skipped_and_missing_methods(self):
        source = self.root / "UITests/First.swift"
        source.write_text("class FirstUITests: XCTestCase { " + " ".join(
            f"func {name}() {{}}" for name in ("testExample", "testFailed", "testSkipped", "testMissing")
        ) + " }")
        path = self.execution_log([
            ("FirstUITests", method, event)
            for method, terminal in (("testExample", "passed"), ("testFailed", "failed"), ("testSkipped", "skipped"))
            for event in ("started", terminal)
        ])
        report_path = self.root / "accounting.json"
        output = io.StringIO()
        with contextlib.redirect_stdout(output), self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
            native_test_shards.verify_log("first", path, report_path)
        self.assertEqual(output.getvalue(), "")
        report = json.loads(report_path.read_text())
        self.assertEqual(report["schema"], 1)
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["target"], "KeyAndFillUITests")
        self.assertEqual(report["expected"], [f"FirstUITests.{name}" for name in
                                             ("testExample", "testFailed", "testMissing", "testSkipped")])
        self.assertEqual(report["started"], [f"FirstUITests.{name}" for name in
                                            ("testExample", "testFailed", "testSkipped")])
        self.assertEqual(report["passed"], ["FirstUITests.testExample"])
        self.assertEqual(report["failed"], ["FirstUITests.testFailed"])
        self.assertEqual(report["skipped"], ["FirstUITests.testSkipped"])
        self.assertEqual(report["unstarted"], ["FirstUITests.testMissing"])
        self.assertEqual([item["method"] for item in report["invalid"]],
                         ["FirstUITests.testFailed", "FirstUITests.testMissing", "FirstUITests.testSkipped"])
        self.assertEqual(report["invalid"][0]["events"],
                         [{"line": 3, "event": "started"}, {"line": 4, "event": "failed"}])
        self.assertEqual(report["invalid"][1]["events"], [])

    def test_failed_ordering_replaces_a_previous_passing_report(self):
        report_path = self.root / "reports/accounting.json"
        path = self.execution_log([("FirstUITests", "testExample", event) for event in ("started", "passed")])
        with contextlib.redirect_stdout(io.StringIO()):
            native_test_shards.verify_log("first", path, report_path)
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["passed"], ["FirstUITests.testExample"])
        for category in ("failed", "skipped", "unstarted", "invalid"):
            self.assertEqual(report[category], [])
        path = self.execution_log([("FirstUITests", "testExample", event) for event in ("passed", "started")])
        with self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
            native_test_shards.verify_log("first", path, report_path)
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["passed"], [])
        self.assertEqual(report["expected"], ["FirstUITests.testExample"])
        self.assertEqual(report["invalid"][0]["events"],
                         [{"line": 1, "event": "passed"}, {"line": 2, "event": "started"}])

    def test_missing_log_writes_failed_report_with_expected_unstarted_inventory(self):
        report_path = self.root / "accounting.json"
        with self.assertRaises(OSError):
            native_test_shards.verify_log("first", self.root / "missing.log", report_path)
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["expected"], ["FirstUITests.testExample"])
        self.assertEqual(report["unstarted"], report["expected"])
        self.assertEqual(report["started"], [])
        self.assertEqual(report["passed"], [])
        self.assertTrue(report["invalid"])

    def test_inventory_and_unknown_shard_failures_still_write_failed_reports(self):
        report_path = self.root / "accounting.json"
        source = self.root / "UITests/First.swift"
        source.write_text("class A: XCTestCase { func testA() {} }\nclass B: XCTestCase { func testB() {} }")
        for shard, error in (("first", "Ambiguous XCTest method inventory"), ("unknown", "Unknown native test shard")):
            with self.subTest(shard=shard), self.assertRaisesRegex(ValueError, error):
                native_test_shards.verify_log(shard, self.root / "missing.log", report_path)
            report = json.loads(report_path.read_text())
            self.assertEqual(report["status"], "failed")
            self.assertEqual(report["passed"], [])
            self.assertIn(error, report["invalid"][0]["reason"])

    def test_cli_verification_supports_legacy_usage_and_optional_report(self):
        path = self.execution_log([("FirstUITests", "testExample", event) for event in ("started", "passed")])
        report_path = self.root / "accounting.json"
        for extra in ([], ["--report", str(report_path)]):
            output = io.StringIO()
            with self.subTest(extra=extra), patch("sys.argv", [str(SCRIPT), "verify-log", "first", str(path), *extra]), \
                    contextlib.redirect_stdout(output):
                native_test_shards.main()
            self.assertIn("Verified 1 first methods", output.getvalue())
        self.assertEqual(json.loads(report_path.read_text())["status"], "passed")

    def test_cli_reports_execution_failure_without_emitting_success(self):
        path = self.execution_log([("FirstUITests", "testExample", "skipped")])
        report_path = self.root / "accounting.json"
        output = io.StringIO()
        with patch("sys.argv", [str(SCRIPT), "verify-log", "first", str(path), "--report", str(report_path)]), \
                contextlib.redirect_stdout(output), self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
            native_test_shards.main()
        self.assertEqual(output.getvalue(), "")
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["passed"], [])
        self.assertEqual(report["skipped"], ["FirstUITests.testExample"])
        self.assertEqual(report["unstarted"], ["FirstUITests.testExample"])

    def test_cli_preflight_failure_writes_a_failed_report(self):
        self.workflow.write_text("jobs: {}\n")
        report_path = self.root / "accounting.json"
        with patch("sys.argv", [str(SCRIPT), "verify-log", "first", "missing.log", "--report", str(report_path)]), \
                self.assertRaisesRegex(ValueError, "Native UI matrix missing"):
            native_test_shards.main()
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["passed"], [])
        self.assertEqual(report["invalid"], [{"reason": "Native UI matrix missing"}])

    def test_native_inventory_is_separate_and_empty_selection_cannot_pass(self):
        directory = self.root / "NativeTests"
        directory.mkdir()
        (directory / "Unit.swift").write_text("final class UnitTests: XCTestCase { func testNative() {} }")
        log = self.execution_log([("UnitTests", "testNative", event) for event in ("started", "passed")], "KeyAndFillTests")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(native_test_shards.verify_log("unit", log), {"UnitTests.testNative"})
        self.shards["first"] = ("MissingUITests",)
        with self.assertRaisesRegex(ValueError, "no methods"):
            native_test_shards.verify_log("first", log)

    def test_bare_test_method_is_inventoried_and_requires_execution(self):
        directory = self.root / "NativeTests"
        directory.mkdir()
        (directory / "Unit.swift").write_text(
            "final class UnitTests: XCTestCase { func testNative() {} func test() {} }")
        self.assertEqual(native_test_shards.discover_methods("NativeTests"),
                         {"UnitTests": {"testNative", "test"}})
        log = self.execution_log([
            ("UnitTests", "testNative", event) for event in ("started", "passed")
        ], "KeyAndFillTests")
        report_path = self.root / "accounting.json"
        with self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
            native_test_shards.verify_log("unit", log, report_path)
        report = json.loads(report_path.read_text())
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["expected"], ["UnitTests.test", "UnitTests.testNative"])
        self.assertEqual(report["passed"], ["UnitTests.testNative"])
        self.assertEqual(report["unstarted"], ["UnitTests.test"])
        log = self.execution_log([
            ("UnitTests", method, event) for method in ("testNative", "test")
            for event in ("started", "passed")
        ], "KeyAndFillTests")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(native_test_shards.verify_log("unit", log),
                             {"UnitTests.testNative", "UnitTests.test"})

    def test_ambiguous_method_container_fails_inventory(self):
        path = self.root / "UITests/First.swift"
        path.write_text("class A: XCTestCase { func testA() {} }\nclass B: XCTestCase { func testB() {} }")
        with self.assertRaisesRegex(ValueError, "Ambiguous XCTest method inventory"):
            native_test_shards.discover_methods("UITests")


class RepositoryBetaWorkflowShardTests(unittest.TestCase):
    """The real beta workflows must be selected and accounted for by existing CI."""

    methods = {
        "testWelcomeDismissalPersistsAndInitialActionsNeedNoDefaultSave",
        "testInitialProjectNameEditorSavesOnlyRequestedProjectAndReopens",
        "testUnreadableLibraryRecoveryNeedsConfirmationAndSurvivesRelaunch",
        "testFeedbackExactReviewBackAndDiscardExcludePrivateProjectData",
    }

    def test_beta_workflows_are_required_in_the_existing_studio_export_shard(self):
        self.assertIn("BetaWorkflowUITests", native_test_shards.check())
        self.assertEqual(native_test_shards.SHARDS["studio-export"],
                         ("StudioSmokeTests", "LightingPlanExportUITests", "BetaWorkflowUITests", "PlanGestureUITests", "BetaAccessibilityUITests"))
        self.assertEqual(native_test_shards.discover_methods("UITests")["BetaWorkflowUITests"], self.methods)
        output = io.StringIO()
        with patch("sys.argv", [str(SCRIPT), "studio-export"]), contextlib.redirect_stdout(output):
            native_test_shards.main()
        self.assertEqual(output.getvalue().splitlines(), [
            "-only-testing:KeyAndFillUITests/StudioSmokeTests",
            "-only-testing:KeyAndFillUITests/LightingPlanExportUITests",
            "-only-testing:KeyAndFillUITests/BetaWorkflowUITests",
            "-only-testing:KeyAndFillUITests/PlanGestureUITests",
            "-only-testing:KeyAndFillUITests/BetaAccessibilityUITests",
        ])

    def test_studio_export_execution_cannot_omit_the_beta_methods(self):
        inventory = native_test_shards.discover_methods("UITests")
        selected = native_test_shards.SHARDS["studio-export"]
        beta = {f"BetaWorkflowUITests.{method}" for method in self.methods}
        existing = {f"{name}.{method}" for name in selected if name != "BetaWorkflowUITests"
                    for method in inventory[name]}

        def events(methods):
            # Synthetic log fixtures test accounting only, never native execution.
            return "\n".join(
                f"Test Case '-[KeyAndFillUITests.{name} {method}]' {event}."
                for item in sorted(methods) for name, method in [item.split(".", 1)]
                for event in ("started", "passed")
            )

        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "synthetic-studio-export.log"
            report_path = Path(directory) / "accounting.json"
            log.write_text(events(existing), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
                native_test_shards.verify_log("studio-export", log, report_path)
            report = json.loads(report_path.read_text())
            self.assertEqual(report["status"], "failed")
            self.assertEqual(set(report["expected"]), existing | beta)
            self.assertEqual(set(report["passed"]), existing)
            self.assertEqual(set(report["unstarted"]), beta)

            log.write_text(events(existing | beta), encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                verified = native_test_shards.verify_log("studio-export", log, report_path)
            self.assertEqual(verified, existing | beta)
            self.assertEqual(json.loads(report_path.read_text())["status"], "passed")


class RepositoryPlanGestureShardTests(unittest.TestCase):
    """Real marker drags belong to the required suite and its exact accounting."""

    methods = {
        "testShortFastSelectedMarkerDragChangesPositionAndUndoRedoRestoresExactly",
        "testFreshDragAfterCompletionCreatesASeparateUndoableEdit",
        "testFreshDragAfterBackgroundResumeKeepsPriorPositionAndHistory",
    }

    def test_plan_gestures_are_required_in_the_existing_studio_export_shard(self):
        self.assertIn("PlanGestureUITests", native_test_shards.check())
        self.assertEqual(native_test_shards.discover_methods("UITests")["PlanGestureUITests"], self.methods)
        self.assertIn("PlanGestureUITests", native_test_shards.SHARDS["studio-export"])

    def test_studio_export_execution_cannot_omit_a_plan_gesture(self):
        inventory = native_test_shards.discover_methods("UITests")
        expected = {f"{name}.{method}" for name in native_test_shards.SHARDS["studio-export"]
                    for method in inventory[name]}

        def events(methods):
            # These fixtures exercise log accounting, never native touch delivery.
            return "\n".join(
                f"Test Case '-[KeyAndFillUITests.{name} {method}]' {event}."
                for item in sorted(methods) for name, method in [item.split(".", 1)]
                for event in ("started", "passed")
            )

        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "synthetic-plan-gesture-accounting.log"
            report_path = Path(directory) / "accounting.json"
            for method in sorted(self.methods):
                missing = f"PlanGestureUITests.{method}"
                with self.subTest(missing=missing):
                    log.write_text(events(expected - {missing}), encoding="utf-8")
                    with self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
                        native_test_shards.verify_log("studio-export", log, report_path)
                    report = json.loads(report_path.read_text())
                    self.assertEqual(report["status"], "failed")
                    self.assertEqual(set(report["expected"]), expected)
                    self.assertEqual(set(report["passed"]), expected - {missing})
                    self.assertEqual(report["unstarted"], [missing])

            log.write_text(events(expected), encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(native_test_shards.verify_log("studio-export", log, report_path), expected)
            self.assertEqual(json.loads(report_path.read_text())["status"], "passed")


if __name__ == "__main__":
    unittest.main()
