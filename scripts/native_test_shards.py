#!/usr/bin/env python3
"""Fail-closed required/diagnostic XCTest partition and execution accounting."""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHARDS = {
    "room-precision": ("ManualRoomPlacementUITests", "PrecisionEditingUITests"),
    "library-reference": ("ProjectLibraryUITests", "ReferenceComparisonUITests"),
    "studio-export": ("StudioSmokeTests", "LightingPlanExportUITests"),
    "beta-workflows": ("BetaWorkflowUITests", "PlanGestureUITests", "BetaAccessibilityUITests"),
    "studio-optics": ("StudioOpticsUITests",),
    "app-accessibility": ("StudioAppAccessibilityUITests",),
}
# Owner-approved m02-m03-code-v2 keeps Apple's full audits intact as explicit
# diagnostics. Every class must still belong to exactly one declared suite.
DIAGNOSTIC_SHARDS = {"platform-audit": ("AccessibilityAuditUITests",)}
TEST_CASE_MARKER = re.compile(r"\bTest Case\b")
TEST_CASE_EVENT = re.compile(
    r"Test Case '-\[(?P<target>[^.\s\[\]]+)\.(?P<class>\w+) (?P<method>\w+)\]' "
    r"(?P<event>\w+)(?: \(\d+(?:\.\d+)? seconds\))?\.?\s*"
)


def discover_ui_classes():
    result = set()
    # XcodeGen includes source-directory descendants; the coverage check must
    # discover the same nested Swift files before allowing shard selection.
    for file in (ROOT / "UITests").rglob("*.swift"):
        content = file.read_text(encoding="utf-8")
        classes = re.findall(r"\bclass\s+(\w+)\s*:\s*XCTestCase\b", content)
        if re.search(r"\bfunc\s+test\w*\s*\(", content) and not classes:
            raise ValueError(f"Test methods outside a recognized XCTestCase: {file.name}")
        for name in classes:
            if name in result:
                raise ValueError(f"Duplicate XCTestCase: {name}")
            result.add(name)
    if not result:
        raise ValueError("No UI test classes discovered")
    return result


def check():
    expected = discover_ui_classes()
    if set(SHARDS) & set(DIAGNOSTIC_SHARDS):
        raise ValueError("A shard is both required and diagnostic")
    assigned = [name for names in (*SHARDS.values(), *DIAGNOSTIC_SHARDS.values()) for name in names]
    if len(assigned) != len(set(assigned)):
        raise ValueError("A UI test class is assigned to more than one shard")
    if set(assigned) != expected:
        raise ValueError(f"Missing UI classes: {expected - set(assigned)}; stale assignments: {set(assigned) - expected}")
    # Keep the workflow matrix and Python selector map in agreement.
    workflow = (ROOT / ".github/workflows/ios-prototype.yml").read_text(encoding="utf-8")
    matrix = re.search(r"^\s*shard:\s*\[([^\]]+)\]\s*$", workflow, re.MULTILINE)
    if not matrix:
        raise ValueError("Native UI matrix missing")
    matrix_names = [part.strip() for part in matrix.group(1).split(",")]
    if len(matrix_names) != len(set(matrix_names)) or set(matrix_names) != set(SHARDS):
        raise ValueError(f"UI shard matrix does not match selectors: {matrix_names}")
    if DIAGNOSTIC_SHARDS:
        diagnostic = (ROOT / ".github/workflows/platform-accessibility-diagnostics.yml").read_text(encoding="utf-8")
        if not re.search(r"^\s+workflow_dispatch:\s*$", diagnostic, re.MULTILINE):
            raise ValueError("Platform diagnostics must be explicitly dispatched")
        if re.search(r"^\s+(push|pull_request|schedule|workflow_run|workflow_call):", diagnostic, re.MULTILINE):
            raise ValueError("Platform diagnostics must not run automatically")
        selectors = re.findall(r"^\s+TEST_SHARD:\s*(\S+)\s*$", diagnostic, re.MULTILINE)
        if len(selectors) != len(set(selectors)) or set(selectors) != set(DIAGNOSTIC_SHARDS):
            raise ValueError("Diagnostic workflow selectors do not match declarations")
    return expected


def discover_methods(directory):
    """The repository's XCTest files each contain one concrete test class.

    Reject a new unsupported container rather than silently omitting it. The
    simulator-only conditional in StudioSmokeTests is active in these jobs.
    """
    result = {}
    for file in (ROOT / directory).rglob("*.swift"):
        content = file.read_text(encoding="utf-8")
        methods = re.findall(r"\bfunc\s+(test\w*)\s*\(", content)
        if not methods:
            continue
        classes = re.findall(r"\bclass\s+(\w+)\s*:\s*XCTestCase\b", content)
        if len(classes) != 1 or len(methods) != len(set(methods)) or classes[0] in result:
            raise ValueError(f"Ambiguous XCTest method inventory: {file.name}")
        result[classes[0]] = set(methods)
    if not result:
        raise ValueError(f"No XCTest methods discovered in {directory}")
    return result


