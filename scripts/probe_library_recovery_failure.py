#!/usr/bin/env python3
"""Compile and witness recovery's post-archive commit failure on Linux.

Usage: python3 scripts/probe_library_recovery_failure.py --output NEW_DIRECTORY

The existing exact-target interposer is loaded only into an owned recovery child.
A stopped pre-rename run lets the parent inspect complete original archives and
the staged replacement before killing that child. A separate rename-EIO run must
raise the real recoveryWriteFailed error, preserve both original source files,
and retain its complete archive. Both runs then retry with a fresh confirmation
in an unrestricted process and reopen in another fresh process. All compiler,
filesystem, helper, and pipe receipts remain in --output on success or failure.
No production hooks, global resource limits, power-loss or device claims apply.
"""

import argparse
import errno
import json
import os
from pathlib import Path
import platform
import resource
import shutil
import signal
import stat
import subprocess
import sys
import time

import probe_library_commit_interruption as fault


MODES = ("before-rename", "rename-eio")
SOURCE_FILES = ("projects.json", "portrait.json")
COMPILE_TIMEOUT_SECONDS = 180
TOTAL_TIMEOUT_SECONDS = 300


def source_hashes(repository):
    sources = sorted((repository / "Sources" / "LightingCore").glob("*.swift"))
    fault.require(bool(sources), "No LightingCore Swift sources found")
    sources.append(repository / "scripts" / "probe-library-recovery.swift")
    return {str(path.relative_to(repository)): fault.sha256(path) for path in sources}


def diagnostic_hashes(repository):
    names = ("probe_library_recovery_failure.py", "probe_library_commit_interruption.py",
             "probe-library-commit-interposer.c")
    return {"scripts/" + name: fault.sha256(repository / "scripts" / name) for name in names}


def original_bytes(directory):
    return {"projects.json": fault.bounded_read(directory / "original-projects.bin"),
            "portrait.json": fault.bounded_read(directory / "original-portrait.json")}


def file_receipt(path, expected):
    before = path.lstat()
    fault.require(stat.S_ISREG(before.st_mode), "Expected an owned regular file: " + str(path))
    data = fault.bounded_read(path)
    after = path.lstat()
    identity = lambda item: (item.st_dev, item.st_ino, item.st_size, item.st_mtime_ns, item.st_ctime_ns)
    fault.require(identity(before) == identity(after), "File changed during observation: " + str(path))
    return {"bytes": len(data), "sha256": fault.sha256(path), "exactExpectedBytes": data == expected,
            "device": after.st_dev, "inode": after.st_ino, "mode": stat.S_IMODE(after.st_mode),
            "mtimeNanoseconds": after.st_mtime_ns, "ctimeNanoseconds": after.st_ctime_ns}, data


def source_receipt(directory, label, replacement=False):
    expected = original_bytes(directory)
    if replacement:
        expected["projects.json"] = fault.bounded_read(directory / "candidate.json")
    result = {}
    for name in SOURCE_FILES:
        receipt, data = file_receipt(directory / "library" / name, expected[name])
        result[name] = receipt
        (directory / (label + "-" + name)).write_bytes(data)
    fault.write_json(directory / (label + "-sources.json"), result)
    fault.require(all(item["exactExpectedBytes"] for item in result.values()),
                  "Source bytes differ from their complete expected files")
    return result


def archive_receipt(directory, count, store="library"):
    root = directory / store / "Recovery"
    attributes = root.lstat()
    fault.require(stat.S_ISDIR(attributes.st_mode) and not stat.S_IMODE(attributes.st_mode) & 0o077,
                  "Recovery root is not a private real directory")
    archives = sorted(root.iterdir())
    fault.require(len(archives) == count, "Unexpected recovery archive count")
    expected = original_bytes(directory)
    result = {}
    for archive in archives:
        attributes = archive.lstat()
        fault.require(stat.S_ISDIR(attributes.st_mode) and not stat.S_IMODE(attributes.st_mode) & 0o077,
                      "Recovery archive is not a private real directory")
        fault.require(sorted(path.name for path in archive.iterdir()) == sorted(SOURCE_FILES),
                      "Archive does not contain exactly both original filenames")
        files = {name: file_receipt(archive / name, expected[name])[0] for name in SOURCE_FILES}
        fault.require(all(item["exactExpectedBytes"] for item in files.values()),
                      "Archive did not preserve both complete original files")
        result[archive.name] = {"mode": stat.S_IMODE(attributes.st_mode), "files": files}
    return result


