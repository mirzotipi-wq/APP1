#!/usr/bin/env python3
"""Independent Python stdlib scalar check, not Swift or RealityKit execution."""
import json
import math
import struct
from pathlib import Path

SOURCE = "4e694bc377c4825d1d2dd52fcd7900e534c75072"
PATCH = "8fdf2042441591771b1a19b109a2e600758f461bdfb5f33599079991ea77dcbe"

def f32(value):
    return struct.unpack(">f", struct.pack(">f", value))[0]

def next_up(value):
    bits = struct.unpack(">I", struct.pack(">f", value))[0]
    return struct.unpack(">f", struct.pack(">I", bits + 1))[0]

def checks(accepted, ideal, width, height):
    if accepted is None:
        return {"accepted": False}
    uploaded = f32(accepted)
    return {
        "roundtrips_float": accepted == float(uploaded),
        "encloses_ideal": accepted >= ideal,
        "bounded_step": uploaded <= next_up(f32(ideal)),
        "smaller_axis_at_least_24_degrees": math.tan(uploaded * math.pi / 360) * min(1, width / height) >= math.tan(24 * math.pi / 180) - 1e-12,
    }

rows = []
for width, height in [(360., 240.), (120., 600.), (600., 120.), (1., 1000.), (.0003, 3000.), (.0002, 3000.), (.0001, 3000.), (.00001, 1000.)]:
    ideal = 48. if width >= height else 2 * math.atan(math.tan(48 * math.pi / 360) * (height / width)) * 180 / math.pi
    nearest = f32(ideal)
    enclosing = next_up(nearest) if nearest < ideal else nearest
    old = ideal if nearest < 180 else None
    candidate = enclosing if enclosing < 180 else None
    row = {
        "width": width, "height": height, "ideal": ideal,
        "nearest_float": nearest, "enclosing_float": enclosing,
        "old_accepts": old is not None, "candidate_accepts": candidate is not None,
        "old_smaller_axis_half_degrees": math.degrees(math.atan(math.tan(nearest * math.pi / 360) * min(1, width / height))) if old is not None else None,
        "candidate_smaller_axis_half_degrees": math.degrees(math.atan(math.tan(enclosing * math.pi / 360) * min(1, width / height))) if candidate is not None else None,
        "old_assertions": checks(old, ideal, width, height),
        "candidate_assertions": checks(candidate, ideal, width, height),
    }
    if width in (.0001, .00001):
        assert candidate is None
    else:
        assert candidate is not None and all(row["candidate_assertions"].values())
    rows.append(row)
assert rows[4]["old_assertions"]["smaller_axis_at_least_24_degrees"] is False
assert rows[6]["old_accepts"] is True
result = {
    "reviewer": "/root/w08_acceptance/independent_review",
    "source_sha": SOURCE, "candidate_patch_sha256": PATCH,
    "method": "Independent Python standard-library IEEE binary32 degree conversion and Double pinhole arithmetic",
    "native_execution": False,
    "rows": rows,
    "candidate_scalar_assertions_pass": True,
    "old_source_discriminated": True,
    "limits": "No Swift compilation, XCTest run, native camera matrix, RealityKit, rendering, delivered gestures, timing or device-performance claim."
}
out = Path(__file__).with_name("scalar_projection_check.json")
out.write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
