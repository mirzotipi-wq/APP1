#!/usr/bin/env python3
"""Bounded Linux-host rename-boundary probes using a compiled real library helper.

Requires a fresh --output directory and the helper's actual compile manifest.
Only the owned save child receives LD_PRELOAD. Its exact projects.json rename is
witnessed through a private pipe; setup, controls, and fresh-process verification
run without interposition. This does not simulate power loss or certify iOS.
"""

import argparse
import errno
import hashlib
import json
import os
from pathlib import Path
import platform
import resource
import select
import shutil
import signal
import stat
import subprocess
import sys
import time


BYTE_CEILING = 1024 * 1024
WITNESS_CEILING = 64 * 1024
PHASE_TIMEOUT_SECONDS = 30
TOTAL_TIMEOUT_SECONDS = 120
MAXIMUM_TOTAL_TIMEOUT_SECONDS = 240
CLEANUP_TIMEOUT_SECONDS = 5
MODES = ("before-rename", "after-rename", "rename-eio")
ENVIRONMENT_KEYS = ("PATH", "LD_LIBRARY_PATH", "LANG", "LC_ALL", "TMPDIR")
ACTIVE_CHILDREN = {}
TERMINATION_SIGNAL = None


class TerminationRequested(BaseException):
    def __init__(self, number):
        self.number = number


def request_termination(number, _frame):
    global TERMINATION_SIGNAL
    if TERMINATION_SIGNAL is None:
        TERMINATION_SIGNAL = number
        raise TerminationRequested(number)


def spawn_owned(arguments, **options):
    # The diagnostic is single-threaded. Block cancellation until the new
    # handle is registered; restore the original mask in the child before exec.
    previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, {signal.SIGTERM, signal.SIGINT})
    try:
        process = subprocess.Popen(arguments, start_new_session=True,
                                   preexec_fn=lambda: signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask),
                                   **options)
        ACTIVE_CHILDREN[process.pid] = process
    finally:
        signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)
    return process


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def bounded_read(path, ceiling=BYTE_CEILING):
    require(path.stat().st_size <= ceiling, "Artifact exceeds diagnostic bound: " + str(path))
    with path.open("rb") as stream:
        value = stream.read(ceiling + 1)
    require(len(value) <= ceiling, "Artifact grew beyond diagnostic bound: " + str(path))
    return value


def remaining(deadline, maximum=PHASE_TIMEOUT_SECONDS):
    available = min(maximum, deadline - time.monotonic())
    require(available > 0, "Overall diagnostic deadline expired")
    return available


def clean_environment():
    environment = os.environ.copy()
    removed = sorted(key for key in environment
                     if key in ("LD_PRELOAD", "LD_AUDIT") or key.startswith("KF_COMMIT_"))
    for key in removed:
        del environment[key]
    return environment, removed


def kill_owned_group(process):
    require(process.pid != os.getpgrp(), "Refusing to signal the parent process group")
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    result = process.wait(timeout=CLEANUP_TIMEOUT_SECONDS)
    ACTIVE_CHILDREN.pop(process.pid, None)
    return result


def run_command(arguments, cwd, output, name, environment, deadline, maximum=PHASE_TIMEOUT_SECONDS):
    timeout = remaining(deadline, maximum)
    result = {"arguments": arguments, "cwd": str(cwd), "timeoutSeconds": timeout}
    started = time.monotonic()
    with (output / (name + ".stdout.log")).open("wb") as stdout, \
            (output / (name + ".stderr.log")).open("wb") as stderr:
        process = spawn_owned(arguments, cwd=cwd, env=environment, stdout=stdout, stderr=stderr)
        result["processGroupID"] = process.pid
        try:
            result["returnCode"] = process.wait(timeout=timeout)
            ACTIVE_CHILDREN.pop(process.pid, None)
        except subprocess.TimeoutExpired:
            result["timedOut"] = True
            result["returnCode"] = kill_owned_group(process)
            result["cleanup"] = "SIGKILL to owned group; direct child reaped"
        except BaseException:
            kill_owned_group(process)
            raise
    result["elapsedSeconds"] = round(time.monotonic() - started, 3)
    result["stdoutPath"] = str(output / (name + ".stdout.log"))
    result["stderrPath"] = str(output / (name + ".stderr.log"))
    return result