def filesystem_receipt(target, output, name, environment, deadline):
    target = target.resolve(strict=True)
    before = target.stat()
    located = shutil.which("findmnt", path=environment.get("PATH"))
    fault.require(located is not None, "findmnt is required for actual filesystem provenance")
    command = fault.run_command(
        [os.path.abspath(located), "--json", "--target", str(target), "--output",
         "TARGET,SOURCE,FSTYPE,MAJ:MIN", "--first-only"],
        output, output, name, environment, deadline, 10)
    fault.require(command.get("returnCode") == 0, "Filesystem metadata command failed")
    rows = json.loads(fault.bounded_read(Path(command["stdoutPath"]))).get("filesystems")
    fault.require(isinstance(rows, list) and len(rows) == 1 and isinstance(rows[0], dict),
                  "findmnt did not identify one actual target filesystem")
    row = rows[0]
    device = f"{os.major(before.st_dev)}:{os.minor(before.st_dev)}"
    fault.require(row.get("maj:min") == device and Path(row["target"]).stat().st_dev == before.st_dev,
                  "Filesystem device does not match the actual target")
    after = target.stat()
    fault.require((before.st_dev, before.st_ino) == (after.st_dev, after.st_ino),
                  "Target identity changed during filesystem observation")
    return {"targetPath": str(target), "device": before.st_dev, "inode": before.st_ino,
            "selectedFilesystem": row, "command": command, "status": "observed"}


