#!/usr/bin/env python3
"""Compile current LightingCore sources, record provenance, and run the EFBIG probe.

--output must name a new directory whose parent exists. Compiler and probe logs,
the compile manifest, and the raw probe artifacts remain there on success/failure.
Compilation runs in its own child with no injected resource or signal limits;
only the existing probe runner applies RLIMIT_FSIZE to its injection child.
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


def diagnostic_hashes(repository):
    return {"scripts/" + name: sha256(repository / "scripts" / name) for name in (
        "probe_atomic_library_write.py", "run_atomic_library_write_probe.py",
    )}


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def run_logged(arguments, repository, output, name, timeout):
    observation = {"arguments": arguments, "cwd": str(repository), "timeoutSeconds": timeout}
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
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait(timeout=10)

        try:
            observation["returnCode"] = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            observation["timedOut"] = True
            stop_owned_group()
            observation["timeoutCleanup"] = "SIGKILL to owned process group; direct child reaped"
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="New evidence directory")
    parser.add_argument("--swiftc", default="swiftc", help="Swift compiler executable or path")
    args = parser.parse_args()
    repository = Path(__file__).resolve().parent.parent
    output = args.output.resolve()
    report = {"schemaVersion": 1, "status": "failed", "output": str(output),
              "host": {"system": platform.system(), "machine": platform.machine(),
                       "python": platform.python_version()}}
    created_output = False
    try:
        require(platform.system() in ("Linux", "Darwin"), "This diagnostic supports Linux and macOS")
        output.mkdir(parents=False, exist_ok=False)
        created_output = True
        write_json(output / "wrapper-result.json", report)
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
        manifest["diagnosticSHA256BeforeCompilation"] = diagnostic_hashes(repository)
        manifest_path = output / "compile-manifest.json"
        with tempfile.TemporaryDirectory(prefix="atomic-library-write-build-") as build_directory:
            build = Path(build_directory)
            helper = build / "atomic-library-write-probe"
            command = [compiler, "-O", "-module-cache-path", str(build / "module-cache")]
            command += [str(repository / path) for path in manifest["sourceSHA256"]]
            command += ["-o", str(helper)]
            manifest["compileArguments"] = command
            write_json(manifest_path, manifest)
            manifest["compile"] = run_logged(command, repository, output, "compile", COMPILE_TIMEOUT_SECONDS)
            manifest["sourceSHA256AfterCompilation"] = source_hashes(repository)
            manifest["diagnosticSHA256AfterCompilation"] = diagnostic_hashes(repository)
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
            report["probe"] = run_logged(
                [sys.executable, str(repository / "scripts" / "probe_atomic_library_write.py"),
                 "--helper", str(helper), "--output", str(output / "probe"),
                 "--source-revision", revision, "--compile-manifest", str(manifest_path)],
                repository, output, "probe", PROBE_TIMEOUT_SECONDS,
            )
            report["sourceSHA256AfterProbe"] = source_hashes(repository)
            report["diagnosticSHA256AfterProbe"] = diagnostic_hashes(repository)
            report["sourcesUnchangedDuringProbe"] = (
                manifest["sourceSHA256"] == report["sourceSHA256AfterProbe"]
                and manifest["diagnosticSHA256BeforeCompilation"] == report["diagnosticSHA256AfterProbe"]
            )
            require(report["sourcesUnchangedDuringProbe"], "Source files changed during the probe")
            require(report["probe"].get("returnCode") == 0, "EFBIG probe failed or timed out; see raw probe artifacts")
            probe_result = json.loads((output / "probe" / "result.json").read_text(encoding="utf-8"))
            require(probe_result.get("status") == "passed", "EFBIG probe did not produce a passing result")
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
