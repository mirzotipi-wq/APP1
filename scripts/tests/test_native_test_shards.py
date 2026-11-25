"""Keep Xcode UI source discovery and fail-closed shard selection in agreement."""
import contextlib
import importlib.util
import io
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
        path.write_text("struct OtherTests { func testExample() {} }\n", encoding="utf-8")
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
                       ["started", "passed", "passed"]):
            with self.subTest(events=events), self.assertRaisesRegex(ValueError, "Incomplete XCTest execution"):
                native_test_shards.verify_log("first", self.execution_log(
                    [("FirstUITests", "testExample", event) for event in events]))
        events = [(name, "testExample", event) for name in ("FirstUITests", "SecondUITests")
                  for event in ("started", "passed")]
        with self.assertRaisesRegex(ValueError, "SecondUITests"):
            native_test_shards.verify_log("first", self.execution_log(events))

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

    def test_ambiguous_method_container_fails_inventory(self):
        path = self.root / "UITests/First.swift"
        path.write_text("class A: XCTestCase { func testA() {} }\nclass B: XCTestCase { func testB() {} }")
        with self.assertRaisesRegex(ValueError, "Ambiguous XCTest method inventory"):
            native_test_shards.discover_methods("UITests")


if __name__ == "__main__":
    unittest.main()