def run_injection(helper, interposer, directory, mode, environment, overall_deadline):
    target = (directory / "library" / "projects.json").resolve(strict=True)
    fault.require(target == directory / "library" / "projects.json"
                  and stat.S_ISREG(target.lstat().st_mode), "Target is not the exact owned library")
    deadline = min(overall_deadline, time.monotonic() + fault.PHASE_TIMEOUT_SECONDS)
    result = {"status": "failed", "mode": mode, "targetPath": str(target),
              "arguments": [str(helper), "recover", str(directory)], "hookWitnessed": False}
    raw = bytearray()
    read_fd = write_fd = library_fd = -1
    process = None
    started = time.monotonic()
    try:
        read_fd, write_fd = os.pipe()
        library_fd = os.open(interposer, os.O_RDONLY)
        os.set_blocking(read_fd, False)
        child_environment = environment.copy()
        overrides = {"LD_PRELOAD": f"/proc/self/fd/{library_fd}", "KF_COMMIT_TARGET": str(target),
                     "KF_COMMIT_MODE": mode, "KF_COMMIT_WITNESS_FD": str(write_fd)}
        child_environment.update(overrides)
        result["environmentOverrides"] = overrides
        with (directory / "injection.stdout.log").open("wb") as stdout, \
                (directory / "injection.stderr.log").open("wb") as stderr:
            process = fault.spawn_owned(result["arguments"], cwd=directory, env=child_environment,
                                        stdout=stdout, stderr=stderr, pass_fds=(write_fd, library_fd))
            result["processGroupID"] = process.pid
            os.close(write_fd)
            write_fd = -1
            os.close(library_fd)
            library_fd = -1
            while b"\n" not in raw:
                chunk = fault.read_pipe_chunk(read_fd, raw, deadline)
                fault.require(chunk != b"", "Recovery exited without a witnessed target rename")
            event = json.loads(bytes(raw).split(b"\n", 1)[0])
            fault.validate_event(event, mode, target, process)
            result["hookWitnessed"] = True
            if mode == "before-rename":
                result["observedStop"] = fault.wait_for_stop(process, deadline)
                # SIGSTOP gives a stable, externally observed pre-commit point.
                # The source, archives and complete staged replacement coexist.
                result["atHookSources"] = source_receipt(directory, "at-hook")
                result["atHookArchives"] = archive_receipt(directory, 1)
                staged = fault.staged_source(event, process, directory)
                staged_bytes = fault.bounded_read(staged)
                (directory / "staged-at-hook.json").write_bytes(staged_bytes)
                result["stagedSourcePath"] = str(staged)
                result["stagedExactCandidateBytes"] = staged_bytes == fault.bounded_read(directory / "candidate.json")
                fault.write_json(directory / "at-hook-observation.json", result)
                result["returnCode"] = fault.kill_owned_group(process)
                result["parentIssuedSIGKILL"] = True
                fault.require(result["returnCode"] == -signal.SIGKILL, "Owned recovery child was not killed")
            else:
                # This observation follows the EIO witness; unlike the stopped
                # run, it deliberately does not claim to precede error return.
                result["afterWitnessSources"] = source_receipt(directory, "after-witness")
                result["afterWitnessArchives"] = archive_receipt(directory, 1)
                result["returnCode"] = process.wait(timeout=fault.remaining(deadline))
            result["status"] = "observed"
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        result["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        for descriptor in (write_fd, library_fd):
            if descriptor >= 0:
                os.close(descriptor)
        if process is not None:
            try:
                result["finalReturnCode"] = fault.kill_owned_group(process)
                result["ownedGroupCleanupComplete"] = True
            except (OSError, RuntimeError, subprocess.SubprocessError) as error:
                result["cleanupError"] = str(error)
                result["status"] = "failed"
        if read_fd >= 0:
            try:
                while len(raw) <= fault.WITNESS_CEILING:
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
        fault.require(len(raw) <= fault.WITNESS_CEILING, "Witness exceeds diagnostic bound")
        events = [json.loads(line) for line in raw.splitlines()]
        fault.require(bool(events) and process is not None, "No interposer witness was recorded")
        for index, event in enumerate(events, start=1):
            fault.validate_event(event, mode, target, process)
            fault.require(event.get("hit") == index, "Nonsequential witness events")
        result["events"] = events
        result["hookCount"] = len(events)
    except (ValueError, RuntimeError, KeyError) as error:
        result["status"] = "failed"
        result["witnessError"] = str(error)
    try:
        data = fault.bounded_read(directory / "injection.stdout.log")
        if data:
            result["observed"] = json.loads(data)
            fault.require(isinstance(result["observed"], dict), "Helper JSON must be an object")
    except (OSError, ValueError, RuntimeError) as error:
        result["status"] = "failed"
        result["outputError"] = str(error)
    fault.write_json(directory / "injection-result.json", result)
    return result


def run_scenario(helper, interposer, output, mode, base_environment, deadline):
    directory = output / mode
    directory.mkdir(exist_ok=False)
    (directory / "temporary").mkdir()
    environment = dict(base_environment, TMPDIR=str(directory / "temporary"))
    result = {"mode": mode, "status": "failed", "directory": str(directory), "phases": []}
    fault.write_json(directory / "scenario-result.json", result)

    def phase(name, expected):
        observation = fault.run_phase(helper, directory, name, environment, deadline)
        result["phases"].append(observation)
        fault.write_json(directory / "scenario-result.json", result)
        fault.require_phase(observation, expected)
        fault.require(observation["observed"].get("processID") == observation["processGroupID"],
                      "Helper receipt is not bound to its owned child")
        return observation["observed"]

    try:
        setup = phase("setup", "setup_complete")
        fault.require(0 < setup["originalLibraryBytes"] < setup["candidateBytes"]
                      < fault.BYTE_CEILING < setup["libraryByteLimit"], "Invalid fixture bounds")
        result["beforeSources"] = source_receipt(directory, "before")
        control = phase("control", "control_recovered")
        result["controlArchives"] = archive_receipt(directory, 1, "control")
        injected = run_injection(helper, interposer, directory, mode, environment, deadline)
        result["injection"] = injected
        fault.write_json(directory / "scenario-result.json", result)
        fault.require(injected.get("status") == "observed" and injected.get("hookWitnessed") is True,
                      "Recovery did not reach the exact witnessed commit hook")
        preserved = phase("verify-preserved", "preserved_verification_complete")
        result["afterFailureSources"] = source_receipt(directory, "after-failure")
        result["afterFailureArchives"] = archive_receipt(directory, 1)
        checks = result["checks"] = {
            "unrestrictedControlRecovered": control.get("exactReplacementReopened") is True,
            "exactTargetRenameWitnessed": injected.get("hookWitnessed") is True,
            "ownedGroupCleaned": injected.get("ownedGroupCleanupComplete") is True,
            "sourceBytesAndIdentitiesPreserved": result["beforeSources"] == result["afterFailureSources"],
            "freshProcessConfirmedOriginalsAndArchive": preserved.get("exactSourceBytesPreserved") is True
                and preserved.get("exactOriginalsArchived") is True,
            "freshConfirmationStillAvailable": preserved.get("freshConfirmationAvailable") is True,
        }
        if mode == "before-rename":
            checks.update({
                "stoppedAtWitnessedCommitBoundary": injected.get("observedStop", {}).get("signal") == signal.SIGSTOP,
                "exactOriginalSourcesAtHook": injected.get("atHookSources") == result["beforeSources"],
                "completeArchiveExistedBeforeCommit": injected.get("atHookArchives") == result["afterFailureArchives"],
                "completeReplacementStagedBeforeCommit": injected.get("stagedExactCandidateBytes") is True,
                "parentKilledOnlyOwnedRecovery": injected.get("parentIssuedSIGKILL") is True
                    and injected.get("returnCode") == -signal.SIGKILL,
            })
        else:
            observed = injected.get("observed", {})
            checks.update({
                "actualFinalRecoveryWriteFailed": injected.get("returnCode") == 0
                    and observed.get("processID") == injected.get("processGroupID")
                    and observed.get("status") == "recovery_write_failed"
                    and observed.get("errorCase") == "recoveryWriteFailed"
                    and observed.get("recoveryCallAttempted") is True,
                "explicitRenameEIOWitnessed": bool(injected.get("events")) and all(
                    event.get("returnedErrno") == errno.EIO and event.get("realRenameCalled") is False
                    for event in injected.get("events", [])),
                "confirmedSnapshotUnchanged": observed.get("confirmedSnapshotUnchanged") is True,
                "completeArchiveRetainedAfterEIO": observed.get("exactOriginalsArchived") is True
                    and injected.get("afterWitnessArchives") == result["afterFailureArchives"],
            })
        fault.require(all(checks.values()), "Commit failure or pre-commit preservation check failed")
        retry = phase("retry", "recovery_retry_complete")
        result["afterRetrySources"] = source_receipt(directory, "after-retry", replacement=True)
        result["afterRetryArchives"] = archive_receipt(directory, 2)
        reopened = phase("verify-recovered", "recovered_verification_complete")
        checks.update({
            "unrestrictedFreshConfirmationRetrySucceeded": retry.get("freshConfirmationObserved") is True
                and retry.get("exactReplacementReopened") is True,
            "retryCreatedDistinctArchive": retry.get("distinctArchiveCreated") is True,
            "earlierArchiveBytesAndIdentitiesRetained": all(
                result["afterRetryArchives"].get(name) == archive
                for name, archive in result["afterFailureArchives"].items()),
            "freshProcessReopenedExactReplacement": reopened.get("exactReplacementReopened") is True,
            "legacySourceStillExact": reopened.get("exactLegacyBytesPreserved") is True,
            "bothArchivesRetained": reopened.get("bothArchivesRetained") is True,
            "unrestrictedControlReopened": reopened.get("unrestrictedControlReopened") is True,
            "validReplacementNoLongerAuthorizesRecovery": reopened.get("recoveryNoLongerNeeded") is True,
        })
        fault.require(all(checks.values()), "Retry or fresh-process verification failed")
        archive = next(iter(result["afterFailureArchives"]))
        result["filesystemProvenance"] = [filesystem_receipt(target, directory, name, environment, deadline)
            for target, name in (
                (directory / "library" / "projects.json", "filesystem-library"),
                (directory / "library" / "Recovery" / archive / "projects.json", "filesystem-original-archive"),
                (directory / "control" / "projects.json", "filesystem-control"))]
        result["status"] = "passed"
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        result["failure"] = {"type": type(error).__name__, "message": str(error)}
    fault.write_json(directory / "scenario-result.json", result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="New evidence directory; parent must exist")
    parser.add_argument("--swiftc", default="swiftc")
    parser.add_argument("--cc", default="cc")
    parser.add_argument("--timeout-seconds", type=float, default=TOTAL_TIMEOUT_SECONDS,
                        help="Overall deadline including compilation, between 1 and 600 seconds")
    args = parser.parse_args()
    repository = Path(__file__).resolve().parent.parent
    output = args.output.resolve()
    environment, removed = fault.clean_environment()
    parent_state = (resource.getrlimit(resource.RLIMIT_FSIZE), signal.getsignal(signal.SIGXFSZ), os.getpgrp())
    deadline = time.monotonic() + args.timeout_seconds
    report = {"schemaVersion": 1, "probe": "project_library_recovery_commit_failure_linux", "status": "failed",
              "output": str(output), "scenarios": [], "totalTimeoutSeconds": args.timeout_seconds,
              "host": {"system": platform.system(), "release": platform.release(), "machine": platform.machine(),
                       "python": platform.python_version()}, "removedInheritedEnvironmentKeys": removed,
              "environment": {key: environment[key] for key in fault.ENVIRONMENT_KEYS if key in environment},
              "excludedClaims": ["power loss or storage durability", "physical low storage or hardware EIO",
                                 "Darwin, iOS, simulator or physical-device execution",
                                 "child cleanup after uncatchable SIGKILL of this driver"]}
    created_output = False
    fault.TERMINATION_SIGNAL = None
    previous_handlers = {number: signal.getsignal(number) for number in (signal.SIGTERM, signal.SIGINT)}
    for number in previous_handlers:
        signal.signal(number, fault.request_termination)
    try:
        fault.require(platform.system() == "Linux", "This diagnostic supports Linux only")
        fault.require(1 <= args.timeout_seconds <= 600, "Overall timeout must be between 1 and 600 seconds")
        output.mkdir(parents=False, exist_ok=False)
        created_output = True
        fault.write_json(output / "result.json", report)
        build = output / "build"
        build.mkdir()
        (build / "temporary").mkdir()
        environment["TMPDIR"] = str(build / "temporary")
        report["filesystemProvenance"] = filesystem_receipt(output, output, "filesystem-output", environment, deadline)
        revision = fault.run_command(["git", "rev-parse", "HEAD"], repository, output, "source-revision",
                                     environment, deadline, 10)
        report["revisionCommand"] = revision
        fault.require(revision.get("returnCode") == 0, "Cannot record source revision")
        report["baseRevision"] = fault.bounded_read(Path(revision["stdoutPath"])).decode().strip()
        report["workingTreeCommand"] = fault.run_command(
            ["git", "status", "--porcelain", "--untracked-files=normal"], repository, output,
            "working-tree", environment, deadline, 10)
        manifest = {"schemaVersion": 1, "source": "current working tree", "baseRevision": report["baseRevision"],
                    "sourceSHA256": source_hashes(repository), "diagnosticSHA256": diagnostic_hashes(repository)}
        report["compileManifest"] = str(output / "compile-manifest.json")
        fault.write_json(output / "compile-manifest.json", manifest)
        compilers = {}
        for label, executable in (("swift", args.swiftc), ("c", args.cc)):
            located = shutil.which(executable, path=environment.get("PATH"))
            fault.require(located is not None, "Compiler not found: " + executable)
            compiler = os.path.abspath(located)
            version = fault.run_command([compiler, "--version"], repository, output, label + "-compiler-version",
                                        environment, deadline, 10)
            fault.require(version.get("returnCode") == 0, "Cannot record compiler version")
            compilers[label] = compiler
            manifest[label + "Compiler"] = {"path": compiler, "resolvedPath": str(Path(compiler).resolve()),
                                           "versionCommand": version,
                                           "version": fault.bounded_read(Path(version["stdoutPath"])).decode()}
        helper = build / "library-recovery-probe"
        swift_command = [compilers["swift"], "-O", "-j", "2", "-module-cache-path", str(build / "module-cache")]
        swift_command += [str(repository / path) for path in manifest["sourceSHA256"]]
        swift_command += ["-o", str(helper)]
        manifest["swiftCompileArguments"] = swift_command
        fault.write_json(output / "compile-manifest.json", manifest)
        manifest["swiftCompile"] = fault.run_command(swift_command, repository, output, "swift-compile",
                                                     environment, deadline, COMPILE_TIMEOUT_SECONDS)
        fault.write_json(output / "compile-manifest.json", manifest)
        fault.require(manifest["swiftCompile"].get("returnCode") == 0, "Recovery helper compilation failed or timed out")
        interposer = build / "probe-library-commit-interposer.so"
        c_command = [compilers["c"], "-std=c11", "-O2", "-fPIC", "-shared", "-Wall", "-Wextra", "-Werror",
                     str(repository / "scripts" / "probe-library-commit-interposer.c"), "-o", str(interposer), "-ldl"]
        manifest["cCompileArguments"] = c_command
        fault.write_json(output / "compile-manifest.json", manifest)
        manifest["cCompile"] = fault.run_command(c_command, repository, output, "c-compile", environment, deadline)
        manifest["sourceSHA256AfterCompilation"] = source_hashes(repository)
        manifest["diagnosticSHA256AfterCompilation"] = diagnostic_hashes(repository)
        manifest["sourcesUnchangedDuringCompilation"] = (
            manifest["sourceSHA256"] == manifest["sourceSHA256AfterCompilation"]
            and manifest["diagnosticSHA256"] == manifest["diagnosticSHA256AfterCompilation"])
        fault.write_json(output / "compile-manifest.json", manifest)
        fault.require(manifest["cCompile"].get("returnCode") == 0, "Interposer compilation failed or timed out")
        fault.require(manifest["sourcesUnchangedDuringCompilation"], "Sources changed during compilation")
        manifest["binarySHA256"] = {path.name: fault.sha256(path) for path in (helper, interposer)}
        fault.write_json(output / "compile-manifest.json", manifest)
        report["compileManifestSHA256"] = fault.sha256(output / "compile-manifest.json")
        for mode in MODES:
            report["scenarios"].append(run_scenario(helper, interposer, output, mode, environment, deadline))
            fault.write_json(output / "result.json", report)
        report["sourcesUnchangedDuringProbe"] = manifest["sourceSHA256"] == source_hashes(repository)
        report["diagnosticsUnchangedDuringProbe"] = manifest["diagnosticSHA256"] == diagnostic_hashes(repository)
        report["binariesUnchangedDuringProbe"] = manifest["binarySHA256"] == {
            path.name: fault.sha256(path) for path in (helper, interposer)}
        fault.require(report["sourcesUnchangedDuringProbe"] and report["diagnosticsUnchangedDuringProbe"]
                      and report["binariesUnchangedDuringProbe"], "Inputs changed during the diagnostic")
        fault.require(len(report["scenarios"]) == len(MODES)
                      and all(case["status"] == "passed" for case in report["scenarios"]),
                      "One or more witnessed recovery scenarios failed; see retained receipts")
        report["status"] = "passed"
    except fault.TerminationRequested as error:
        report["failure"] = {"type": "TerminationRequested", "signal": error.number,
                             "message": "Driver cancellation requested; owned children cleaned below"}
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        for process in list(fault.ACTIVE_CHILDREN.values()):
            try:
                fault.kill_owned_group(process)
            except (OSError, RuntimeError, subprocess.SubprocessError) as error:
                report["status"] = "failed"
                report.setdefault("cleanupErrors", []).append(str(error))
        report["ownedChildrenReaped"] = not fault.ACTIVE_CHILDREN
        report["parentResourceSignalAndGroupUnchanged"] = parent_state == (
            resource.getrlimit(resource.RLIMIT_FSIZE), signal.getsignal(signal.SIGXFSZ), os.getpgrp())
        if not report["ownedChildrenReaped"] or not report["parentResourceSignalAndGroupUnchanged"]:
            report["status"] = "failed"
        for number, handler in previous_handlers.items():
            signal.signal(number, handler)
    if created_output:
        try:
            fault.write_json(output / "result.json", report)
        except OSError as error:
            report["status"] = "failed"
            report["artifactWriteError"] = str(error)
    print(json.dumps({key: report[key] for key in ("probe", "status", "output")}, sort_keys=True))
    if "failure" in report:
        print(json.dumps(report["failure"], sort_keys=True), file=sys.stderr)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
