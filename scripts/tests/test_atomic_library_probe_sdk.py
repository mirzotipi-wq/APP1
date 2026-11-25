#!/usr/bin/env python3
"""Host-SDK command/provenance regressions; child execution is mocked entirely."""

import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "run_atomic_library_write_probe.py"
SPEC = importlib.util.spec_from_file_location("atomic_probe_wrapper", SCRIPT)
wrapper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(wrapper)


class AtomicLibraryProbeSDKTests(unittest.TestCase):
    def run_wrapper(self, host="Darwin", sdk_output="valid", sdk_code=0,
                    sdk_timeout=False, xcrun_available=True):
        with tempfile.TemporaryDirectory(prefix="atomic SDK regression ") as temporary:
            root = Path(temporary)
            repository = root / "repository"
            (repository / "Sources" / "LightingCore").mkdir(parents=True)
            (repository / "Sources" / "LightingCore" / "Fixture.swift").write_text("// fixture\n")
            (repository / "scripts").mkdir()
            for name in ("probe-atomic-library-write.swift", "probe_atomic_library_write.py",
                         "run_atomic_library_write_probe.py"):
                (repository / "scripts" / name).write_text("// fixture\n")
            real_sdk = root / "Selected Xcode" / "MacOSX Host SDK.sdk"
            real_sdk.mkdir(parents=True)
            sdk = root / "MacOSX.sdk"
            sdk.symlink_to(real_sdk, target_is_directory=True)
            regular_file = root / "not-an-sdk"
            regular_file.write_text("not a directory")
            values = {
                "valid": str(sdk) + "\n", "empty": "\n", "relative": "MacOSX.sdk\n",
                "missing": str(root / "missing.sdk") + "\n", "file": str(regular_file) + "\n",
                "multiline": str(sdk) + "\nextra\n", "invalid-utf8": b"\xff\n",
            }
            compiler = str(root / "Selected Xcode" / "usr" / "bin" / "swiftc")
            xcrun = str(root / "usr" / "bin" / "xcrun")
            output = root / "evidence"
            commands = []
            environment = {"DEVELOPER_DIR": str(root / "Selected Xcode" / "Contents" / "Developer"),
                           "TOOLCHAINS": "com.apple.dt.toolchain.XcodeDefault", "SDKROOT": "iphonesimulator"}

            def which(name):
                if name == "swiftc":
                    return compiler
                if name == "xcrun":
                    return xcrun if xcrun_available else None
                self.fail("Unexpected executable lookup: " + name)

            def run_logged(arguments, cwd, destination, name, timeout, **kwargs):
                commands.append({"name": name, "arguments": arguments, "timeout": timeout,
                                 "environment": {key: os.environ.get(key) for key in environment}})
                stdout, stderr = b"", b""
                observation = {"arguments": arguments, "cwd": str(cwd), "timeoutSeconds": timeout,
                               "returnCode": 0}
                if name == "source-revision":
                    stdout = b"controlled-fixture-revision\n"
                elif name == "compiler-version":
                    stdout = b"controlled compiler stub; no compiler executed\n"
                elif name == "macos-sdk":
                    value = values[sdk_output]
                    stdout = value if isinstance(value, bytes) else value.encode("utf-8")
                    stderr = b"retained SDK lookup diagnostic\n"
                    if sdk_timeout:
                        observation.pop("returnCode")
                        observation["timedOut"] = True
                    else:
                        observation["returnCode"] = sdk_code
                elif name == "compile":
                    Path(arguments[-1]).write_bytes(b"controlled helper stub; not executable")
                elif name == "probe":
                    probe_output = Path(arguments[arguments.index("--output") + 1])
                    probe_output.mkdir()
                    (probe_output / "result.json").write_text('{"status":"passed"}\n')
                else:
                    self.fail("Unexpected mocked command: " + name)
                (destination / (name + ".stdout.log")).write_bytes(stdout)
                (destination / (name + ".stderr.log")).write_bytes(stderr)
                return observation

            with patch.object(wrapper, "__file__", str(repository / "scripts" / SCRIPT.name)), \
                    patch.object(wrapper.platform, "system", return_value=host), \
                    patch.object(wrapper.shutil, "which", side_effect=which), \
                    patch.object(wrapper, "run_logged", side_effect=run_logged), \
                    patch.object(wrapper, "observe_target_filesystem", side_effect=lambda target, *args:
                                 {"status": "observed", "requestedTargetPath": str(target),
                                  "fixture": "filesystem commands mocked; covered by dedicated tests"}), \
                    patch.object(wrapper.subprocess, "Popen", side_effect=AssertionError("No actual child allowed")), \
                    patch.dict(os.environ, environment), \
                    patch.object(wrapper.sys, "argv", [str(SCRIPT), "--output", str(output)]), \
                    contextlib.redirect_stdout(io.StringIO()):
                code = wrapper.main()
            manifest = json.loads((output / "compile-manifest.json").read_text())
            report = json.loads((output / "wrapper-result.json").read_text())
            logs = {path.name: path.read_bytes() for path in output.glob("*.log")}
            return {"code": code, "manifest": manifest, "report": report, "commands": commands,
                    "sdk": str(sdk), "resolvedSDK": str(real_sdk), "compiler": compiler,
                    "xcrun": xcrun, "environment": environment, "logs": logs}

    def assert_no_compile_or_probe(self, result):
        self.assertEqual(result["code"], 1)
        self.assertEqual(result["report"]["status"], "failed")
        self.assertFalse({"compile", "probe"} & {command["name"] for command in result["commands"]})

    def test_darwin_explicit_host_sdk_preserves_selection_and_path_argument(self):
        result = self.run_wrapper()
        self.assertEqual(result["code"], 0)
        lookup = next(command for command in result["commands"] if command["name"] == "macos-sdk")
        self.assertEqual(lookup["arguments"], [result["xcrun"], "--sdk", "macosx", "--show-sdk-path"])
        self.assertEqual(lookup["timeout"], 10)
        self.assertEqual(lookup["environment"], result["environment"])
        sdk = result["manifest"]["hostSDK"]
        self.assertEqual(sdk["name"], "macosx")
        self.assertEqual(sdk["path"], result["sdk"])
        self.assertEqual(sdk["resolvedPath"], result["resolvedSDK"])
        self.assertEqual(sdk["environment"], result["environment"])
        self.assertEqual(result["manifest"]["compileArguments"][:4],
                         [result["compiler"], "-O", "-sdk", result["sdk"]])

    def test_linux_never_discovers_or_adds_an_apple_sdk(self):
        result = self.run_wrapper(host="Linux")
        self.assertEqual(result["code"], 0)
        self.assertNotIn("hostSDK", result["manifest"])
        self.assertNotIn("macos-sdk", [command["name"] for command in result["commands"]])
        self.assertNotIn("-sdk", result["manifest"]["compileArguments"])
        self.assertEqual(result["manifest"]["compileArguments"][:3],
                         [result["compiler"], "-O", "-module-cache-path"])

    def test_failed_sdk_lookup_retains_receipt_and_blocks_compiler(self):
        result = self.run_wrapper(sdk_code=1)
        self.assert_no_compile_or_probe(result)
        self.assertEqual(result["manifest"]["hostSDK"]["discovery"]["returnCode"], 1)
        self.assertIn(b"retained SDK lookup diagnostic", result["logs"]["macos-sdk.stderr.log"])

    def test_sdk_timeout_retains_receipt_and_blocks_compiler(self):
        result = self.run_wrapper(sdk_timeout=True)
        self.assert_no_compile_or_probe(result)
        self.assertTrue(result["manifest"]["hostSDK"]["discovery"]["timedOut"])

    def test_invalid_sdk_paths_block_compiler(self):
        for value in ("empty", "relative", "missing", "file", "multiline"):
            with self.subTest(value=value):
                result = self.run_wrapper(sdk_output=value)
                self.assert_no_compile_or_probe(result)
                self.assertIn("path", result["manifest"]["hostSDK"])

    def test_invalid_sdk_encoding_keeps_raw_output_and_receipt(self):
        result = self.run_wrapper(sdk_output="invalid-utf8")
        self.assert_no_compile_or_probe(result)
        self.assertEqual(result["logs"]["macos-sdk.stdout.log"], b"\xff\n")
        self.assertEqual(result["manifest"]["hostSDK"]["discovery"]["returnCode"], 0)

    def test_missing_xcrun_retains_selection_and_blocks_compiler(self):
        result = self.run_wrapper(xcrun_available=False)
        self.assert_no_compile_or_probe(result)
        self.assertEqual(result["manifest"]["hostSDK"]["environment"], result["environment"])


if __name__ == "__main__":
    unittest.main()
