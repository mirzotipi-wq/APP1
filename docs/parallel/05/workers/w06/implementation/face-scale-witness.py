"""Source-bound scalar witness; does not execute Swift or RealityKit."""

from decimal import Decimal, getcontext
import hashlib
import json
from pathlib import Path
import subprocess
import sys

getcontext().prec = 30
BASE = "bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9"
RELATIVE = "App/StudioEntityGraph.swift"
repo = Path(sys.argv[1])
before = subprocess.check_output(["git", "show", f"{BASE}:{RELATIVE}"], cwd=repo)
after = (repo / RELATIVE).read_bytes()
old = b"            face.scale = [max(0.01, width - 0.012), max(0.01, height - 0.012), 0.006]\n"
new = (
    b"            // Rectangle dimensions describe the full emitting area.\n"
    b"            face.scale = optics.kind == .rectangle ? [width, height, 0.006] :\n"
    b"                [max(0.01, width - 0.012), max(0.01, height - 0.012), 0.006]\n"
)
assert before.count(old) == 1
assert after == before.replace(old, new), "Unexpected production change"

cases = []
for kind, width_text, height_text in [
    ("rectangle", "1.2", "0.7"),
    ("rectangle", "0.05", "0.05"),
    ("directional", "0.22", "0.18"),
]:
    width, height = Decimal(width_text), Decimal(height_text)
    before_width = max(Decimal("0.01"), width - Decimal("0.012"))
    before_height = max(Decimal("0.01"), height - Decimal("0.012"))
    after_width, after_height = (width, height) if kind == "rectangle" else (before_width, before_height)
    before_area = before_width * before_height
    after_area = after_width * after_height
    case = {
        "kind": kind,
        "input_dimensions_m": [str(width), str(height)],
        "before_face_dimensions_m": [str(before_width), str(before_height)],
        "after_face_dimensions_m": [str(after_width), str(after_height)],
        "before_face_area_m2": str(before_area),
        "after_face_area_m2": str(after_area),
    }
    if kind == "rectangle":
        authored_area = width * height
        case["before_authored_area_shortfall_percent"] = str((1 - before_area / authored_area) * 100)
        case["after_authored_area_shortfall_percent"] = str((1 - after_area / authored_area) * 100)
        assert after_area == authored_area
    else:
        case["inset_unchanged"] = after_width == before_width and after_height == before_height
        assert case["inset_unchanged"]
    cases.append(case)

front = Decimal("-0.003") + Decimal("0.006") / 2
assert front == 0
result = {
    "evidence_type": "Exact decimal arithmetic transcribed from the inspected scalar expressions; not native execution or Float32 runtime output",
    "worker": "/root/w06_acceptance/implementation",
    "base_revision": BASE,
    "source_path": RELATIVE,
    "before_source_sha256": hashlib.sha256(before).hexdigest(),
    "after_source_sha256": hashlib.sha256(after).hexdigest(),
    "scope_check": "PASS: only the rectangle face.scale branch and its explanatory comment changed",
    "unit_box_size_m": "1",
    "cases": cases,
    "unchanged_face_depth_m": "0.006",
    "unchanged_face_center_z_m": "-0.003",
    "unchanged_front_plane_z_m": str(front),
    "native_execution": "UNRUN",
}
output = Path(__file__).with_suffix(".json")
output.write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
