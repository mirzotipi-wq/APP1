#!/usr/bin/env python3
"""Verify one selected simulator, with at most one CI-only startup recovery.

The default 580-second budget fits inside the existing ten-minute workflow step.
Both attempts, inventory checks, target-only shutdown and child cleanup share
one monotonic deadline. No tests are executed or retried. Recovery is a bounded
hypothesis, not evidence that a hosted CoreSimulator startup defect is repaired.

--output must be a new directory. Raw stdout/stderr, command receipts and the
incremental report remain there even when an attempt fails or is interrupted.
"""

import argparse
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time
import uuid


DEFAULT_TIMEOUT_SECONDS = 580.0
MAX_TIMEOUT_SECONDS = 600.0
MAX_ATTEMPTS = 2
INVENTORY_TIMEOUT_SECONDS = 20.0
POST_BOOT_INVENTORY_TIMEOUT_SECONDS = 60.0
SHUTDOWN_TIMEOUT_SECONDS = 30.0


class StartupFailure(RuntimeError):
    """A boot/readiness failure eligible for one targeted recovery."""


class VerificationFailure(RuntimeError):
    """Identity, tool, cleanup or policy failure; never a recovery trigger."""


class Interrupted(BaseException):
    def __init__(self, number):
        self.number = number
        super().__init__(f"Startup interrupted by signal {number}")


def error_record(error):
    return {"type": type(error).__name__, "message": str(error)}


def write_json(path, value):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