def run_phase(helper, directory, phase, environment, deadline):
    result = run_command([str(helper), phase, str(directory)], directory, directory,
                         phase, environment, deadline)
    try:
        result["observed"] = json.loads(bounded_read(Path(result["stdoutPath"])))
        require(isinstance(result["observed"], dict), "Helper JSON must be an object")
    except (OSError, ValueError, RuntimeError) as error:
        result["outputError"] = str(error)
    return result


def require_phase(phase, status):
    require(phase.get("returnCode") == 0 and phase.get("observed", {}).get("status") == status,
            "Helper phase failed: " + phase["arguments"][1])


def read_pipe_chunk(descriptor, raw, deadline):
    ready, _, _ = select.select([descriptor], [], [], min(remaining(deadline), 0.1))
    if not ready:
        return None
    chunk = os.read(descriptor, 8192)
    raw.extend(chunk)
    require(len(raw) <= WITNESS_CEILING, "Interposer witness exceeds diagnostic bound")
    return chunk


def validate_event(event, mode, target, process):
    require(isinstance(event, dict) and event.get("schemaVersion") == 1, "Invalid witness schema")
    require(event.get("pid") == process.pid and event.get("targetMatched") is True
            and event.get("targetPath") == str(target) and event.get("mode") == mode
            and event.get("api") in ("rename", "renameat", "renameat2"),
            "Witness does not identify the exact owned save and destination")
    expected_state = {"before-rename": "before-call", "after-rename": "after-success", "rename-eio": "rejected"}[mode]
    require(event.get("hookState") == expected_state, "Rename did not reach the required hook state")
    if mode == "after-rename":
        require(event.get("realRenameCalled") is True and event.get("realReturnCode") == 0,
                "Post-rename witness must prove a successful real rename")
    else:
        require(event.get("realRenameCalled") is False, "Pre-commit/error hook unexpectedly called real rename")
    if mode == "rename-eio":
        require(event.get("returnedErrno") == errno.EIO, "Rename rejection did not report explicit EIO")


def wait_for_stop(process, deadline):
    while True:
        remaining(deadline)
        state = os.waitid(os.P_PID, process.pid, os.WSTOPPED | os.WEXITED | os.WNOHANG | os.WNOWAIT)
        if state is not None:
            require(state.si_code == os.CLD_STOPPED and state.si_status == signal.SIGSTOP,
                    "Witnessed child exited or stopped unexpectedly before parent interruption")
            return {"signal": state.si_status, "processID": state.si_pid, "code": state.si_code}
        time.sleep(0.005)


def staged_source(event, process, directory):
    source = Path(event["sourceArgument"])
    if not source.is_absolute():
        source_fd = event["sourceDirFD"]
        source = (directory if source_fd == -100 else Path(f"/proc/{process.pid}/fd/{source_fd}")) / source
    source = source.resolve(strict=True)
    require(source.is_relative_to(directory), "Staged source lies outside the owned scenario")
    return source


