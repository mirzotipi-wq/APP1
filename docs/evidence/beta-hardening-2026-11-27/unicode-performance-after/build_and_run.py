#!/usr/bin/env python3
"""Run only after root grants the Swift compiler slot; all writes stay here."""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import pathlib
import statistics
import subprocess
import time

ROOT = pathlib.Path(__file__).resolve().parent


def now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compiler-released-by-root", action="store_true", required=True)
    parser.add_argument("--swift-toolchain", type=pathlib.Path,
                        default=ROOT.parent / "toolchains" / "swift-6.0.3" / "usr")
    parser.add_argument("--phase", choices=["build", "pilot", "full"], required=True)
    args = parser.parse_args()
    manifest = json.loads((ROOT / "manifest.json").read_text())
    for path in [ROOT / "cache", ROOT / "cache" / "modules", ROOT / "tmp", ROOT / "logs"]:
        path.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["TMPDIR"] = str(ROOT / "tmp")
    env["CLANG_MODULE_CACHE_PATH"] = str(ROOT / "cache" / "modules")
    env["SWIFT_MODULECACHE_PATH"] = str(ROOT / "cache" / "modules")
    env["SWIFTPM_MODULECACHE_OVERRIDE"] = str(ROOT / "cache" / "modules")
    env["XDG_CACHE_HOME"] = str(ROOT / "cache")
    env["PATH"] = str(args.swift_toolchain / "bin") + os.pathsep + env["PATH"]
    binary = ROOT / "decode-probe"
    if args.phase == "build":
        swiftc = args.swift_toolchain / "bin" / "swiftc"
        version = subprocess.check_output([str(swiftc), "--version"], env=env, text=True)
        command = [str(swiftc), "-O", "-whole-module-optimization", "-num-threads", "1",
                   "-module-name", "A027DecodeProbe", "-module-cache-path", str(ROOT / "cache" / "modules"),
                   *map(str, sorted((ROOT / "sources").glob("*.swift"))), str(ROOT / "main.swift"),
                   "-o", str(binary)]
        start = now()
        outcome = subprocess.run(command, cwd=ROOT, env=env, text=True, capture_output=True, timeout=300)
        (ROOT / "logs" / "build.stdout").write_text(outcome.stdout)
        (ROOT / "logs" / "build.stderr").write_text(outcome.stderr)
        result = {"started": start, "ended": now(), "command": command,
                  "swift": version, "exit_code": outcome.returncode,
                  "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest() if outcome.returncode == 0 else None,
                  "cache_path": str(ROOT / "cache")}
        (ROOT / "build.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result, indent=2), flush=True)
        raise SystemExit(outcome.returncode)

    fixtures = manifest["fixtures"]
    if args.phase == "pilot":
        fixtures = [f for f in fixtures if f["id"] == "empty_strings_1mib"]
    samples = 1 if args.phase == "pilot" else 3
    records = []
    raw_path = ROOT / f"{args.phase}-raw.jsonl"
    if raw_path.exists():
        raise SystemExit(f"Refusing to overwrite retained measurements: {raw_path}")
    started = now()
    with raw_path.open("x") as raw:
        for sample in range(samples):
            # Rotate three parser orders so each occupies every position once.
            variants = (("baseline", "before", "current"), ("current", "baseline", "before"), ("before", "current", "baseline"))[sample % 3]
            for fixture in fixtures:
                path = ROOT / fixture["path"]
                assert hashlib.sha256(path.read_bytes()).hexdigest() == fixture["sha256"]
                # Batch the ordinary tiny control to make timer overhead immaterial.
                iterations = 1000 if fixture["id"] == "ordinary" else 1
                warmups = 10 if fixture["id"] == "ordinary" else (0 if args.phase == "pilot" else 1)
                for variant in variants:
                    command = [str(binary), variant, str(path), str(warmups), str(iterations)]
                    t0 = time.monotonic_ns()
                    completed = subprocess.run(command, cwd=ROOT, env=env, text=True, capture_output=True, timeout=120)
                    wall = time.monotonic_ns() - t0
                    record = {
                        "fixture": fixture["id"], "sample": sample + 1,
                        "utc": now(), "command": command, "exit_code": completed.returncode,
                        "process_wall_nanoseconds": wall, "stderr": completed.stderr,
                        "host_loadavg": os.getloadavg(),
                    }
                    if completed.returncode == 0:
                        record.update(json.loads(completed.stdout))
                        assert record["checksum"] == (warmups + iterations) * 14
                        assert record["input_bytes"] == fixture["bytes"]
                    else:
                        record["stdout"] = completed.stdout
                    raw.write(json.dumps(record, sort_keys=True) + "\n")
                    raw.flush()
                    records.append(record)
                    print(json.dumps(record, sort_keys=True), flush=True)
                    if completed.returncode:
                        raise SystemExit(completed.returncode)

    summaries = []
    for fixture in fixtures:
        summary = dict(fixture)
        for variant in ("baseline", "before", "current"):
            subset = [r for r in records if r["fixture"] == fixture["id"] and r["variant"] == variant]
            summary[variant] = {
                "samples": len(subset),
                "median_ms": statistics.median(r["nanoseconds_per_decode"] for r in subset) / 1e6,
                "raw_ms": [r["nanoseconds_per_decode"] / 1e6 for r in subset],
                "raw_maximum_rss_kib": [r.get("maximum_rss_kib") for r in subset],
            }
        summary["current_over_baseline"] = summary["current"]["median_ms"] / summary["baseline"]["median_ms"]
        summary["current_over_before"] = summary["current"]["median_ms"] / summary["before"]["median_ms"]
        summary["before_delta_ms"] = summary["current"]["median_ms"] - summary["before"]["median_ms"]
        summary["median_delta_ms"] = summary["current"]["median_ms"] - summary["baseline"]["median_ms"]
        summaries.append(summary)
    report = {"started": started, "ended": now(), "phase": args.phase,
              "method": "Same optimized binary and host; exact production full decode; each full-matrix large-input sample has one untimed warmup and one timed decode in its own process. Three samples per parser/fixture, rotating baseline/before/current parser order by round. Tiny ordinary control uses ten warmups and 1000 timed decodes per process. File reads excluded from decode timer; VmHWM includes process, input read and warmup. No timing threshold or device claim.",
              "results": summaries}
    (ROOT / f"{args.phase}-summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    main()
