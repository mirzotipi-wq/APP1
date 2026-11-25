#!/usr/bin/env python3
"""Bounded Linux/macOS EFBIG probe; compile the adjacent Swift helper first.

The output directory must not exist. All generated artifacts remain there.
Only the owned injection child receives RLIMIT_FSIZE; no disk filling, mount,
permission changes, root access, or process interruption is involved.
The compile manifest must provide sourceSHA256 (relative source paths to SHA256)
and binarySHA256 (the helper filename to its SHA256) for the actual build.
"""

import argparse
import errno
import hashlib
import json
import os
from pathlib import Path
import platform
import resource
import signal
import subprocess
import sys


FILE_LIMIT_BYTES = 32 * 1024
FIXTURE_BYTE_CEILING = 1024 * 1024
PHASE_TIMEOUT_SECONDS = 30


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(64 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def efbig_evidence(observed):
    # Cocoa's generic write error is never sufficient evidence. Foundation may
    # omit an underlying POSIX NSError, so the helper also resets errno before
    # save and captures it as the first operation after return or throw.
    chain = observed.get("errorChain", [])
    return {
        "errorChainContainsPOSIXEFBIG": any(
            isinstance(item, dict) and item.get("domain") == "NSPOSIXErrorDomain"
            and item.get("code") == errno.EFBIG for item in chain
        ),
        "resetErrnoCapturedImmediatelyAfterSaveIsEFBIG": (
            observed.get("posixErrnoResetBeforeSave") is True
            and observed.get("posixErrnoImmediatelyAfterSave") == errno.EFBIG
        ),
    }


def limit_injection_child():
    # This script is single-threaded. preexec_fn runs only in its new child;
    # ignored signals remain ignored across exec. Neither parent state changes.
    signal.signal(signal.SIGXFSZ, signal.SIG_IGN)
    resource.setrlimit(resource.RLIMIT_FSIZE, (FILE_LIMIT_BYTES, FILE_LIMIT_BYTES))


def run_phase(helper, output, phase):
    environment = os.environ.copy()
    environment["TMPDIR"] = str(output / "temporary")
    options = {}
    if phase == "inject":
        options = {"preexec_fn": limit_injection_child, "restore_signals": False}
    observation = {"phase": phase, "fileSizeLimitInjected": phase == "inject"}
    try:
        process = subprocess.run(
            [str(helper), phase, str(output)], cwd=output, env=environment,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=PHASE_TIMEOUT_SECONDS, check=False, **options,
        )
        stdout, stderr = process.stdout, process.stderr
        observation["returnCode"] = process.returncode
    except subprocess.TimeoutExpired as error:
        # subprocess.run terminates and reaps only this owned child on timeout.
        stdout, stderr = error.stdout or b"", error.stderr or b""
        observation["timeoutSeconds"] = PHASE_TIMEOUT_SECONDS
    (output / f"{phase}.stdout.json").write_bytes(stdout)
    (output / f"{phase}.stderr.log").write_bytes(stderr)
    try:
        observation["observed"] = json.loads(stdout)
    except (ValueError, UnicodeDecodeError) as error:
        observation["outputError"] = str(error)
    return observation


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--helper", required=True, type=Path, help="Precompiled Swift helper")
    parser.add_argument("--output", required=True, type=Path, help="New directory under caller temporary storage")
    parser.add_argument("--source-revision", required=True, help="Revision label for the compiled source; the compile manifest supplies source hashes")
    parser.add_argument("--compile-manifest", required=True, type=Path,
                        help="Build manifest containing sourceSHA256 and binarySHA256 for this helper")
    args = parser.parse_args()
    helper, output = args.helper.resolve(), args.output.resolve()
    parent_limit = resource.getrlimit(resource.RLIMIT_FSIZE)
    parent_signal = signal.getsignal(signal.SIGXFSZ)
    report = {
        "schemaVersion": 2,
        "probe": "project_library_atomic_write_EFBIG",
        "status": "failed",
        "sourceRevision": args.source_revision,
        "host": {"system": platform.system(), "release": platform.release(),
                 "machine": platform.machine(), "python": platform.python_version()},
        "injection": {"mechanism": "RLIMIT_FSIZE", "fileLimitBytes": FILE_LIMIT_BYTES,
                      "expectedPOSIXErrno": errno.EFBIG, "expectedPOSIXName": "EFBIG",
                      "signal": "SIGXFSZ ignored in injection child only"},
        "parentFileSizeLimitBefore": list(parent_limit),
        "phases": [],
        "excludedClaims": ["ENOSPC or physical low storage", "abrupt process interruption",
                           "rename-only replacement failure", "physical-device or iOS execution"],
    }
    created_output = False
    try:
        require(platform.system() in ("Linux", "Darwin"), "This diagnostic supports Linux and macOS")
        require(helper.is_file() and os.access(helper, os.X_OK), "Swift helper must be an executable regular file")
        require(parent_limit[0] == resource.RLIM_INFINITY or parent_limit[0] >= FIXTURE_BYTE_CEILING,
                "Parent file-size limit is too small for unrestricted setup/control")
        output.mkdir(parents=False, exist_ok=False)
        created_output = True
        (output / "temporary").mkdir()
        repository = Path(__file__).resolve().parent.parent
        sources = sorted((repository / "Sources" / "LightingCore").glob("*.swift"))
        sources += [repository / "scripts" / "probe-atomic-library-write.swift", Path(__file__).resolve()]
        report["workingTreeFilesSHA256"] = {str(path.relative_to(repository)): sha256(path) for path in sources}
        report["helperBinarySHA256"] = sha256(helper)
        manifest_path = args.compile_manifest.resolve()
        require(manifest_path.stat().st_size <= FIXTURE_BYTE_CEILING, "Compile manifest exceeds diagnostic bound")
        manifest_bytes = manifest_path.read_bytes()
        manifest = json.loads(manifest_bytes)
        require(isinstance(manifest, dict), "Compile manifest must be an object")
        compiled_sources = manifest.get("sourceSHA256")
        compiled_binaries = manifest.get("binarySHA256")
        require(isinstance(compiled_sources, dict) and bool(compiled_sources)
                and all(isinstance(path, str) and isinstance(digest, str) and len(digest) == 64
                        and all(character in "0123456789abcdef" for character in digest)
                        for path, digest in compiled_sources.items()),
                "Compile manifest must identify compiled source hashes")
        require("scripts/probe-atomic-library-write.swift" in compiled_sources
                and any(path.startswith("Sources/LightingCore/") and path.endswith(".swift")
                        for path in compiled_sources),
                "Compile manifest must identify the Swift helper and LightingCore sources")
        require(isinstance(compiled_binaries, dict)
                and compiled_binaries.get(helper.name) == report["helperBinarySHA256"],
                "Helper binary does not match the supplied compile manifest")
        (output / "compile-manifest.json").write_bytes(manifest_bytes)
        report["compiledSourceProvenance"] = {
            "manifestPath": str(manifest_path),
            "manifestSHA256": hashlib.sha256(manifest_bytes).hexdigest(),
            "baseRevision": manifest.get("baseRevision"),
            "source": manifest.get("source"),
            "helperBinaryMatchesManifest": True,
            "sourceFilesSHA256": compiled_sources,
            "workingTreePathsDifferingFromCompiledSources": sorted(
                path for path, digest in compiled_sources.items()
                if report["workingTreeFilesSHA256"].get(path) != digest
            ),
        }

        setup = run_phase(helper, output, "setup")
        report["phases"].append(setup)
        require(setup.get("returnCode") == 0 and setup.get("observed", {}).get("status") == "setup_complete",
                "Unrestricted setup failed; no injected write result is certified")
        before = (output / "prior.json").read_bytes()
        proposed = (output / "candidate.json").read_bytes()
        byte_limit = setup["observed"]["libraryByteLimit"]
        require(0 < len(before) < FILE_LIMIT_BYTES < len(proposed) <= FIXTURE_BYTE_CEILING < byte_limit,
                "Fixtures do not straddle the injection limit below the application limit")

        control = run_phase(helper, output, "control")
        report["phases"].append(control)
        require(control.get("returnCode") == 0 and control.get("observed", {}).get("status") == "control_saved",
                "Unrestricted control save failed; no injected write result is certified")

        injection = run_phase(helper, output, "inject")
        report["phases"].append(injection)
        # Always collect a fresh-process reopen after the injection, even when
        # its exception/termination is unexpected. A setup failure is distinct.
        verification = run_phase(helper, output, "verify")
        report["phases"].append(verification)
        current = output / "library" / "projects.json"
        require(current.stat().st_size <= FIXTURE_BYTE_CEILING, "Post-failure file exceeded diagnostic bound")
        after = current.read_bytes()
        (output / "after.json").write_bytes(after)
        report["files"] = {}
        for relative in ("prior.json", "candidate.json", "after.json", "library/projects.json", "control/projects.json"):
            path = output / relative
            report["files"][relative] = {"bytes": path.stat().st_size, "sha256": sha256(path)}
        observed = injection.get("observed", {})
        verified = verification.get("observed", {})
        report["expectedFailureEvidence"] = efbig_evidence(observed)
        report["checks"] = {
            "setupAndUnrestrictedControlSucceeded": True,
            "validFixturesBelowApplicationByteLimit": True,
            "injectionReturnedCaughtSaveError": injection.get("returnCode") == 0 and observed.get("status") == "save_threw"
                and observed.get("writeAttempted") is True,
            "observedPOSIXEFBIG": any(report["expectedFailureEvidence"].values()),
            "freshProcessVerificationSucceeded": verification.get("returnCode") == 0
                and verified.get("status") == "verification_complete",
            "exactPriorBytesPreserved": before == after,
            "priorCompleteSnapshotPreserved": verified.get("priorCompleteSnapshotPreserved") is True,
            "unrelatedRecordsPreserved": verified.get("unrelatedRecordsPreserved") is True,
            "activeIdentityPreserved": verified.get("activeIdentityPreserved") is True,
            "unrestrictedControlCandidateReopened": verified.get("controlCandidateReopened") is True
                and verified.get("controlExactCandidateBytes") is True,
            "unrestrictedControlExactCandidateBytes": (output / "control" / "projects.json").read_bytes() == proposed,
        }
        require(all(report["checks"].values()), "One or more observed failure/control/reopen checks failed")
        report["status"] = "passed"
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report["failure"] = {"type": type(error).__name__, "message": str(error)}
    finally:
        report["parentFileSizeLimitAfter"] = list(resource.getrlimit(resource.RLIMIT_FSIZE))
        report["parentLimitAndSignalUnchanged"] = (
            resource.getrlimit(resource.RLIMIT_FSIZE) == parent_limit
            and signal.getsignal(signal.SIGXFSZ) == parent_signal
        )
        if not report["parentLimitAndSignalUnchanged"]:
            report["status"] = "failed"
            report["failure"] = {"type": "ParentStateChanged", "message": "Parent resource or signal state changed"}
    result = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if created_output:
        try:
            (output / "result.json").write_text(result, encoding="utf-8")
        except OSError as error:
            report["status"] = "failed"
            report["artifactWriteError"] = str(error)
            result = json.dumps(report, indent=2, sort_keys=True) + "\n"
    sys.stdout.write(result)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
