"""Math-only witness; imports no app/native framework and runs no app test."""
import json
import math
import struct
from pathlib import Path

def float32(value):
    return struct.unpack("f", struct.pack("f", value))[0]

def fov_sample(width, height):
    if not all(map(math.isfinite, (width, height))) or width <= 0 or height <= 0:
        return {"width": width, "height": height, "accepted": False}
    value = 48 if width >= height else math.degrees(2 * math.atan(math.tan(math.radians(24)) * height / width))
    native = float32(value)
    return {"width": width, "height": height, "double_degrees": value,
            "float32_degrees": native, "accepted": math.isfinite(native) and native < 180}

# A hypothetical equipment sphere of radius 1 m, not an executed app fixture.
radius = 1.0
fitted = max(0.8, radius) / math.sin(math.radians(24)) * 1.12
near = 0.02
far = fitted + 750
backward = 1000.0
depth = fitted + backward
normalized_depth = far / (far - near) - (far * near) / ((far - near) * depth)
result = {
    "kind": "independent Python arithmetic; NOT Swift, SceneKit, RealityKit, device, or performance execution",
    "conditional_premise": "the active controlled camera retains fitted zFar and manual clipping while moving backward",
    "radius_meters": radius,
    "fitted_distance_meters": fitted,
    "fixed_far_meters": far,
    "backward_translation_meters": backward,
    "center_depth_meters": depth,
    "center_beyond_far_meters": depth - far,
    "nearest_sphere_depth_meters": depth - radius,
    "normalized_depth_0_to_1_convention": normalized_depth,
    "normalized_depth_float32": float32(normalized_depth),
    "fov_samples": [fov_sample(*size) for size in [(0, 240), (360, 280), (120, 600), (1, 1000), (0.00001, 1000)]],
}
assert depth - far == 250
assert depth - radius > far
assert normalized_depth > 1 and float32(normalized_depth) > 1
assert [sample["accepted"] for sample in result["fov_samples"]] == [False, True, True, True, False]
Path(__file__).with_name("witness.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