class SimulatorStartup:
    def __init__(self, args, started):
        self.output = args.output.resolve()
        # Never overwrite a previous success or the failed-attempt evidence.
        self.output.mkdir(exist_ok=False)
        self.started = started
        self.deadline = started + args.timeout_seconds
        self.cleanup_reserve = min(5.0, args.timeout_seconds / 10.0)
        self.work_deadline = self.deadline - self.cleanup_reserve
        self.first_deadline = started + (self.work_deadline - started) / 2.0
        self.udid = args.udid
        self.runtime = args.runtime
        self.device_type = args.device_type
        self.xcrun = shutil.which("xcrun")
        self.report = {
            "schema": 1,
            "startedAtUTC": datetime.now(timezone.utc).isoformat(),
            "budgetSeconds": args.timeout_seconds,
            "cleanupReserveSeconds": self.cleanup_reserve,
            "maximumAttempts": MAX_ATTEMPTS,
            "expectedDevice": {"udid": self.udid, "runtime": self.runtime,
                               "deviceTypeIdentifier": self.device_type},
            "recoveryEnvironment": {name: os.environ.get(name) for name in
                                    ("GITHUB_ACTIONS", "RUNNER_ENVIRONMENT")},
            "xcrun": self.xcrun,
            "status": "running",
            "attempts": [],
            "commands": [],
        }
        self.save()

    def elapsed(self):
        return time.monotonic() - self.started

    def save(self):
        write_json(self.output / "report.json", self.report)

    def stop_child(self, process, record):
        # Only this newly created command session is signalled; no service,
        # other simulator, or unrelated runner process is reset or killed.
        cleanup = {"processGroupID": process.pid, "signal": "SIGKILL"}
        record["cleanup"] = cleanup
        record.setdefault("cleanupAttempts", []).append(cleanup)
        try:
            os.killpg(process.pid, signal.SIGKILL)
            cleanup["signalSent"] = True
        except ProcessLookupError:
            cleanup["groupAlreadyExited"] = True
        except OSError as error:
            cleanup["error"] = error_record(error)
        remaining = self.deadline - time.monotonic()
        try:
            record["returnCode"] = process.wait(timeout=max(0.0, min(2.0, remaining)))
            cleanup["directChildReaped"] = True
        except subprocess.TimeoutExpired as error:
            cleanup["directChildReaped"] = False
            cleanup["reapError"] = error_record(error)

    def command(self, name, arguments, deadline, maximum_seconds=None):
        deadline = min(deadline, self.work_deadline)
        if maximum_seconds is not None:
            deadline = min(deadline, time.monotonic() + maximum_seconds)
        sequence = len(self.report["commands"]) + 1
        stem = f"{sequence:02d}-{name}"
        record = {"name": name, "arguments": [self.xcrun, "simctl"] + arguments,
                  "startedElapsedSeconds": self.elapsed(), "status": "running",
                  "deadlineElapsedSeconds": deadline - self.started,
                  "stdoutPath": stem + ".stdout.log", "stderrPath": stem + ".stderr.log"}
        self.report["commands"].append(record)
        self.save()
        print(f"Simulator startup: {name}; evidence {self.output / stem}", flush=True)
        process = None
        try:
            with (self.output / record["stdoutPath"]).open("xb") as stdout, \
                    (self.output / record["stderrPath"]).open("xb") as stderr:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    record["status"] = "not_started"
                    record["deadlineExceeded"] = True
                else:
                    process = subprocess.Popen(record["arguments"], stdout=stdout, stderr=stderr,
                                               start_new_session=True)
                    record["processGroupID"] = process.pid
                    self.save()
                    try:
                        record["returnCode"] = process.wait(timeout=max(0.0, deadline - time.monotonic()))
                        record["status"] = "exited"
                        # A command may exit while a descendant still holds its
                        # session/log handles. Bound that group on every return,
                        # including exit zero; retain the command's real status.
                        self.stop_child(process, record)
                    except subprocess.TimeoutExpired:
                        record["status"] = "timed_out"
                        self.stop_child(process, record)
                    record["deadlineExceeded"] = time.monotonic() >= deadline
        except Interrupted as error:
            record["status"] = "interrupted"
            record["error"] = error_record(error)
            record["terminationSignal"] = error.number
            if process is not None:
                self.stop_child(process, record)
            raise
        except Exception as error:
            record["status"] = "execution_error"
            record["error"] = error_record(error)
            if process is not None:
                self.stop_child(process, record)
        finally:
            record["finishedElapsedSeconds"] = self.elapsed()
            write_json(self.output / (stem + ".result.json"), record)
            self.save()
        print(f"Simulator startup: {name}: {record['status']}, "
              f"exit={record.get('returnCode')}", flush=True)
        return record

    @staticmethod
    def require_success(record, *, startup=False):
        cleanup = record.get("cleanup", {})
        if cleanup.get("directChildReaped") is False or cleanup.get("error"):
            raise VerificationFailure(f"Owned command cleanup failed: {record['name']}")
        if record["status"] == "execution_error":
            raise VerificationFailure(f"Tool execution failed: {record['name']}: {record.get('error')}")
        # A child signal is terminal, except the SIGKILL we explicitly sent on
        # its recorded timeout. User cancellation never initiates recovery.
        if record.get("returnCode", 0) < 0 and record["status"] != "timed_out":
            raise VerificationFailure(f"Command terminated by signal: {record['name']}")
        if (record["status"] != "exited" or record.get("returnCode") != 0
                or record.get("deadlineExceeded")):
            failure = StartupFailure if startup else VerificationFailure
            raise failure(f"{record['name']} did not complete successfully before its deadline "
                          f"(status={record['status']}, exit={record.get('returnCode')})")

    def inventory(self, name, deadline, maximum_seconds=None):
        if maximum_seconds is None:
            maximum_seconds = INVENTORY_TIMEOUT_SECONDS
        record = self.command(name, ["list", "devices", "available", "-j"], deadline,
                              maximum_seconds)
        self.require_success(record)
        try:
            data = json.loads((self.output / record["stdoutPath"]).read_text(encoding="utf-8"))
            groups = data["devices"]
            if not isinstance(groups, dict) or any(not isinstance(group, list) for group in groups.values()):
                raise ValueError("devices must be a dictionary of lists")
            matches = [(runtime, device) for runtime, group in groups.items() for device in group
                       if isinstance(device, dict) and device.get("udid") == self.udid]
            if len(matches) != 1:
                raise ValueError("selected UDID must appear exactly once")
            runtime, device = matches[0]
            if runtime != self.runtime or device.get("deviceTypeIdentifier") != self.device_type:
                raise ValueError("selected simulator runtime or device type changed")
            if device.get("isAvailable") is not True:
                raise ValueError("selected simulator is unavailable")
            if device.get("state") not in ("Booted", "Booting", "Shutdown", "Shutting Down"):
                raise ValueError("selected simulator has an unknown state")
        except (KeyError, TypeError, ValueError) as error:
            raise VerificationFailure(f"Invalid simulator inventory in {name}: {error}") from error
        self.report.setdefault("inventories", []).append(
            {"command": name, "runtime": runtime, "device": device})
        self.save()
        return device

    def attempt(self, number, device, deadline):
        attempt = {"number": number, "status": "running", "initialState": device["state"],
                   "startedElapsedSeconds": self.elapsed(),
                   "deadlineElapsedSeconds": deadline - self.started}
        self.report["attempts"].append(attempt)
        self.save()
        try:
            if device["state"] == "Shutdown":
                record = self.command(f"attempt-{number}-boot", ["boot", self.udid], deadline)
                self.require_success(record, startup=True)
            elif device["state"] == "Shutting Down":
                raise StartupFailure("Selected simulator is still shutting down")
            # Booted/Booting alone is insufficient: bootstatus must finish, and
            # an independent postflight must still verify this exact device.
            record = self.command(f"attempt-{number}-bootstatus", ["bootstatus", self.udid, "-b"], deadline)
            self.require_success(record, startup=True)
            # Hosted CoreSimulator can report bootstatus success while its
            # inventory service is still busy. Allow a bounded readiness query
            # within this same attempt deadline; identity validation is intact.
            ready = self.inventory(f"attempt-{number}-postflight", deadline,
                                   POST_BOOT_INVENTORY_TIMEOUT_SECONDS)
            if ready["state"] != "Booted" or time.monotonic() >= deadline:
                raise StartupFailure("Simulator was not verified Booted before the attempt deadline")
            attempt["status"] = "ready"
            return True
        except StartupFailure as error:
            attempt["status"] = "failed"
            attempt["failure"] = error_record(error)
            return False
        except BaseException as error:
            attempt["status"] = "interrupted" if isinstance(error, Interrupted) else "failed"
            attempt["failure"] = error_record(error)
            raise
        finally:
            attempt["finishedElapsedSeconds"] = self.elapsed()
            self.save()

    def recover(self):
        if not (os.environ.get("GITHUB_ACTIONS") == "true"
                and os.environ.get("RUNNER_ENVIRONMENT") == "github-hosted"):
            raise VerificationFailure("Targeted recovery requires a GitHub-hosted ephemeral CI runner")
        recovery = {"status": "running", "startedElapsedSeconds": self.elapsed()}
        self.report["recovery"] = recovery
        self.save()
        try:
            device = self.inventory("recovery-preflight", self.work_deadline)
            if device["state"] != "Shutdown":
                record = self.command("recovery-shutdown", ["shutdown", self.udid],
                                      self.work_deadline, SHUTDOWN_TIMEOUT_SECONDS)
                self.require_success(record)
            device = self.inventory("recovery-postflight", self.work_deadline)
            if device["state"] != "Shutdown":
                raise VerificationFailure("Targeted shutdown did not leave the selected device Shutdown")
            recovery["status"] = "shutdown_verified"
            return device
        except BaseException as error:
            recovery["status"] = "failed"
            recovery["failure"] = error_record(error)
            raise
        finally:
            recovery["finishedElapsedSeconds"] = self.elapsed()
            self.save()

    def run(self):
        if self.xcrun is None:
            raise VerificationFailure("xcrun is unavailable")
        device = self.inventory("preflight", self.first_deadline)
        if self.attempt(1, device, self.first_deadline):
            return
        if time.monotonic() >= self.work_deadline:
            raise StartupFailure("Startup budget exhausted after first attempt")
        device = self.recover()
        if not self.attempt(2, device, self.work_deadline):
            raise StartupFailure("Both simulator startup attempts failed")


