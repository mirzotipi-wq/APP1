#!/usr/bin/env python3
"""Stage the frozen A027 three-variant probe in a fresh directory, then run it."""
from __future__ import annotations

import argparse
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys

# Importing the fixture helpers must not create caches beside preserved evidence.
sys.dont_write_bytecode = True
from reconstruct_inputs import (EVIDENCE, FROZEN_HASHES, digest, load_manifests,
                                new_output_directory, read_checked, verify_inputs,
                                write_json, write_new)


def now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def run(args: argparse.Namespace) -> int:
    _, manifest = load_manifests()
    fixtures = args.fixtures_dir.expanduser().resolve(strict=True)
    verify_inputs(fixtures, manifest["fixtures"])
    toolchain = args.swift_toolchain.expanduser().resolve(strict=True)
    swiftc = toolchain / "bin" / "swiftc"
    if not swiftc.is_file() or not os.access(swiftc, os.X_OK):
        raise ValueError(f"Expected an executable Swift compiler: {swiftc}")

    snapshot = EVIDENCE / "unicode-performance-after"
    source_hashes = {
        Path(item["path"]).name: item["sha256"] for item in manifest["sources"]
    }
    source_hashes.update({
        "BaselineProjectDocument.swift": manifest["baseline_renamed_parser_sha256"],
        "BeforeProjectDocument.swift": manifest["before_parser_sha256"],
    })
    if {p.name for p in (snapshot / "sources").glob("*.swift")} != set(source_hashes):
        raise ValueError("Frozen Swift source inventory differs from the manifest")
    staged = {
        f"sources/{name}": read_checked(snapshot / "sources" / name, sha)
        for name, sha in source_hashes.items()
    }
    for name in ("main.swift", "build_and_run.py"):
        staged[name] = read_checked(snapshot / name, manifest["probe_files"][name])
    staged["manifest.json"] = read_checked(
        snapshot / "manifest.json", FROZEN_HASHES["unicode-performance-after/manifest.json"])
    for fixture in manifest["fixtures"]:
        staged[fixture["path"]] = read_checked(fixtures / fixture["path"], fixture["sha256"])

    # No compiler starts until every dependency and input is verified, and a
    # non-colliding output directory has been created outside preserved evidence.
    output = new_output_directory(args.output_dir)
    for name in ("sources", "inputs", "logs"):
        (output / name).mkdir()
    for name, data in staged.items():
        write_new(output / name, data)
        read_checked(output / name, digest(data))
    write_json(output / "staged-files.json", {
        "schema": 1, "snapshot": "unicode-performance-after",
        "note": "Copied manifest describes the original snapshot; run.json/build.json describe this run.",
        "files": {name: digest(data) for name, data in sorted(staged.items())},
    })
    receipts = []
    for phase in ("build", "pilot", "full"):
        command = [sys.executable, "-B", str(output / "build_and_run.py"),
                   "--compiler-released-by-root", "--swift-toolchain", str(toolchain),
                   "--phase", phase]
        started = now()
        with (output / "logs" / f"reproduce-{phase}.stdout").open("x") as stdout, \
                (output / "logs" / f"reproduce-{phase}.stderr").open("x") as stderr:
            result = subprocess.run(command, cwd=output, stdout=stdout, stderr=stderr)
        receipts.append({"phase": phase, "started": started, "ended": now(),
                         "command": command, "exit_code": result.returncode})
        print(f"{phase}: exit {result.returncode}; logs in {output / 'logs'}", flush=True)
        if result.returncode:
            break
    write_json(output / "run.json", {
        "schema": 1, "swift_toolchain": str(toolchain), "phases": receipts,
        "completed_all_phases": len(receipts) == 3 and receipts[-1]["exit_code"] == 0,
        "scope": "Host observation only; no device-performance claim or acceptance threshold",
    })
    return receipts[-1]["exit_code"]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swift-toolchain", type=Path, required=True,
                        help="Explicit toolchain usr directory containing bin/swiftc")
    parser.add_argument("--fixtures-dir", type=Path, required=True,
                        help="Output directory from reconstruct_inputs.py")
    parser.add_argument("--output-dir", type=Path, required=True,
                        help="Fresh run directory outside preserved evidence")
    parser.add_argument("--compiler-released-by-root", action="store_true", required=True,
                        help="Retain the original probe's compiler-slot coordination requirement")
    args = parser.parse_args()
    try:
        raise SystemExit(run(args))
    except (OSError, ValueError) as error:
        parser.exit(1, f"error: {error}\n")


if __name__ == "__main__":
    main()
