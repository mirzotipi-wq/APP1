"""Python binary64 transcriptions, not execution of Swift or a renderer.
Corresponds to SurfacePhotometry.swift:179-197 and Scene.swift:95-99.
The ordinary-source reference postpones intensity scaling to test cancellation
of per-cell underflow independently of the finite-area integration accuracy.
"""
import json
import math
from pathlib import Path


def midpoint(candela, width, height, depth):
    count = 32
    per_cell = candela / (count * count)
    total = 0.0
    for j in range(count):
        y = ((j + 0.5) / count - 0.5) * height
        for i in range(count):
            x = ((i + 0.5) / count - 0.5) * width
            r2 = x * x + y * y + depth * depth
            cosine = depth / math.sqrt(r2)
            total += per_cell * cosine * cosine / r2
    return total


def analytic_unit(width, height, depth):
    a, b = width / 2, height / 2
    da, db = math.hypot(depth, a), math.hypot(depth, b)
    return 2 / (width * height) * (a / da * math.atan(b / da) + b / db * math.atan(a / db))


width = height = depth = 0.05
unit_grid = midpoint(1.0, width, height, depth)
unit_analytic = analytic_unit(width, height, depth)
rows = []
for candela in [1000.0, 1e-300, 1e-317, 1e-320, 1e-321, math.ulp(0.0)]:
    raw = midpoint(candela, width, height, depth)
    scaled = unit_grid * candela
    expected = unit_analytic * candela
    rows.append({
        'candela': candela, 'candela_per_cell': candela / 1024,
        'swift_order_transcription_lux': raw,
        'unit_grid_scaled_last_lux': scaled, 'analytic_scaled_last_lux': expected,
        'relative_error_to_analytic': abs(raw / expected - 1) if expected else None,
    })

# Distinct adjacent public API issue, unreachable through bounded Position values.
far_distance = 1e160
far_candela = 100000.0
far_current = far_candela / (far_distance * far_distance)
far_stable = (far_candela / far_distance) / far_distance
result = {
    'evidence_kind': 'Python 3 binary64 numerical transcription; no Swift was run',
    'source_geometry': {'width_meters': width, 'height_meters': height, 'depth_meters': depth},
    'unit_grid_lux': unit_grid, 'unit_analytic_lux': unit_analytic,
    'ordinary_grid_relative_error': abs(unit_grid / unit_analytic - 1),
    'cases': rows,
    'adjacent_normal_illuminance_overflow': {
        'candela': far_candela, 'distance_meters': far_distance,
        'swift_order_transcription_lux': far_current, 'stable_order_lux': far_stable,
        'scene_reachable': False,
    },
}
assert unit_grid > 0 and abs(unit_grid / unit_analytic - 1) < .01
assert rows[-2]['swift_order_transcription_lux'] == 0
assert rows[-2]['analytic_scaled_last_lux'] > 0
assert far_current == 0 and far_stable > 0
out = Path(__file__).with_name('probe-results.json')
out.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))

# RelativeXYZ accepts these finite coordinates; chromaticity should be invariant
# under a shared positive scale. The existing sum overflows before normalization.
large_xyz = (1e308, 1e308, 1e308)
large_sum = sum(large_xyz)
scale = max(large_xyz)
rescaled = tuple(v / scale for v in large_xyz)
rescaled_sum = sum(rescaled)
result['relative_xyz_chromaticity'] = {
    'xyz': large_xyz, 'components_all_finite': all(map(math.isfinite, large_xyz)),
    'unscaled_sum_finite': math.isfinite(large_sum),
    'swift_order_result': None,
    'max_scaled_result': {'x': rescaled[0] / rescaled_sum, 'y': rescaled[1] / rescaled_sum},
    'ordinary_xyz': [1.0, 1.0, 1.0],
    'ordinary_result': {'x': 1 / 3, 'y': 1 / 3},
    'scene_reachable': False,
}

# Also verify UnitDirection's max-component normalization at the opposite extreme.
tiny = math.ulp(0.0)
for values in [(tiny, tiny, tiny), (1e308, 1e308, 0.0)]:
    scale = max(map(abs, values))
    a = tuple(v / scale for v in values)
    length = math.sqrt(sum(v * v for v in a))
    unit = tuple(v / length for v in a)
    assert all(map(math.isfinite, unit))
    assert abs(sum(v * v for v in unit) - 1) < 1e-15


def bradford(v):
    x, y, z = v
    return (.8951*x + .2664*y - .1614*z,
            -.7502*x + 1.7135*y + .0367*z,
            .0389*x - .0685*y + 1.0296*z)


def inverse_bradford(v):
    x, y, z = v
    return (.9869929*x - .1470543*y + .1599627*z,
            .4323053*x + .5183603*y + .0492912*z,
            -.0085287*x + .0400428*y + .9684867*z)


def blackbody(kelvin):
    total = [0., 0., 0.]
    for nm in range(380, 781, 5):
        def lobe(center, left, right):
            t = (nm - center) * (left if nm < center else right)
            return math.exp(-.5 * t * t)
        matching = (max(0, 1.056*lobe(599.8,.0264,.0323) + .362*lobe(442,.0624,.0374) - .065*lobe(501.1,.049,.0382)),
                    .821*lobe(568.8,.0213,.0247) + .286*lobe(530.9,.0613,.0322),
                    1.217*lobe(437,.0845,.0278) + .681*lobe(459,.0385,.0725))
        spectrum = (560 / nm) ** 5 / math.expm1(1.438776877e7 / (nm * kelvin))
        weight = .5 if nm in (380, 780) else 1.
        for i in range(3):
            total[i] += matching[i] * (spectrum * weight)
    return tuple(v / total[1] for v in total)


source = bradford(blackbody(5600))
destination = bradford((.3127/.3290, 1., (1-.3127-.3290)/.3290))
ratio = tuple(a/b for a, b in zip(destination, source))
cones = bradford(large_xyz)
adapted = inverse_bradford(tuple(v*r for v,r in zip(cones, ratio)))
x, y, z = adapted
rgb = (3.24096994*x - 1.53738318*y - .49861076*z,
       -.96924364*x + 1.87596750*y + .04155506*z,
       .05563008*x - .20397696*y + 1.05697151*z)
result['large_display_fail_closed'] = {
    'xyz': large_xyz, 'white_balance_kelvin': 5600, 'exposure_stops': 0,
    'adapted_components_all_finite': all(map(math.isfinite, adapted)),
    'rgb_components_all_finite': all(map(math.isfinite, rgb)),
    'swift_order_result': None,
    'note': 'display() returns nil through its nonfinite RGB guard; no fabricated black/color value',
}
assert not math.isfinite(large_sum)
assert not all(map(math.isfinite, rgb))
out.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({k: result[k] for k in ('relative_xyz_chromaticity', 'large_display_fail_closed')}, indent=2))
