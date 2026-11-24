#!/usr/bin/env python3
"""Class-level XCTest partition. Fail closed if a test class is unassigned."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHARDS = {
    "room-precision": ("ManualRoomPlacementUITests", "PrecisionEditingUITests"),
    "library-reference": ("ProjectLibraryUITests", "ReferenceComparisonUITests", "AccessibilityAuditUITests"),
    "studio-export": ("StudioSmokeTests", "LightingPlanExportUITests"),
}


def discover_ui_classes():
    result = set()
    # XcodeGen includes source-directory descendants; the coverage check must
    # discover the same nested Swift files before allowing shard selection.
    for file in (ROOT / "UITests").rglob("*.swift"):
        content = file.read_text(encoding="utf-8")
        classes = re.findall(r"\bclass\s+(\w+)\s*:\s*XCTestCase\b", content)
        if re.search(r"\bfunc\s+test\w+\s*\(", content) and not classes:
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
    assigned = [name for names in SHARDS.values() for name in names]
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
    return expected


def main():
    if len(sys.argv) != 2:
        raise ValueError("Usage: native_test_shards.py check|unit|<shard>")
    command = sys.argv[1]
    expected = check()
    if command == "check":
        print(f"All {len(expected)} UI test classes assigned once across {len(SHARDS)} shards; native unit target is separate.")
    elif command == "unit":
        print("-only-testing:KeyAndFillTests")
    elif command in SHARDS:
        for name in SHARDS[command]:
            print(f"-only-testing:KeyAndFillUITests/{name}")
    else:
        raise ValueError(f"Unknown native test shard: {command}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as exc:
        print(exc, file=sys.stderr)
        raise SystemExit(1)