def run_injection(helper, interposer, directory, mode, environment, overall_deadline):
    target = (directory / "library" / "projects.json").resolve(strict=True)
    require(target.parent == directory / "library" and stat.S_ISREG(target.stat().st_mode),
            "Injection target is not the exact owned regular library file")
    deadline = min(overall_deadline, time.monotonic() + PHASE_TIMEOUT_SECONDS)
    result = {"status": "failed", "mode": mode, "targetPath": str(target),
              "arguments": [str(helper), "save", str(directory)], "hookWitnessed": False}
    raw = bytearray()
    read_fd = write_fd = library_fd = -1
    result["interposerPath"] = str(interposer)
    process = None
    started = time.monotonic()
    try:
        read_fd, write_fd = os.pipe()
        library_fd = os.open(interposer, os.O_RDONLY)
        os.set_blocking(read_fd, False)
        child_environment = environment.copy()
        # /proc/self/fd avoids LD_PRELOAD's whitespace/colon path parsing entirely.
        overrides = {"LD_PRELOAD": f"/proc/self/fd/{library_fd}", "KF_COMMIT_TARGET": str(target),
                     "KF_COMMIT_MODE": mode, "KF_COMMIT_WITNESS_FD": str(write_fd)}
        child_environment.update(overrides)
        result["environmentOverrides"] = overrides
        with (directory / "save.stdout.log").open("wb") as stdout, \
                (directory / "save.stderr.log").open("wb") as stderr:
            process = spawn_owned(result["arguments"], cwd=directory, env=child_environment,
                                  stdout=stdout, stderr=stderr, pass_fds=(write_fd, library_fd))
            result["processGroupID"] = process.pid
            os.close(write_fd)
            write_fd = -1
            os.close(library_fd)
            library_fd = -1
            while b"\n" not in raw:
                chunk = read_pipe_chunk(read_fd, raw, deadline)
                require(chunk != b"", "Save exited without a witnessed target rename")
            event = json.loads(bytes(raw).split(b"\n", 1)[0])
            validate_event(event, mode, target, process)
            result["hookWitnessed"] = True
            if mode != "rename-eio":
                result["observedStop"] = wait_for_stop(process, deadline)
                at_hook = bounded_read(target)
                (directory / "at-hook.json").write_bytes(at_hook)
                expected = bounded_read(directory / ("candidate.json" if mode == "after-rename" else "prior.json"))
                result["exactExpectedBytesAtHook"] = at_hook == expected
                if mode == "before-rename":
                    staged = staged_source(event, process, directory)
                    staged_bytes = bounded_read(staged)
                    (directory / "staged-at-hook.json").write_bytes(staged_bytes)
                    result["stagedSourcePath"] = str(staged)
                    result["stagedExactCandidateBytes"] = staged_bytes == bounded_read(directory / "candidate.json")
                result["returnCode"] = kill_owned_group(process)
                result["parentIssuedSIGKILL"] = True
                require(result["returnCode"] == -signal.SIGKILL, "Save was not terminated by owned SIGKILL")
            else:
                result["returnCode"] = process.wait(timeout=remaining(deadline))
            result["status"] = "observed"
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        result["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        for descriptor in (write_fd, library_fd):
            if descriptor >= 0:
                os.close(descriptor)
        if process is not None:
            try:
                result["finalReturnCode"] = kill_owned_group(process)
                result["ownedGroupCleanupComplete"] = True
            except (OSError, RuntimeError, subprocess.SubprocessError) as error:
                result["status"] = "failed"
                result["cleanupError"] = str(error)
        if read_fd >= 0:
            try:
                while len(raw) <= WITNESS_CEILING:
                    chunk = os.read(read_fd, 8192)
                    if not chunk:
                        break
                    raw.extend(chunk)
            except BlockingIOError:
                pass
            os.close(read_fd)
        (directory / "hook-witness.jsonl").write_bytes(raw)
    result["elapsedSeconds"] = round(time.monotonic() - started, 3)
    try:
        require(len(raw) <= WITNESS_CEILING, "Witness exceeds diagnostic bound")
        events = [json.loads(line) for line in raw.splitlines()]
        require(bool(events), "No interposer witness was recorded")
        for event in events:
            validate_event(event, mode, target, process)
        result["events"] = events
        result["hookCount"] = len(events)
    except (ValueError, RuntimeError, KeyError) as error:
        result["status"] = "failed"
        result["witnessError"] = str(error)
    try:
        data = bounded_read(directory / "save.stdout.log")
        if data:
            result["observed"] = json.loads(data)
    except (OSError, ValueError, RuntimeError) as error:
        result["outputError"] = str(error)
    return result


def run_scenario(helper, interposer, output, mode, base_environment, deadline):
    directory = output / mode
    directory.mkdir(exist_ok=False)
    (directory / "temporary").mkdir()
    environment = base_environment.copy()
    environment["TMPDIR"] = str(directory / "temporary")
    result = {"mode": mode, "status": "failed", "directory": str(directory), "phases": []}
    write_json(directory / "scenario-result.json", result)
    try:
        setup = run_phase(helper, directory, "setup", environment, deadline)
        result["phases"].append(setup)
        require_phase(setup, "setup_complete")
        prior = bounded_read(directory / "prior.json")
        candidate = bounded_read(directory / "candidate.json")
        require(0 < len(prior) < len(candidate) <= BYTE_CEILING < setup["observed"]["libraryByteLimit"],
                "Fixtures exceed declared bounds or do not differ")
        control = run_phase(helper, directory, "control", environment, deadline)
        result["phases"].append(control)
        require_phase(control, "control_saved")
        result["injection"] = run_injection(helper, interposer, directory, mode, environment, deadline)
        phase = "verify-candidate" if mode == "after-rename" else "verify"
        verification = run_phase(helper, directory, phase, environment, deadline)
        result["phases"].append(verification)
        after = bounded_read(directory / "library" / "projects.json")
        (directory / "after.json").write_bytes(after)
        injected = result["injection"]
        verified = verification.get("observed", {})
        expected_status = "candidate_verification_complete" if mode == "after-rename" else "verification_complete"
        result["checks"] = {
            "unrestrictedSetupAndControlSucceeded": True,
            "exactTargetRenameWitnessed": injected.get("status") == "observed" and injected.get("hookWitnessed") is True,
            "ownedGroupCleaned": injected.get("ownedGroupCleanupComplete") is True,
            "freshProcessReopenSucceeded": verification.get("returnCode") == 0 and verified.get("status") == expected_status,
            "exactExpectedBytesPreserved": after == (candidate if mode == "after-rename" else prior),
            "activeIdentityPreserved": verified.get("activeIdentityPreserved") is True,
            "unrelatedRecordsPreserved": verified.get("unrelatedRecordsPreserved") is True,
            "unrestrictedControlCandidateReopened": verified.get("controlCandidateReopened") is True
                and verified.get("controlExactCandidateBytes") is True,
            "unrestrictedControlExactCandidateBytes": bounded_read(directory / "control" / "projects.json") == candidate,
        }
        if mode == "after-rename":
            result["checks"].update({
                "candidateCompleteSnapshotPreserved": verified.get("candidateCompleteSnapshotPreserved") is True,
                "candidateExactBytesPreserved": verified.get("candidateExactBytesPreserved") is True,
                "candidateRecordsPreserved": verified.get("candidateRecordsPreserved") is True,
            })
        else:
            result["checks"]["priorCompleteSnapshotPreserved"] = verified.get("priorCompleteSnapshotPreserved") is True
        if mode == "rename-eio":
            saved = injected.get("observed", {})
            result["checks"]["actualSaveThrew"] = (injected.get("returnCode") == 0
                and saved.get("status") == "save_threw" and saved.get("writeAttempted") is True)
            result["checks"]["witnessedRenameReturnedEIO"] = bool(injected.get("events")) and all(
                event.get("returnedErrno") == errno.EIO and event.get("realRenameCalled") is False
                for event in injected.get("events", []))
            result["saveErrorObservation"] = saved
        else:
            result["checks"].update({
                "stoppedAtWitnessedHook": injected.get("observedStop", {}).get("signal") == signal.SIGSTOP,
                "parentKilledOwnedSave": injected.get("parentIssuedSIGKILL") is True
                    and injected.get("returnCode") == -signal.SIGKILL,
                "exactExpectedBytesAtHook": injected.get("exactExpectedBytesAtHook") is True,
            })
            if mode == "before-rename":
                result["checks"]["fullyWrittenCandidateStagedBeforeRename"] = injected.get("stagedExactCandidateBytes") is True
        result["files"] = {relative: {"bytes": (directory / relative).stat().st_size,
                                     "sha256": sha256(directory / relative)}
                           for relative in ("prior.json", "candidate.json", "after.json", "library/projects.json", "control/projects.json")}
        require(all(result["checks"].values()), "One or more witnessed commit/preservation checks failed")
        result["status"] = "passed"
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        result["failure"] = {"type": type(error).__name__, "message": str(error)}
    write_json(directory / "scenario-result.json", result)
    return result


def source_hashes(repository):
    paths = sorted((repository / "Sources" / "LightingCore").glob("*.swift"))
    require(bool(paths), "No LightingCore sources found")
    paths.append(repository / "scripts" / "probe-atomic-library-write.swift")
    return {str(path.relative_to(repository)): sha256(path) for path in paths}


def main():
    global TERMINATION_SIGNAL
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--helper", required=True, type=Path)
    parser.add_argument("--compile-manifest", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--cc", default="cc")
    parser.add_argument("--timeout-seconds", type=float, default=TOTAL_TIMEOUT_SECONDS,
                        help="Overall deadline, 1–240 seconds; callers must allow an additional cleanup margin")
    args = parser.parse_args()
    repository = Path(__file__).resolve().parent.parent
    output, helper = args.output.resolve(), args.helper.resolve()
    deadline = time.monotonic() + args.timeout_seconds
    environment, removed = clean_environment()
    parent_state = (resource.getrlimit(resource.RLIMIT_FSIZE), signal.getsignal(signal.SIGXFSZ), os.getpgrp())
    report = {"schemaVersion": 1, "probe": "project_library_commit_boundaries_linux", "status": "failed",
              "sourceRevision": args.source_revision, "output": str(output), "scenarios": [],
              "host": {"system": platform.system(), "release": platform.release(), "machine": platform.machine(),
                       "python": platform.python_version()},
              "environment": {key: environment[key] for key in ENVIRONMENT_KEYS if key in environment},
              "removedInheritedEnvironmentKeys": removed, "totalTimeoutSeconds": args.timeout_seconds,
              "excludedClaims": ["power loss or storage durability", "ENOSPC or physical low storage",
                                 "Darwin, iOS, simulator or physical-device execution",
                                 "child cleanup after uncatchable SIGKILL of this driver"]}
    created_output = False
    TERMINATION_SIGNAL = None
    previous_handlers = {number: signal.getsignal(number) for number in (signal.SIGTERM, signal.SIGINT)}
    for number in previous_handlers:
        signal.signal(number, request_termination)
    try:
        require(platform.system() == "Linux", "This diagnostic supports Linux hosts only")
        require(1 <= args.timeout_seconds <= MAXIMUM_TOTAL_TIMEOUT_SECONDS,
                "Overall timeout must be between 1 and 240 seconds")
        require(helper.is_file() and os.access(helper, os.X_OK), "Helper must be an executable regular file")
        require(parent_state[0][0] == resource.RLIM_INFINITY or parent_state[0][0] >= BYTE_CEILING,
                "Inherited file-size limit is too low for unrestricted fixtures")
        output.mkdir(parents=False, exist_ok=False)
        created_output = True
        write_json(output / "result.json", report)
        manifest_bytes = bounded_read(args.compile_manifest.resolve())
        manifest = json.loads(manifest_bytes)
        require(isinstance(manifest, dict), "Compile manifest must be an object")
        actual_sources = source_hashes(repository)
        require(manifest.get("sourceSHA256") == actual_sources, "Helper manifest does not match every current Swift input")
        require(manifest.get("binarySHA256", {}).get(helper.name) == sha256(helper), "Helper binary does not match compile manifest")
        require(manifest.get("sourcesUnchangedDuringCompilation") is True
                and manifest.get("compilerPath") and manifest.get("compilerVersion")
                and manifest.get("compile", {}).get("returnCode") == 0,
                "Manifest lacks a successful, source-stable compiler receipt")
        (output / "helper-compile-manifest.json").write_bytes(manifest_bytes)
        report["helperProvenance"] = {"path": str(helper), "sha256": sha256(helper),
                                      "manifestSHA256": hashlib.sha256(manifest_bytes).hexdigest(),
                                      "baseRevision": manifest.get("baseRevision"), "sourceSHA256": actual_sources}
        c_source = repository / "scripts" / "probe-library-commit-interposer.c"
        diagnostics = (c_source, Path(__file__).resolve())
        before = {str(path.relative_to(repository)): sha256(path) for path in diagnostics}
        report["diagnosticSHA256Before"] = before
        compiler = shutil.which(args.cc)
        require(compiler is not None, "C compiler not found: " + args.cc)
        compiler = os.path.abspath(compiler)
        report["compilerPath"] = compiler
        report["compilerResolvedPath"] = str(Path(compiler).resolve())
        version = run_command([compiler, "--version"], repository, output, "c-compiler-version", environment, deadline, 10)
        report["compilerVersionCommand"] = version
        require(version.get("returnCode") == 0, "Cannot record C compiler version")
        report["compilerVersion"] = bounded_read(Path(version["stdoutPath"])).decode("utf-8")
        interposer = output / "probe-library-commit-interposer.so"
        command = [compiler, "-std=c11", "-O2", "-fPIC", "-shared", "-Wall", "-Wextra", "-Werror",
                   str(c_source), "-o", str(interposer), "-ldl"]
        report["compile"] = run_command(command, repository, output, "c-compile", environment, deadline)
        require(report["compile"].get("returnCode") == 0, "Interposer compilation failed or timed out")
        require(before == {str(path.relative_to(repository)): sha256(path) for path in diagnostics},
                "Diagnostic source changed during C compilation")
        report["interposerSHA256"] = sha256(interposer)
        write_json(output / "result.json", report)
        for mode in MODES:
            report["scenarios"].append(run_scenario(helper, interposer, output, mode, environment, deadline))
            write_json(output / "result.json", report)
        report["diagnosticSHA256After"] = {str(path.relative_to(repository)): sha256(path) for path in diagnostics}
        report["sourcesUnchanged"] = actual_sources == source_hashes(repository)
        report["diagnosticsUnchanged"] = before == report["diagnosticSHA256After"]
        report["binariesUnchanged"] = (report["helperProvenance"]["sha256"] == sha256(helper)
                                         and report["interposerSHA256"] == sha256(interposer))
        require(report["sourcesUnchanged"] and report["diagnosticsUnchanged"] and report["binariesUnchanged"],
                "Inputs changed during the diagnostic")
        require(len(report["scenarios"]) == len(MODES) and all(case["status"] == "passed" for case in report["scenarios"]),
                "One or more commit-boundary scenarios failed; retained artifacts contain details")
        report["status"] = "passed"
    except TerminationRequested as error:
        report["status"] = "failed"
        report["failure"] = {"type": "TerminationRequested", "signal": error.number,
                             "message": "Driver cancellation requested; owned children cleaned below"}
        report["terminationSignal"] = error.number
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        for process in list(ACTIVE_CHILDREN.values()):
            try:
                kill_owned_group(process)
            except (OSError, RuntimeError, subprocess.SubprocessError) as error:
                report["status"] = "failed"
                report.setdefault("cleanupErrors", []).append(str(error))
        report["ownedChildrenReaped"] = not ACTIVE_CHILDREN
        report["parentResourceSignalAndGroupUnchanged"] = parent_state == (
            resource.getrlimit(resource.RLIMIT_FSIZE), signal.getsignal(signal.SIGXFSZ), os.getpgrp())
        if not report["parentResourceSignalAndGroupUnchanged"]:
            report["status"] = "failed"
            report["parentStateError"] = "Parent resource/signal/process group changed"
        for number, handler in previous_handlers.items():
            signal.signal(number, handler)
    if created_output:
        try:
            write_json(output / "result.json", report)
        except OSError as error:
            report["status"] = "failed"
            report["artifactWriteError"] = str(error)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
