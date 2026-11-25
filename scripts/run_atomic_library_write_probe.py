#!/usr/bin/env python3
"""Compile current LightingCore sources and run bounded persistence probes.

--output must name a new directory whose parent exists. Compiler and probe logs,
the compile manifest, and the raw probe artifacts remain there on success/failure.
Compilation runs in its own child with no injected resource or signal limits;
only the existing probe runner applies RLIMIT_FSIZE to its injection child.
On Linux, --with-commit-interruption also runs witnessed rename-boundary probes
with the same compiled helper and a shared overall probe time budget.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import signal
import subprocess
import sys
import tempfile
import time


COMPILE_TIMEOUT_SECONDS = 180
PROBE_TIMEOUT_SECONDS = 140
METADATA_TIMEOUT_SECONDS = 10


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(64 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def source_hashes(repository):
    # Re-enumerate each time so additions/removals also invalidate the build.
    sources = sorted((repository / "Sources" / "LightingCore").glob("*.swift"))
    require(bool(sources), "No LightingCore Swift sources found")
    sources.append(repository / "scripts" / "probe-atomic-library-write.swift")
    return {str(path.relative_to(repository)): sha256(path) for path in sources}


def diagnostic_hashes(repository, with_commit_interruption=False):
    names = [
        "probe_atomic_library_write.py", "run_atomic_library_write_probe.py",
    ]
    if with_commit_interruption:
        names += ["probe-library-commit-interposer.c", "probe_library_commit_interruption.py"]
    return {"scripts/" + name: sha256(repository / "scripts" / name) for name in names}


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def run_logged(arguments, repository, output, name, timeout, graceful_timeout_seconds=0):
    observation = {"arguments": arguments, "cwd": str(repository), "timeoutSeconds": timeout}
    if graceful_timeout_seconds:
        observation["gracefulTerminationSeconds"] = graceful_timeout_seconds
    print("Running " + json.dumps(arguments), flush=True)
    started = time.monotonic()
    with (output / (name + ".stdout.log")).open("wb") as stdout, \
            (output / (name + ".stderr.log")).open("wb") as stderr:
        process = subprocess.Popen(arguments, cwd=repository, stdout=stdout, stderr=stderr,
                                   start_new_session=True)
        observation["processGroupID"] = process.pid

        def stop_owned_group():
            # The new session isolates this compiler/probe and its descendants
            # from the runner, parent, and every unrelated process.
            if graceful_timeout_seconds:
                # The commit driver owns additional child sessions. Give its
                # signal handler time to clean them up before terminating the
                # driver itself. A forced fallback is not proof of that cleanup.
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=graceful_timeout_seconds)
                    return "SIGTERM to owned driver group; direct child reaped within grace period"
                except subprocess.TimeoutExpired:
                    observation["gracefulTerminationExpired"] = True
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait(timeout=10)
            return "SIGKILL to owned process group; direct child reaped"

        try:
            observation["returnCode"] = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            observation["timedOut"] = True
            observation["timeoutCleanup"] = stop_owned_group()
        except BaseException:
            stop_owned_group()
            raise
    observation["elapsedSeconds"] = round(time.monotonic() - started, 3)
    for suffix, destination in (("stdout", sys.stdout), ("stderr", sys.stderr)):
        path = output / (name + "." + suffix + ".log")
        observation[suffix + "Path"] = str(path)
        with path.open("rb") as stream:
            destination.flush()
            shutil.copyfileobj(stream, destination.buffer)
            destination.flush()
    return observation


def host_sdk_arguments(repository, output, manifest, manifest_path):
    if platform.system() != "Darwin":
        return []
    # A direct Xcode swiftc invocation needs an explicit host SDK. xcrun uses
    # the same inherited developer/toolchain selection as the compiler lookup;
    # selecting macosx explicitly also avoids an inherited iOS SDKROOT.
    sdk = {"name": "macosx", "environment": {
        name: os.environ.get(name) for name in ("DEVELOPER_DIR", "TOOLCHAINS", "SDKROOT")
    }}
    manifest["hostSDK"] = sdk
    write_json(manifest_path, manifest)
    xcrun = shutil.which("xcrun")
    require(xcrun is not None, "xcrun is required to discover the macOS host SDK")
    arguments = [os.path.abspath(xcrun), "--sdk", "macosx", "--show-sdk-path"]
    sdk["discoveryArguments"] = arguments
    write_json(manifest_path, manifest)
    sdk["discovery"] = run_logged(arguments, repository, output, "macos-sdk", METADATA_TIMEOUT_SECONDS)
    # Retain the lookup receipt even when its exit status, output, or path is
    # invalid. A discovery failure must never fall through to compilation.
    write_json(manifest_path, manifest)
    require(sdk["discovery"].get("returnCode") == 0, "macOS host SDK discovery failed or timed out")
    sdk_path = (output / "macos-sdk.stdout.log").read_text(encoding="utf-8").strip()
    sdk["path"] = sdk_path
    write_json(manifest_path, manifest)
    require(bool(sdk_path) and "\n" not in sdk_path and "\r" not in sdk_path
            and Path(sdk_path).is_absolute() and Path(sdk_path).is_dir(),
            "macOS host SDK discovery did not return one existing absolute directory")
    sdk["resolvedPath"] = str(Path(sdk_path).resolve())
    write_json(manifest_path, manifest)
    return ["-sdk", sdk_path]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="New evidence directory")
    parser.add_argument("--swiftc", default="swiftc", help="Swift compiler executable or path")
    parser.add_argument("--with-commit-interruption", action="store_true",
                        help="Also verify witnessed pre/post-rename interruption and rename EIO on Linux")
    args = parser.parse_args()
    repository = Path(__file__).resolve().parent.parent
    output = args.output.resolve()
    report = {"schemaVersion": 1, "status": "failed", "output": str(output),
              "commitInterruptionRequested": args.with_commit_interruption,
              "host": {"system": platform.system(), "machine": platform.machine(),
                       "python": platform.python_version()}}
    created_output = False
    try:
        require(platform.system() in ("Linux", "Darwin"), "This diagnostic supports Linux and macOS")
        output.mkdir(parents=False, exist_ok=False)
        created_output = True
        write_json(output / "wrapper-result.json", report)
        require(not args.with_commit_interruption or platform.system() == "Linux",
                "Commit interruption injection is supported only by the Linux host diagnostic")
        compiler = shutil.which(args.swiftc)
        require(compiler is not None, "Swift compiler not found: " + args.swiftc)
        # Preserve the swiftc invocation name: resolving a driver symlink can
        # change Swift driver behavior. Record its resolved target separately.
        compiler = os.path.abspath(compiler)
        manifest = {"schemaVersion": 1, "source": "current working tree",
                    "compilerPath": compiler, "compilerResolvedPath": str(Path(compiler).resolve())}
        report["revision"] = run_logged(["git", "rev-parse", "HEAD"], repository, output,
                                        "source-revision", METADATA_TIMEOUT_SECONDS)
        require(report["revision"].get("returnCode") == 0, "Cannot record source revision")
        revision = (output / "source-revision.stdout.log").read_text(encoding="utf-8").strip()
        manifest["baseRevision"] = report["baseRevision"] = revision
        manifest["compilerVersionCommand"] = run_logged([compiler, "--version"], repository, output,
                                                       "compiler-version", METADATA_TIMEOUT_SECONDS)
        require(manifest["compilerVersionCommand"].get("returnCode") == 0,
                "Cannot record Swift compiler version")
        manifest["compilerVersion"] = (output / "compiler-version.stdout.log").read_text(encoding="utf-8")
        manifest["sourceSHA256"] = source_hashes(repository)
        manifest["sourceSHA256BeforeCompilation"] = manifest["sourceSHA256"]
        manifest["diagnosticSHA256BeforeCompilation"] = diagnostic_hashes(repository, args.with_commit_interruption)
        manifest_path = output / "compile-manifest.json"
        sdk_arguments = host_sdk_arguments(repository, output, manifest, manifest_path)
        with tempfile.TemporaryDirectory(prefix="atomic-library-write-build-") as build_directory:
            build = Path(build_directory)
            helper = build / "atomic-library-write-probe"
            command = [compiler, "-O"] + sdk_arguments + ["-module-cache-path", str(build / "module-cache")]
            command += [str(repository / path) for path in manifest["sourceSHA256"]]
            command += ["-o", str(helper)]
            manifest["compileArguments"] = command
            write_json(manifest_path, manifest)
            manifest["compile"] = run_logged(command, repository, output, "compile", COMPILE_TIMEOUT_SECONDS)
            manifest["sourceSHA256AfterCompilation"] = source_hashes(repository)
            manifest["diagnosticSHA256AfterCompilation"] = diagnostic_hashes(repository, args.with_commit_interruption)
            manifest["sourcesUnchangedDuringCompilation"] = (
                manifest["sourceSHA256BeforeCompilation"] == manifest["sourceSHA256AfterCompilation"]
                and manifest["diagnosticSHA256BeforeCompilation"] == manifest["diagnosticSHA256AfterCompilation"]
            )
            write_json(manifest_path, manifest)
            require(manifest["sourcesUnchangedDuringCompilation"],
                    "Source files changed during compilation; probe was not run")
            require(manifest["compile"].get("returnCode") == 0, "Swift helper compilation failed or timed out")
            manifest["binarySHA256"] = {helper.name: sha256(helper)}
            write_json(manifest_path, manifest)
            report["compileManifestSHA256"] = sha256(manifest_path)
            probe_started = time.monotonic()
            report["probe"] = run_logged(
                [sys.executable, str(repository / "scripts" / "probe_atomic_library_write.py"),
                 "--helper", str(helper), "--output", str(output / "probe"),
                 "--source-revision", revision, "--compile-manifest", str(manifest_path)],
                repository, output, "probe", PROBE_TIMEOUT_SECONDS,
            )
            require(report["probe"].get("returnCode") == 0, "EFBIG probe failed or timed out; see raw probe artifacts")
            probe_result = json.loads((output / "probe" / "result.json").read_text(encoding="utf-8"))
            require(probe_result.get("status") == "passed", "EFBIG probe did not produce a passing result")
            if args.with_commit_interruption:
                # Both families share the old work budget, including a ten-second
                # driver TERM grace. Its inner deadline leaves another ten
                # seconds for normal owned-child cleanup before the outer signal.
                remaining = PROBE_TIMEOUT_SECONDS - (time.monotonic() - probe_started)
                require(remaining > 21, "Insufficient remaining budget for commit interruption probes")
                outer_timeout = remaining - 10
                report["commitInterruption"] = run_logged(
                    [sys.executable, str(repository / "scripts" / "probe_library_commit_interruption.py"),
                     "--helper", str(helper), "--output", str(output / "commit-interruption"),
                     "--source-revision", revision, "--compile-manifest", str(manifest_path),
                     "--timeout-seconds", str(min(120, outer_timeout - 10))],
                    repository, output, "commit-interruption", outer_timeout,
                    graceful_timeout_seconds=10,
                )
                require(report["commitInterruption"].get("returnCode") == 0,
                        "Commit interruption probe failed or timed out; see raw artifacts")
                commit_result = json.loads((output / "commit-interruption" / "result.json").read_text(encoding="utf-8"))
                require(commit_result.get("status") == "passed",
                        "Commit interruption probe did not produce a passing result")
            report["sourceSHA256AfterProbe"] = source_hashes(repository)
            report["diagnosticSHA256AfterProbe"] = diagnostic_hashes(repository, args.with_commit_interruption)
            report["sourcesUnchangedDuringProbe"] = (
                manifest["sourceSHA256"] == report["sourceSHA256AfterProbe"]
                and manifest["diagnosticSHA256BeforeCompilation"] == report["diagnosticSHA256AfterProbe"]
            )
            require(report["sourcesUnchangedDuringProbe"], "Source files changed during the probe")
            report["status"] = "passed"
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        report["failure"] = {"type": type(error).__name__, "message": str(error)}
    if created_output:
        try:
            write_json(output / "wrapper-result.json", report)
        except OSError as error:
            report["status"] = "failed"
            report["artifactWriteError"] = str(error)
    print("Compile/probe wrapper result:")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
