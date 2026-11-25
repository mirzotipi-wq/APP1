"""Synthetic-tool control-flow tests on the host; no Apple startup is exercised."""

import argparse
import importlib.util
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "boot_simulator.py"
UDID = "12FCFD0F-7FCF-463F-A605-132A7E18B5D5"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"

SPEC = importlib.util.spec_from_file_location("boot_simulator", SCRIPT)
BOOT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BOOT)


SYNTHETIC_XCRUN = r'''#!/usr/bin/env python3
import json, os, pathlib, signal, subprocess, sys, time
root = pathlib.Path(os.environ["KEYFILL_STARTUP_TEST_DIRECTORY"])
config = json.loads((root / "scenario.json").read_text())
arguments = sys.argv[1:]
with (root / "calls.jsonl").open("a") as stream:
    stream.write(json.dumps({"arguments": arguments, "pid": os.getpid()}) + "\n")
assert arguments[0] == "simctl", arguments
operation = arguments[1]
state_path = root / "state.json"
state = json.loads(state_path.read_text()) if state_path.exists() else {
    "deviceState": config.get("initial_state", "Shutdown"), "counts": {}}
index = state["counts"].get(operation, 0)
state["counts"][operation] = index + 1
outcomes = config.get(operation, [])
outcome = outcomes[index] if index < len(outcomes) else {}
if operation == "boot":
    state["deviceState"] = outcome.get("next_state", "Booted")
elif operation == "shutdown" and not outcome.get("exit", 0):
    state["deviceState"] = outcome.get("next_state", "Shutdown")
elif operation == "bootstatus":
    state["deviceState"] = outcome.get("next_state", "Booted")
state_path.write_text(json.dumps(state))
if operation == "list":
    assert arguments == ["simctl", "list", "devices", "available", "-j"], arguments
    if outcome.get("malformed"):
        print("{ invalid inventory", flush=True)
    else:
        device = {"name": "iPhone 17 Pro", "udid": config["udid"],
                  "deviceTypeIdentifier": outcome.get("device_type", config["device_type"]),
                  "isAvailable": outcome.get("available", True),
                  "state": outcome.get("state", state["deviceState"])}
        devices = [] if outcome.get("missing") else [device]
        if outcome.get("duplicate"):
            devices.append(dict(device))
        print(json.dumps({"devices": {outcome.get("runtime", config["runtime"]): devices}}), flush=True)
else:
    assert arguments[2] == config["udid"], arguments
    assert operation in ("boot", "bootstatus", "shutdown"), arguments
    print(outcome.get("stdout", f"synthetic {operation} {index + 1}"), flush=True)
    print(outcome.get("stderr", f"synthetic stderr {operation} {index + 1}"), file=sys.stderr, flush=True)
if outcome.get("spawn_child"):
    child = subprocess.Popen([sys.executable, "-c",
        "import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)"])
    (root / "child.pid").write_text(str(child.pid))
(root / "active").write_text(operation)
if outcome.get("signal"):
    os.kill(os.getpid(), outcome["signal"])
time.sleep(outcome.get("sleep", 0))
sys.exit(outcome.get("exit", 0))
'''


