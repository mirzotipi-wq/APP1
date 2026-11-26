#!/usr/bin/env python3
"""One independent rolled, grazing rectangle reference; fixed Simpson budget.

This uses analytic slice limits and world-space Lambertian cosine factors.
It does not import production geometry, clipping, quadrature, or Swift results.
The expected lux is computed before the actual Swift probe is generated.
"""
import json
import math
from pathlib import Path

OUT = Path(__file__).resolve().parent
CENTER = (-0.8, 1.1, 0.4)
ROLL_DEGREES = -63.0
WIDTH, HEIGHT, CANDELA = 1.6, 0.9, 1375.0
A, B, DEPTH = 0.18, -0.11, 0.405
SLOPE, CUTOFF = 0.55, 0.72
angle = math.radians(ROLL_DEGREES)
right = (math.cos(angle), math.sin(angle), 0.0)
up = (-math.sin(angle), math.cos(angle), 0.0)
receiver = tuple(CENTER[k] + A * right[k] + B * up[k]
                 + (DEPTH if k == 2 else 0.0) for k in range(3))
local_nz = (CUTOFF - A + SLOPE * B) / DEPTH
normal_raw = tuple(right[k] - SLOPE * up[k]
                   + (local_nz if k == 2 else 0.0) for k in range(3))
normal_length = math.hypot(*normal_raw)
normal = tuple(component / normal_length for component in normal_raw)

# Positive incidence is x - 0.55*y > 0.72 in local meters. The entire
# contributing domain is a triangle at the right/lower corner of the face.
y_low = -HEIGHT / 2
y_high = (WIDTH / 2 - CUTOFF) / SLOPE
assert -HEIGHT / 2 < y_high < HEIGHT / 2
assert -WIDTH / 2 < CUTOFF + SLOPE * y_low < WIDTH / 2
lit_area = 0.5 * (WIDTH / 2 - CUTOFF - SLOPE * y_low) * (y_high - y_low)


def simpson(function, low, high, intervals):
    assert intervals > 0 and intervals % 2 == 0
    step = (high - low) / intervals
    terms = [function(low), function(high)]
    terms.extend((4.0 if i % 2 else 2.0) * function(low + i * step)
                 for i in range(1, intervals))
    return math.fsum(terms) * step / 3.0


def direct_integrand(x, y):
    source = tuple(CENTER[k] + x * right[k] + y * up[k] for k in range(3))
    delta = tuple(receiver[k] - source[k] for k in range(3))
    distance_squared = math.fsum(component * component for component in delta)
    distance = math.sqrt(distance_squared)
    cosine_emitter = max(0.0, delta[2] / distance)
    cosine_receiver = max(0.0, -math.fsum(delta[k] * normal[k] for k in range(3)) / distance)
    return cosine_emitter * cosine_receiver / distance_squared


def integrate(intervals):
    def slice_integral(y):
        return simpson(lambda x: direct_integrand(x, y),
                       CUTOFF + SLOPE * y, WIDTH / 2, intervals)
    return CANDELA / (WIDTH * HEIGHT) * simpson(slice_integral, y_low, y_high, intervals)


rows = []
for count in (32, 64, 128, 256, 512):
    lux = integrate(count)
    row = {"intervals_per_dimension": count,
           "integrand_evaluations": (count + 1) ** 2,
           "reference_lux": lux}
    if rows:
        row["relative_change_from_previous"] = abs(lux - rows[-1]["reference_lux"]) / lux
    rows.append(row)

reference = rows[-1]["reference_lux"]
result = {
    "fixture": "minus63_roll_triangular_grazing_corner",
    "method": "nested composite Simpson on analytic y slices, direct world-space cosine factors",
    "formula": "E = (onAxisCandela / area) * integral(cosEmitter * max(0, cosReceiver) / distance^2 dA)",
    "expected_value_independence": "No production clipping, triangle mapping, Gaussian nodes/weights, or normal helper",
    "roll_degrees": ROLL_DEGREES,
    "center_m": CENTER,
    "aim_target_m": (CENTER[0], CENTER[1], CENTER[2] + 2.0),
    "width_m": WIDTH,
    "height_m": HEIGHT,
    "candela": CANDELA,
    "receiver_local_m": (A, B, DEPTH),
    "receiver_world_m": receiver,
    "receiver_normal_raw_world": normal_raw,
    "receiver_normal_unit_world": normal,
    "minimum_plane_separation_m": max(0.05, max(WIDTH, HEIGHT) / 4),
    "plane_separation_m": DEPTH,
    "positive_incidence_domain": "x - 0.55*y > 0.72; y in [-0.45, (0.8-0.72)/0.55], x in [0.72+0.55*y, 0.8]",
    "contributing_area_m2": lit_area,
    "contributing_face_fraction": lit_area / (WIDTH * HEIGHT),
    "refinement": rows,
    "total_integrand_evaluations": sum(row["integrand_evaluations"] for row in rows),
    "finest_reference_lux": reference,
    "last_refinement_relative_change": rows[-1]["relative_change_from_previous"],
    "area_relative_error_gate_unchanged": 0.05,
    "point_relative_error_gate_unchanged_not_exercised": 0.01,
}
(OUT / "reference.json").write_text(json.dumps(result, indent=2) + "\n")


def swift_position(p):
    return ".init(x: %.17g, y: %.17g, z: %.17g)" % tuple(p)


probe = f'''import Foundation
import LightingCore

let center: Position = {swift_position(CENTER)}
let receiver: Position = {swift_position(receiver)}
guard let frame = EmitterFrame(source: center,
    target: {swift_position((CENTER[0], CENTER[1], CENTER[2] + 2.0))},
    rollDegrees: {ROLL_DEGREES:.17g}),
    let emitter = LambertianRectangle(center: center, right: frame.right, up: frame.up,
        widthMeters: {WIDTH:.17g}, heightMeters: {HEIGHT:.17g}, onAxisCandela: {CANDELA:.17g}),
    let normal = UnitDirection(x: {normal_raw[0]:.17g}, y: {normal_raw[1]:.17g}, z: {normal_raw[2]:.17g}),
    let actual = Photometry.rectangularIlluminance(emitter: emitter,
        receiver: receiver, receiverNormal: normal)
else {{ fatalError("Fixture must be supported") }}
let expected = {reference:.17g}
let relativeError = abs(actual - expected) / expected
let output: [String: Any] = [
    "fixture": "minus63_roll_triangular_grazing_corner",
    "execution": "actual frozen LightingCore v1 Swift standalone probe",
    "actual_lux": actual,
    "independent_reference_lux": expected,
    "absolute_error_lux": abs(actual - expected),
    "relative_error": relativeError,
    "relative_error_percent": relativeError * 100,
    "area_gate_unchanged": 0.05,
    "passes_area_gate": actual.isFinite && relativeError <= 0.05,
    "frame_right": [frame.right.x, frame.right.y, frame.right.z],
    "frame_up": [frame.up.x, frame.up.y, frame.up.z]
]
let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys, .prettyPrinted])
print(String(decoding: data, as: UTF8.self))
precondition(actual.isFinite && relativeError <= 0.05, "Unchanged 5% area-model gate")
'''
(OUT / "probe.swift").write_text(probe)
print(json.dumps(result, indent=2))