def parse_arguments(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--udid", required=True, help="Exact selected simulator UUID; aliases are rejected")
    parser.add_argument("--runtime", required=True)
    parser.add_argument("--device-type", required=True)
    parser.add_argument("--output", type=Path, required=True, help="New evidence directory (must not exist)")
    parser.add_argument("--timeout-seconds", type=float, default=DEFAULT_TIMEOUT_SECONDS)
    args = parser.parse_args(argv)
    try:
        uuid.UUID(args.udid)
    except ValueError:
        parser.error("--udid must be a simulator UUID")
    if not (math.isfinite(args.timeout_seconds) and 0 < args.timeout_seconds <= MAX_TIMEOUT_SECONDS):
        parser.error("--timeout-seconds must be finite, greater than zero and at most 600")
    return args


def main(argv=None):
    started = time.monotonic()
    args = parse_arguments(argv)
    try:
        startup = SimulatorStartup(args, started)
    except OSError as error:
        print(f"Cannot create new startup evidence directory: {error}", file=sys.stderr)
        return 1
    interrupted = False

    def on_signal(number, _frame):
        nonlocal interrupted
        if not interrupted:
            interrupted = True
            raise Interrupted(number)

    previous = {number: signal.signal(number, on_signal) for number in (signal.SIGINT, signal.SIGTERM)}
    exit_code = 1

    def finalize():
        startup.report["elapsedSeconds"] = startup.elapsed()
        startup.report["exitCode"] = exit_code
        startup.save()
        print(f"Simulator startup: {startup.report['status']}; report {startup.output / 'report.json'}", flush=True)

    try:
        try:
            startup.run()
            if time.monotonic() >= startup.work_deadline:
                raise StartupFailure("Startup completion exceeded the shared work deadline")
            startup.report["status"] = "ready" if len(startup.report["attempts"]) == 1 else "ready_after_recovery"
            exit_code = 0
        except Exception as error:
            startup.report["status"] = "failed"
            startup.report["failure"] = error_record(error)
            print(f"Simulator startup failed: {error}", file=sys.stderr, flush=True)
        finalize()
    except Interrupted as error:
        # Cover cancellation during report persistence too: a success receipt
        # may already have been written, so replace it with the terminal signal
        # outcome. The handler ignores subsequent signals during this cleanup.
        startup.report["status"] = "interrupted"
        startup.report["failure"] = error_record(error)
        startup.report["terminationSignal"] = error.number
        exit_code = 128 + error.number
        finalize()
    finally:
        for number, handler in previous.items():
            signal.signal(number, handler)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