class BootSimulatorTests(unittest.TestCase):
    def run_case(self, scenario=None, *, budget=8, hosted=True, cancel=False,
                 existing_output=False, before_cleanup=None):
        scenario = dict(scenario or {}, udid=UDID, runtime=RUNTIME, device_type=DEVICE_TYPE)
        with tempfile.TemporaryDirectory(prefix="keyfill-startup-test-") as temporary:
            root = Path(temporary)
            tool = root / "xcrun"
            tool.write_text(SYNTHETIC_XCRUN)
            tool.chmod(0o755)
            (root / "scenario.json").write_text(json.dumps(scenario))
            output = root / "evidence"
            if existing_output:
                output.mkdir()
                (output / "report.json").write_text('{"status":"earlier evidence"}\n')
            environment = dict(os.environ, KEYFILL_STARTUP_TEST_DIRECTORY=str(root),
                               PATH=str(root) + os.pathsep + os.environ["PATH"],
                               GITHUB_ACTIONS="true", RUNNER_ENVIRONMENT="github-hosted" if hosted else "self-hosted")
            arguments = [sys.executable, str(SCRIPT), "--udid", UDID, "--runtime", RUNTIME,
                         "--device-type", DEVICE_TYPE, "--output", str(output),
                         "--timeout-seconds=" + str(budget)]
            started = time.monotonic()
            process = subprocess.Popen(arguments, env=environment, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, text=True, start_new_session=True)
            calls = []
            try:
                if cancel:
                    until = time.monotonic() + 4
                    while time.monotonic() < until:
                        if (root / "active").exists() and (root / "active").read_text() == "bootstatus":
                            break
                        if process.poll() is not None:
                            self.fail("Helper exited before the cancellation fixture reached bootstatus")
                        time.sleep(0.01)
                    else:
                        self.fail("Synthetic bootstatus did not start")
                    os.kill(process.pid, signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=10)
                elapsed = time.monotonic() - started
                result = subprocess.CompletedProcess(arguments, process.returncode, stdout, stderr)
                report = json.loads((output / "report.json").read_text()) if (output / "report.json").exists() else None
                calls = [json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()] \
                    if (root / "calls.jsonl").exists() else []
                artifacts = {path.name: path.read_text() for path in output.glob("*")} if output.exists() else {}
                if before_cleanup:
                    before_cleanup(root, report)
                if report and "commands" in report:
                    for command in report["commands"]:
                        self.assertIn(command["stdoutPath"], artifacts)
                        self.assertIn(command["stderrPath"], artifacts)
                        stem = command["stdoutPath"].removesuffix(".stdout.log")
                        self.assertEqual(json.loads(artifacts[stem + ".result.json"]), command)
                    for call in calls:
                        command = call["arguments"]
                        if command[1] != "list":
                            self.assertEqual(command[2], UDID)
                            self.assertIn(command[1], ("boot", "bootstatus", "shutdown"))
                    self.assertLessEqual(sum(call["arguments"][1] == "boot" for call in calls), 2)
                    self.assertLessEqual(sum(call["arguments"][1] == "shutdown" for call in calls), 1)
                return result, report, calls, artifacts, elapsed
            finally:
                # Test failures must not leave the synthetic processes behind.
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.communicate(timeout=2)
                if (root / "calls.jsonl").exists():
                    calls = [json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()]
                for call in calls:
                    try:
                        os.killpg(call["pid"], signal.SIGKILL)
                    except ProcessLookupError:
                        pass

    @staticmethod
    def operations(calls):
        return [call["arguments"][1] for call in calls]

    def assert_ready(self, result, report):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(report["status"].startswith("ready"))
        self.assertEqual(report["attempts"][-1]["status"], "ready")
        self.assertEqual(report["inventories"][-1]["device"]["state"], "Booted")

    def test_slow_postflight_has_readiness_budget_within_attempt_deadline(self):
        # Scale the production 20/60-second policy to 1/3 seconds. The real
        # synthetic child must finish after the ordinary inventory limit while
        # still respecting both the post-boot limit and shared attempt deadline.
        for delay, budget, ready in [(1.25, 12, True), (3.25, 12, False), (1.25, 1.5, False)]:
            with self.subTest(delay=delay, budget=budget), \
                    tempfile.TemporaryDirectory(prefix="keyfill-slow-postflight-") as temporary:
                root = Path(temporary)
                tool = root / "xcrun"
                tool.write_text(SYNTHETIC_XCRUN)
                tool.chmod(0o755)
                scenario = {"udid": UDID, "runtime": RUNTIME, "device_type": DEVICE_TYPE,
                            "list": [{}, {"sleep": delay}]}
                (root / "scenario.json").write_text(json.dumps(scenario))
                environment = {"KEYFILL_STARTUP_TEST_DIRECTORY": str(root),
                               "PATH": str(root) + os.pathsep + os.environ["PATH"],
                               "GITHUB_ACTIONS": "false", "RUNNER_ENVIRONMENT": "self-hosted"}
                args = argparse.Namespace(output=root / "evidence", timeout_seconds=budget,
                                          udid=UDID, runtime=RUNTIME, device_type=DEVICE_TYPE)
                with mock.patch.dict(os.environ, environment), \
                        mock.patch.object(BOOT, "INVENTORY_TIMEOUT_SECONDS", 1.0), \
                        mock.patch.object(BOOT, "POST_BOOT_INVENTORY_TIMEOUT_SECONDS", 3.0, create=True):
                    startup = BOOT.SimulatorStartup(args, time.monotonic())
                    if ready:
                        startup.run()
                        self.assertEqual(startup.report["attempts"][-1]["status"], "ready")
                    else:
                        with self.assertRaises(BOOT.VerificationFailure):
                            startup.run()
                        self.assertNotEqual(startup.report["attempts"][-1]["status"], "ready")
                        self.assertEqual(startup.report["attempts"][-1]["failure"]["type"], "StartupFailure")
                command = startup.report["commands"][-1]
                self.assertEqual(command["name"], "attempt-1-postflight")
                self.assertEqual(command["status"], "exited" if ready else "timed_out")
                self.assertLessEqual(command["deadlineElapsedSeconds"], startup.first_deadline - startup.started)
                self.assertNotIn("recovery", startup.report)

    def test_normal_startup_requires_bootstatus_and_postflight(self):
        result, report, calls, _, _ = self.run_case()
        self.assert_ready(result, report)
        self.assertEqual(self.operations(calls), ["list", "boot", "bootstatus", "list"])
        self.assertEqual(len(report["attempts"]), 1)

    def test_already_booted_still_requires_bootstatus(self):
        result, report, calls, _, _ = self.run_case({"initial_state": "Booted"})
        self.assert_ready(result, report)
        self.assertEqual(self.operations(calls), ["list", "bootstatus", "list"])

    def test_postflight_timeout_recovers_once_within_shared_budget(self):
        result, report, calls, artifacts, elapsed = self.run_case(
            {"list": [{}, {"sleep": 60, "spawn_child": True}]}, budget=3,
            before_cleanup=self.assert_child_stopped)
        self.assert_ready(result, report)
        self.assertEqual(report["status"], "ready_after_recovery")
        self.assertEqual([attempt["status"] for attempt in report["attempts"]], ["failed", "ready"])
        self.assertEqual(report["attempts"][0]["failure"]["type"], "StartupFailure")
        bootstatus = next(command for command in report["commands"]
                          if command["name"] == "attempt-1-bootstatus")
        self.assertEqual(bootstatus["returnCode"], 0)
        postflight = next(command for command in report["commands"]
                         if command["name"] == "attempt-1-postflight")
        self.assertEqual(postflight["status"], "timed_out")
        self.assertTrue(postflight["cleanup"]["directChildReaped"])
        self.assertIn(UDID, artifacts[postflight["stdoutPath"]])
        self.assertEqual(self.operations(calls),
                         ["list", "boot", "bootstatus", "list", "list", "shutdown", "list",
                          "boot", "bootstatus", "list"])
        self.assertLess(elapsed, 3.5)
        work_budget = report["budgetSeconds"] - report["cleanupReserveSeconds"]
        self.assertTrue(all(command["deadlineElapsedSeconds"] <= work_budget + 0.01
                            for command in report["commands"]))

    def test_two_postflight_timeouts_exhaust_same_budget_after_one_recovery(self):
        result, report, calls, _, elapsed = self.run_case(
            {"list": [{}, {"sleep": 60}, {}, {}, {"sleep": 60}]}, budget=3)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report["status"], "failed")
        self.assertEqual([attempt["status"] for attempt in report["attempts"]], ["failed", "failed"])
        self.assertTrue(all(attempt["failure"]["type"] == "StartupFailure"
                            for attempt in report["attempts"]))
        postflights = [command for command in report["commands"]
                       if command["name"].startswith("attempt-") and command["name"].endswith("-postflight")]
        self.assertEqual([command["status"] for command in postflights], ["timed_out", "timed_out"])
        self.assertTrue(all(command["cleanup"]["directChildReaped"] for command in postflights))
        self.assertEqual(self.operations(calls).count("boot"), 2)
        self.assertEqual(self.operations(calls).count("shutdown"), 1)
        self.assertLess(elapsed, 3.5)
        self.assertLess(report["elapsedSeconds"], 3.15)

    def test_recovery_retains_initial_stderr_and_exit_status(self):
        result, report, calls, artifacts, _ = self.run_case({"bootstatus": [
            {"exit": 17, "stdout": "first attempt nonterminal", "stderr": "original error survives"}, {}]})
        self.assert_ready(result, report)
        self.assertEqual(report["status"], "ready_after_recovery")
        self.assertEqual([attempt["status"] for attempt in report["attempts"]], ["failed", "ready"])
        first = next(command for command in report["commands"] if command["name"] == "attempt-1-bootstatus")
        self.assertEqual(first["returnCode"], 17)
        self.assertEqual(artifacts[first["stdoutPath"]], "first attempt nonterminal\n")
        self.assertEqual(artifacts[first["stderrPath"]], "original error survives\n")
        self.assertEqual(self.operations(calls),
                         ["list", "boot", "bootstatus", "list", "shutdown", "list", "boot", "bootstatus", "list"])

    def test_boot_command_failure_can_recover_without_running_tests(self):
        result, report, calls, _, _ = self.run_case({"boot": [{"exit": 9}, {}]})
        self.assert_ready(result, report)
        self.assertEqual(report["attempts"][0]["status"], "failed")
        self.assertEqual(self.operations(calls).count("boot"), 2)
        self.assertEqual(self.operations(calls).count("bootstatus"), 1)

    def test_both_failures_are_terminal_after_exactly_two_attempts(self):
        result, report, calls, artifacts, _ = self.run_case({"bootstatus": [{"exit": 17}, {"exit": 23}]})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report["status"], "failed")
        self.assertEqual([attempt["status"] for attempt in report["attempts"]], ["failed", "failed"])
        statuses = [command for command in report["commands"] if "bootstatus" in command["name"]]
        self.assertEqual([command["returnCode"] for command in statuses], [17, 23])
        self.assertEqual(self.operations(calls).count("shutdown"), 1)
        self.assertTrue(all(artifacts[command["stderrPath"]] for command in statuses))

    def test_identity_or_malformed_initial_inventory_never_recovers(self):
        for defect in ({"runtime": "another-runtime"}, {"device_type": "another-type"},
                       {"missing": True}, {"duplicate": True}, {"available": False}, {"malformed": True}):
            with self.subTest(defect=defect):
                result, report, calls, _, _ = self.run_case({"list": [defect]})
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.operations(calls), ["list"])
                self.assertEqual(report["attempts"], [])

    def test_recovery_revalidates_identity_and_inventory(self):
        for defect in ({"runtime": "another-runtime"}, {"device_type": "another-type"}, {"malformed": True}):
            with self.subTest(defect=defect):
                result, report, calls, _, _ = self.run_case({"bootstatus": [{"exit": 4}], "list": [{}, defect]})
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(len(report["attempts"]), 1)
                self.assertNotIn("shutdown", self.operations(calls))
                self.assertEqual(report["recovery"]["status"], "failed")

    def test_invalid_postflight_is_terminal_even_after_bootstatus_success(self):
        for defect in ({"runtime": "another-runtime"}, {"device_type": "another-type"},
                       {"missing": True}, {"duplicate": True}, {"available": False},
                       {"malformed": True}, {"state": "unknown"}, {"exit": 9},
                       {"signal": signal.SIGTERM}):
            with self.subTest(defect=defect):
                result, report, calls, _, _ = self.run_case({"list": [{}, defect]})
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.operations(calls), ["list", "boot", "bootstatus", "list"])
                self.assertEqual(len(report["attempts"]), 1)
                self.assertEqual(report["attempts"][0]["failure"]["type"], "VerificationFailure")
                self.assertNotIn("recovery", report)

    def test_postflight_execution_or_timeout_cleanup_failure_is_terminal(self):
        for defect in ({"status": "execution_error", "error": {"message": "cannot execute xcrun"}},
                       {"status": "timed_out", "returnCode": -signal.SIGKILL,
                        "cleanup": {"directChildReaped": False}},
                       {"status": "timed_out", "returnCode": -signal.SIGKILL,
                        "cleanup": {"directChildReaped": True, "error": {"message": "cannot kill group"}}}):
            with self.subTest(defect=defect), \
                    tempfile.TemporaryDirectory(prefix="keyfill-postflight-terminal-") as temporary:
                args = argparse.Namespace(output=Path(temporary) / "evidence", timeout_seconds=8,
                                          udid=UDID, runtime=RUNTIME, device_type=DEVICE_TYPE)
                startup = BOOT.SimulatorStartup(args, time.monotonic())
                bootstatus = {"name": "attempt-1-bootstatus", "status": "exited", "returnCode": 0}
                postflight = dict(defect, name="attempt-1-postflight")
                with mock.patch.object(startup, "command", side_effect=[bootstatus, postflight]), \
                        self.assertRaises(BOOT.VerificationFailure):
                    startup.attempt(1, {"state": "Booted"}, startup.first_deadline)
                self.assertEqual(startup.report["attempts"][0]["failure"]["type"], "VerificationFailure")
                self.assertNotIn("recovery", startup.report)

    def test_bootstatus_success_without_booted_postflight_is_not_ready(self):
        result, report, _, _, _ = self.run_case({"bootstatus": [{"next_state": "Shutdown"}, {"next_state": "Shutdown"}]})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report["status"], "failed")
        self.assertEqual([attempt["status"] for attempt in report["attempts"]], ["failed", "failed"])

    def test_failed_shutdown_blocks_second_attempt_and_preserves_error(self):
        result, report, calls, artifacts, _ = self.run_case({"bootstatus": [{"exit": 4}],
                                                          "shutdown": [{"exit": 31, "stderr": "shutdown error"}]})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(report["attempts"]), 1)
        self.assertEqual(self.operations(calls).count("boot"), 1)
        shutdown = next(command for command in report["commands"] if command["name"] == "recovery-shutdown")
        self.assertEqual(shutdown["returnCode"], 31)
        self.assertEqual(artifacts[shutdown["stderrPath"]], "shutdown error\n")

    def test_unverified_shutdown_blocks_reboot(self):
        result, report, calls, _, _ = self.run_case({"bootstatus": [{"exit": 4}],
                                                  "shutdown": [{"next_state": "Booted"}]})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.operations(calls).count("boot"), 1)
        self.assertEqual(report["recovery"]["status"], "failed")

    def test_non_ephemeral_environment_does_not_shutdown_selected_device(self):
        result, report, calls, _, _ = self.run_case({"bootstatus": [{"exit": 4}]}, hosted=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("shutdown", self.operations(calls))
        self.assertEqual(len(report["attempts"]), 1)
        self.assertIn("GitHub-hosted", report["failure"]["message"])

    def test_two_hung_attempts_share_budget_and_keep_partial_output(self):
        result, report, calls, artifacts, elapsed = self.run_case({"bootstatus": [
            {"sleep": 60, "stdout": "first partial readiness log"},
            {"sleep": 60, "stdout": "second partial readiness log"}]}, budget=2)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.operations(calls).count("bootstatus"), 2)
        self.assertLess(elapsed, 3)
        self.assertLess(report["elapsedSeconds"], 2.15)
        self.assertGreater(report["elapsedSeconds"], 1.5)
        statuses = [command for command in report["commands"] if "bootstatus" in command["name"]]
        self.assertEqual([command["status"] for command in statuses], ["timed_out", "timed_out"])
        self.assertTrue(all(command["cleanup"]["directChildReaped"] for command in statuses))
        self.assertTrue(all(command["deadlineElapsedSeconds"] <= 2 for command in report["commands"]))
        self.assertIn("first partial readiness log", artifacts[statuses[0]["stdoutPath"]])
        self.assertIn("second partial readiness log", artifacts[statuses[1]["stdoutPath"]])

    def assert_child_stopped(self, root, _report):
        child = int((root / "child.pid").read_text())
        until = time.monotonic() + 1
        while time.monotonic() < until:
            try:
                os.kill(child, 0)
            except ProcessLookupError:
                return
            stat = Path(f"/proc/{child}/stat")
            if stat.exists() and stat.read_text().split(") ", 1)[1].split()[0] == "Z":
                return  # A dead grandchild may briefly await the host's reaper.
            time.sleep(0.01)
        self.fail("Timed-out synthetic descendant is still running")

    def test_timeout_kills_owned_descendant_before_recovery(self):
        result, report, _, _, _ = self.run_case({"bootstatus": [{"sleep": 60, "spawn_child": True}, {}]},
                                              budget=2, before_cleanup=self.assert_child_stopped)
        self.assert_ready(result, report)
        self.assertEqual(report["attempts"][0]["status"], "failed")

    def test_successful_command_does_not_leave_owned_descendant_running(self):
        result, report, _, _, _ = self.run_case({"bootstatus": [{"spawn_child": True}]},
                                              before_cleanup=self.assert_child_stopped)
        self.assert_ready(result, report)
        command = next(command for command in report["commands"] if command["name"] == "attempt-1-bootstatus")
        self.assertEqual(command["returnCode"], 0)
        self.assertTrue(command["cleanup"]["signalSent"])

    def test_failed_command_descendant_is_stopped_before_recovery(self):
        result, report, _, _, _ = self.run_case({"bootstatus": [{"exit": 29, "spawn_child": True}, {}]},
                                              before_cleanup=self.assert_child_stopped)
        self.assert_ready(result, report)
        command = next(command for command in report["commands"] if command["name"] == "attempt-1-bootstatus")
        self.assertEqual(command["returnCode"], 29)
        self.assertTrue(command["cleanup"]["signalSent"])

    def test_cancellation_is_terminal_and_cleans_owned_child(self):
        result, report, calls, _, _ = self.run_case({"bootstatus": [{"sleep": 60, "spawn_child": True}]},
                                                  cancel=True, before_cleanup=self.assert_child_stopped)
        self.assertEqual(result.returncode, 128 + signal.SIGTERM)
        self.assertEqual(report["status"], "interrupted")
        self.assertEqual(report["terminationSignal"], signal.SIGTERM)
        self.assertNotIn("shutdown", self.operations(calls))
        self.assertEqual(len(report["attempts"]), 1)
        command = report["commands"][-1]
        self.assertEqual(command["status"], "interrupted")
        self.assertTrue(command["cleanup"]["directChildReaped"])

    def test_tool_signal_is_terminal_not_recovery_trigger(self):
        result, report, calls, _, _ = self.run_case({"bootstatus": [{"signal": signal.SIGTERM}]})
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("shutdown", self.operations(calls))
        self.assertEqual(len(report["attempts"]), 1)
        self.assertEqual(report["commands"][-1]["returnCode"], -signal.SIGTERM)

    def test_finalization_signal_replaces_success_and_restores_handlers(self):
        with tempfile.TemporaryDirectory(prefix="keyfill-startup-finalize-") as temporary:
            output = Path(temporary) / "evidence"
            original_save = BOOT.SimulatorStartup.save
            previous = {number: signal.getsignal(number) for number in (signal.SIGINT, signal.SIGTERM)}

            def ready_fixture(startup):
                startup.report["attempts"].append({"status": "ready"})

            def interrupt_after_success_receipt(startup):
                original_save(startup)
                if startup.report.get("exitCode") == 0:
                    signal.getsignal(signal.SIGTERM)(signal.SIGTERM, None)

            with mock.patch.object(BOOT.SimulatorStartup, "run", ready_fixture), \
                    mock.patch.object(BOOT.SimulatorStartup, "save", interrupt_after_success_receipt):
                code = BOOT.main(["--udid", UDID, "--runtime", RUNTIME,
                                  "--device-type", DEVICE_TYPE, "--output", str(output)])
            self.assertEqual(code, 128 + signal.SIGTERM)
            report = json.loads((output / "report.json").read_text())
            self.assertEqual(report["status"], "interrupted")
            self.assertEqual(report["exitCode"], code)
            self.assertEqual(report["terminationSignal"], signal.SIGTERM)
            self.assertEqual({number: signal.getsignal(number) for number in previous}, previous)

    def test_invalid_budgets_fail_without_tool_calls(self):
        for budget in ("nan", "inf", "-inf", 0, -1, 600.1):
            with self.subTest(budget=budget):
                result, report, calls, _, _ = self.run_case(budget=budget)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(report)
                self.assertEqual(calls, [])

    def test_existing_evidence_is_not_overwritten(self):
        result, report, calls, artifacts, _ = self.run_case(existing_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(report, {"status": "earlier evidence"})
        self.assertEqual(artifacts, {"report.json": '{"status":"earlier evidence"}\n'})
        self.assertEqual(calls, [])

    def test_exit_zero_observed_after_deadline_is_not_success(self):
        with tempfile.TemporaryDirectory(prefix="keyfill-startup-late-") as temporary:
            clock = [100.0]
            args = argparse.Namespace(output=Path(temporary) / "evidence", timeout_seconds=20,
                                      udid=UDID, runtime=RUNTIME, device_type=DEVICE_TYPE)
            with mock.patch.object(BOOT.time, "monotonic", side_effect=lambda: clock[0]):
                startup = BOOT.SimulatorStartup(args, clock[0])
                startup.xcrun = "/synthetic/xcrun"
                child = mock.Mock(pid=900000)

                def wait_after_deadline(**_kwargs):
                    clock[0] = 101.25
                    return 0

                child.wait.side_effect = wait_after_deadline
                with mock.patch.object(BOOT.subprocess, "Popen", return_value=child), \
                        mock.patch.object(BOOT.os, "killpg", side_effect=ProcessLookupError):
                    command = startup.command("late-exit", ["bootstatus", UDID, "-b"], 101.0)
                self.assertEqual(command["returnCode"], 0)
                self.assertTrue(command["deadlineExceeded"])
                with self.assertRaises(BOOT.StartupFailure):
                    startup.require_success(command, startup=True)


if __name__ == "__main__":
    unittest.main()
