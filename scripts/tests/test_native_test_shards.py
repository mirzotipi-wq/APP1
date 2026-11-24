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
        for name, value in (("ROOT", self.root), ("SHARDS", self.shards)):
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


if __name__ == "__main__":
    unittest.main()