def execution_report(shard, path):
    """Start failed so interrupted discovery or log reads cannot imply a pass."""
    return {
        "schema": 1, "shard": shard, "log": str(path), "target": None,
        "status": "failed", "expected": [], "started": [], "passed": [],
        "failed": [], "skipped": [], "unstarted": [], "invalid": [],
    }


def write_report(report, path):
    if path is not None:
        destination = Path(path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def verify_log(shard, path, report_path=None):
    """Require every selected method to start and pass exactly once.

    A successful xcodebuild exit alone cannot prove a complete selected suite.
    Missing, skipped, failed, duplicate and unexpected events all fail closed.
    Report lists describe selected methods; foreign or unrecognized events are
    retained in ``invalid``. ``passed`` requires the complete ordered sequence,
    and only ``status`` indicates whether the entire execution is verified.
    """
    report = execution_report(shard, path)
    try:
        suites = {**SHARDS, **DIAGNOSTIC_SHARDS}
        if shard == "unit":
            target = "KeyAndFillTests"
            inventory = discover_methods("NativeTests")
            selected = tuple(inventory)
        elif shard in suites:
            target = "KeyAndFillUITests"
            inventory = discover_methods("UITests")
            selected = suites[shard]
        else:
            raise ValueError(f"Unknown native test shard: {shard}")
        expected = {f"{name}.{method}" for name in selected for method in inventory.get(name, ())}
        report.update(target=target, expected=sorted(expected), unstarted=sorted(expected))
        if not expected or any(not inventory.get(name) for name in selected):
            raise ValueError(f"Selected XCTest suite has no methods: {shard}")

        events = {key: [] for key in expected}
        content = Path(path).read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(content.splitlines(), 1):
            marker = TEST_CASE_MARKER.search(line)
            if marker is None:
                continue
            match = TEST_CASE_EVENT.fullmatch(line[marker.start():])
            if match is None:
                report["invalid"].append({
                    "line": number, "text": line, "reason": "Unrecognized Test Case line",
                })
                continue
            name = f"{match['class']}.{match['method']}"
            observed = {"line": number, "target": match["target"],
                        "method": name, "event": match["event"]}
            if match["target"] != target:
                report["invalid"].append({**observed, "reason": "Unexpected XCTest target"})
            elif name not in expected:
                report["invalid"].append({**observed, "reason": "Unexpected XCTest method"})
            else:
                events[name].append({"line": number, "event": match["event"]})

        for name in sorted(expected):
            sequence = [item["event"] for item in events[name]]
            for event in ("started", "failed", "skipped"):
                if event in sequence:
                    report[event].append(name)
            if sequence == ["started", "passed"]:
                report["passed"].append(name)
            else:
                report["invalid"].append({
                    "target": target, "method": name, "events": events[name],
                    "reason": "Expected exactly one ordered started -> passed sequence",
                })
        report["unstarted"] = sorted(expected - set(report["started"]))
        if report["invalid"]:
            raise ValueError("Incomplete XCTest execution: " + json.dumps(report["invalid"], sort_keys=True))
        report["status"] = "passed"
    except (OSError, ValueError) as exc:
        if not report["invalid"]:
            report["invalid"].append({"reason": str(exc)})
        raise
    finally:
        write_report(report, report_path)
    print(f"Verified {len(expected)} {shard} methods: one start and one pass each; no failures, skips, duplicates or omissions.")
    return expected


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "verify-log":
        parser = argparse.ArgumentParser(prog=f"{sys.argv[0]} verify-log")
        parser.add_argument("shard")
        parser.add_argument("log")
        parser.add_argument("--report", metavar="JSON", help="write execution accounting even when verification fails")
        args = parser.parse_args(sys.argv[2:])
        try:
            check()
        except (OSError, ValueError) as exc:
            report = execution_report(args.shard, args.log)
            report["invalid"].append({"reason": str(exc)})
            write_report(report, args.report)
            raise
        verify_log(args.shard, args.log, args.report)
        return
    if len(sys.argv) != 2:
        raise ValueError("Usage: native_test_shards.py check|unit|<shard>|verify-log <shard> <log> [--report <json>]")
    command = sys.argv[1]
    expected = check()
    if command == "check":
        print(f"All {len(expected)} UI test classes assigned once across {len(SHARDS)} required and {len(DIAGNOSTIC_SHARDS)} opt-in diagnostic shards; native unit target is separate.")
    elif command == "unit":
        print("-only-testing:KeyAndFillTests")
    elif command in {**SHARDS, **DIAGNOSTIC_SHARDS}:
        for name in {**SHARDS, **DIAGNOSTIC_SHARDS}[command]:
            print(f"-only-testing:KeyAndFillUITests/{name}")
    else:
        raise ValueError(f"Unknown native test shard: {command}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as exc:
        print(exc, file=sys.stderr)
        raise SystemExit(1)
