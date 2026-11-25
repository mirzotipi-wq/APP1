#!/usr/bin/env python3
"""Filesystem provenance regressions; metadata command execution is mocked.

Darwin cases are controlled parser/device-join fixtures, not macOS execution.
Only temporary test files are created; no persistence failure is injected.
"""

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
SPEC = importlib.util.spec_from_file_location("atomic_filesystem_wrapper", SCRIPT)
wrapper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(wrapper)


class AtomicLibraryProbeFilesystemTests(unittest.TestCase):
    def observe(self, host="Linux", transform=None, failed_command=None, timed_out=False,
                missing_command=None):
        with tempfile.TemporaryDirectory(prefix="atomic filesystem regression ") as temporary:
            root = Path(temporary)
            output = root / "evidence"
            output.mkdir()
            target = root / "Users" / "A Photographer" / "projects.json"
            target.parent.mkdir(parents=True)
            target.write_bytes(b"controlled test fixture")
            mounted = root / "System" / "Volumes" / "Data volume"
            mounted.mkdir(parents=True)
            device = target.stat().st_dev
            major_minor = f"{os.major(device)}:{os.minor(device)}"
            texts = {
                "findmnt": json.dumps({"filesystems": [{"target": str(mounted), "source": "/dev/test",
                                                        "fstype": "ext4", "maj:min": major_minor}]}),
                "df": "Filesystem 1024-blocks Used Available Capacity Mounted on\n"
                      f"/dev/disk3s5 1000 100 900 10% {mounted}\n",
                "mount": f"/dev/disk3s1s1 on {root} (apfs, sealed, local, read-only)\n"
                         f"/dev/disk3s5 on {mounted} (apfs, local, journaled)\n",
            }
            if transform:
                transform(texts, mounted, target)
            calls = []

            def run_logged(arguments, repository, destination, name, timeout, **kwargs):
                executable = Path(arguments[0]).name
                calls.append({"arguments": arguments, "timeout": timeout, **kwargs})
                stdout = texts[executable]
                stdout = stdout if isinstance(stdout, bytes) else stdout.encode("utf-8")
                (destination / (name + ".stdout.log")).write_bytes(stdout)
                (destination / (name + ".stderr.log")).write_bytes(b"retained metadata diagnostic\n")
                receipt = {"arguments": arguments, "cwd": str(repository), "timeoutSeconds": timeout,
                           "returnCode": 0, "stdoutPath": str(destination / (name + ".stdout.log")),
                           "stderrPath": str(destination / (name + ".stderr.log"))}
                if executable == failed_command:
                    if timed_out:
                        receipt.pop("returnCode")
                        receipt["timedOut"] = True
                        receipt["timeoutCleanup"] = "fixture: owned process group reaped"
                    else:
                        receipt["returnCode"] = 7
                return receipt

            with patch.object(wrapper.platform, "system", return_value=host), \
                    patch.object(wrapper.shutil, "which", side_effect=lambda name:
                                 None if name == missing_command else "/observed/bin/" + name), \
                    patch.object(wrapper, "run_logged", side_effect=run_logged), \
                    patch.object(wrapper.subprocess, "Popen", side_effect=AssertionError("No actual child allowed")):
                result = wrapper.observe_target_filesystem(target, root, output, "filesystem-target")
            return result, calls, {p.name: p.read_bytes() for p in output.glob("*.log")}

    def test_linux_matches_the_actual_target_device_and_retains_command(self):
        result, calls, _ = self.observe()
        self.assertEqual(result["status"], "observed")
        self.assertEqual(result["selectedFilesystem"]["type"], "ext4")
        self.assertEqual(result["targetStat"]["device"], result["mountStat"]["device"])
        self.assertTrue(result["targetIdentityUnchangedDuringObservation"])
        self.assertEqual(calls[0]["arguments"],
                         ["/observed/bin/findmnt", "--json", "--target", result["targetPath"],
                          "--output", "TARGET,SOURCE,FSTYPE,MAJ:MIN", "--first-only"])
        self.assertEqual(calls[0]["timeout"], 10)
        self.assertEqual(calls[0]["environment_overrides"], {"LC_ALL": "C", "LANG": "C"})

    def test_linux_mismatched_device_fails_without_relabeling(self):
        def mismatched(texts, _mount, _target):
            parsed = json.loads(texts["findmnt"])
            parsed["filesystems"][0]["maj:min"] = "9999:9999"
            texts["findmnt"] = json.dumps(parsed)
        result, _, _ = self.observe(transform=mismatched)
        self.assertEqual(result["status"], "failed")
        self.assertIn("device identity", result["failure"]["message"])
        self.assertEqual(result["selectedFilesystem"]["deviceMajorMinor"], "9999:9999")

    def test_unknown_or_ambiguous_linux_filesystem_cannot_pass(self):
        payloads = ["not JSON", "[]", '{"filesystems": []}',
                    '{"filesystems": [{}, {}]}', '{"filesystems": [{}]}']
        for payload in payloads:
            with self.subTest(payload=payload):
                result, _, _ = self.observe(transform=lambda texts, *_: texts.update(findmnt=payload))
                self.assertEqual(result["status"], "failed")

    def test_missing_linux_type_fails_even_when_device_matches(self):
        def missing_type(texts, _mount, _target):
            parsed = json.loads(texts["findmnt"])
            parsed["filesystems"][0].pop("fstype")
            texts["findmnt"] = json.dumps(parsed)
        result, _, _ = self.observe(transform=missing_type)
        self.assertEqual(result["status"], "failed")
        self.assertIn("type was not observed", result["failure"]["message"])

    def test_darwin_firmlink_uses_df_device_not_lexical_parent_mount(self):
        result, calls, _ = self.observe(host="Darwin")
        self.assertEqual(result["status"], "observed")
        selected = result["selectedFilesystem"]
        self.assertEqual(selected["source"], "/dev/disk3s5")
        self.assertEqual(selected["type"], "apfs")
        self.assertFalse(Path(result["targetPath"]).is_relative_to(selected["mountPoint"]))
        self.assertEqual([Path(call["arguments"][0]).name for call in calls], ["df", "mount"])
        self.assertEqual(calls[0]["arguments"][1:], ["-P", "-k", result["targetPath"]])
        self.assertEqual(result["dfSelection"]["mountPoint"], selected["mountPoint"])

    def test_darwin_inode_columns_and_spaces_preserve_exact_device_mount_join(self):
        def inode_columns(texts, mount, _target):
            texts["df"] = "Filesystem 1024-blocks Used Available Capacity iused ifree %iused Mounted on\n"
            texts["df"] += f"/dev/disk3s5 1000 100 -1 101% 45 200 19% {mount}\n"
        result, _, _ = self.observe(host="Darwin", transform=inode_columns)
        self.assertEqual(result["status"], "observed")
        self.assertTrue(result["selectedFilesystem"]["mountPoint"].endswith("Data volume"))

    def test_darwin_does_not_accept_source_only_or_path_only_matches(self):
        def wrong_pair(texts, mount, target):
            texts["mount"] = (f"/dev/disk3s5 on {target.parent} (apfs, local)\n"
                              f"/dev/different on {mount} (apfs, local)\n")
        result, _, _ = self.observe(host="Darwin", transform=wrong_pair)
        self.assertEqual(result["status"], "failed")
        self.assertIn("device/mount pair", result["failure"]["message"])

    def test_darwin_duplicate_matching_mounts_fail(self):
        result, _, _ = self.observe(host="Darwin", transform=lambda texts, *_:
                                    texts.update(mount=texts["mount"] * 2))
        self.assertEqual(result["status"], "failed")

    def test_command_failure_and_timeout_preserve_exact_status_and_logs(self):
        for timed_out in (False, True):
            with self.subTest(timed_out=timed_out):
                result, _, logs = self.observe(failed_command="findmnt", timed_out=timed_out)
                self.assertEqual(result["status"], "failed")
                receipt = result["commands"][0]
                self.assertEqual(receipt.get("timedOut", False), timed_out)
                self.assertEqual(receipt.get("returnCode"), None if timed_out else 7)
                self.assertEqual(logs["filesystem-target-findmnt.stderr.log"], b"retained metadata diagnostic\n")

    def test_missing_command_retains_requested_command_and_fails(self):
        result, calls, _ = self.observe(missing_command="findmnt")
        self.assertEqual(result["status"], "failed")
        self.assertEqual(calls, [])
        self.assertEqual(result["commands"][0]["requestedArguments"][0], "findmnt")
        self.assertIn("unavailable", result["failure"]["message"])

    def test_invalid_encoding_or_oversized_output_fails_with_raw_logs_retained(self):
        for raw in (b"\xff", b"x" * (wrapper.METADATA_BYTE_CEILING + 1)):
            with self.subTest(size=len(raw)):
                result, _, logs = self.observe(transform=lambda texts, *_: texts.update(findmnt=raw))
                self.assertEqual(result["status"], "failed")
                self.assertEqual(logs["filesystem-target-findmnt.stdout.log"], raw)

    def test_wrapper_blocks_compilation_when_filesystem_identity_is_unobserved(self):
        with tempfile.TemporaryDirectory(prefix="atomic provenance failure ") as temporary:
            output = Path(temporary) / "evidence"
            failed = {"status": "failed", "failure": {"message": "controlled missing filesystem identity"}}
            with patch.object(wrapper.platform, "system", return_value="Linux"), \
                    patch.object(wrapper, "observe_target_filesystem", return_value=failed), \
                    patch.object(wrapper.shutil, "which", side_effect=AssertionError("Compiler lookup forbidden")), \
                    patch.object(wrapper.subprocess, "Popen", side_effect=AssertionError("Child execution forbidden")), \
                    patch.object(wrapper.sys, "argv", [str(SCRIPT), "--output", str(output)]), \
                    contextlib.redirect_stdout(io.StringIO()):
                code = wrapper.main()
            result = json.loads((output / "wrapper-result.json").read_text())
            self.assertEqual(code, 1)
            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["filesystemProvenance"]["observations"], [failed])
            self.assertFalse((output / "compile-manifest.json").exists())


if __name__ == "__main__":
    unittest.main()
