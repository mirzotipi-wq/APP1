"""Exercise CI preflight control flow; these are not real Apple compiler tests."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "ensure-metal-toolchain.sh"


class MetalToolchainPreflightTests(unittest.TestCase):
    def run_case(self, *, installed=False, download_fails=False, install_ineffective=False):
        with tempfile.TemporaryDirectory(prefix="keyfill-metal-test-") as temporary:
            root = Path(temporary)
            if installed:
                (root / "installed").touch()
            if download_fails:
                (root / "download-fails").touch()
            if install_ineffective:
                (root / "install-ineffective").touch()
            stub = """#!/usr/bin/env python3
import json, os, pathlib, sys
root = pathlib.Path(os.environ["KEYFILL_METAL_TEST_DIR"])
name = pathlib.Path(sys.argv[0]).name
with (root / "calls.jsonl").open("a") as stream:
    stream.write(json.dumps([name] + sys.argv[1:]) + "\\n")
if name == "xcodebuild":
    if (root / "download-fails").exists():
        sys.exit(9)
    if not (root / "install-ineffective").exists():
        (root / "installed").touch()
elif not (root / "installed").exists():
    print("fixture: missing Metal component", file=sys.stderr)
    sys.exit(7)
else:
    output = pathlib.Path(sys.argv[sys.argv.index("-o") + 1])
    output.write_bytes(b"fixture compiled output")
"""
            for name in ("xcrun", "xcodebuild"):
                tool = root / name
                tool.write_text(stub)
                tool.chmod(0o755)
            environment = dict(os.environ, KEYFILL_METAL_TEST_DIR=str(root),
                               PATH=str(root) + os.pathsep + os.environ["PATH"])
            result = subprocess.run(["bash", str(SCRIPT)], env=environment,
                                    capture_output=True, text=True, timeout=10)
            calls = [json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()]
            # Every probe owns a unique temporary directory, removed on success
            # and failure; the script never deletes the mocked tool directory.
            outputs = [Path(call[call.index("-o") + 1]) for call in calls if "-o" in call]
            self.assertTrue(outputs)
            self.assertTrue(all(not path.parent.exists() for path in outputs))
            self.assertTrue(root.is_dir())
            return result, calls

    def test_installed_compiler_is_exercised_without_downloading(self):
        result, calls = self.run_case(installed=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call[0] for call in calls], ["xcrun", "xcrun"])
        self.assertIn("compile and link probe passed", result.stdout)

    def test_missing_component_is_installed_once_and_retested(self):
        result, calls = self.run_case()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call[0] for call in calls],
                         ["xcrun", "xcodebuild", "xcrun", "xcrun"])
        self.assertEqual(calls[1], ["xcodebuild", "-downloadComponent", "metalToolchain"])

    def test_failed_download_stops_without_claiming_success(self):
        result, calls = self.run_case(download_fails=True)
        self.assertEqual(result.returncode, 9)
        self.assertEqual([call[0] for call in calls], ["xcrun", "xcodebuild"])
        self.assertNotIn("probe passed", result.stdout)

    def test_still_missing_compiler_fails_after_one_install_attempt(self):
        result, calls = self.run_case(install_ineffective=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual([call[0] for call in calls], ["xcrun", "xcodebuild", "xcrun"])
        self.assertNotIn("probe passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
