#!/usr/bin/env python3
"""Private arithmetic probe; no shipped Swift, shared C++, or Metal execution."""
import json
import math
from pathlib import Path

ROOT = Path('/tmp/keyfill04-2987b1ee980d/results/w012')
RUN = 'w012-silhouette-analytic-001'
EPS = 2.0 ** -23  # Float.ulpOfOne, twice the usual round-to-nearest unit roundoff.
R = 0.22

def ray_distance(width, focal, distance, x, y):
    height = width * 2 // 3
    px = (2.0 * (x + 0.5) / width - 1.0) * (18.0 / focal)
    py = (1.0 - 2.0 * (y + 0.5) / height) * (12.0 / focal)
    q = px * px + py * py
    rho2 = distance * distance * q / (1.0 + q)
    return math.sqrt(rho2), q

def all_min(width, focal, distance):
    result = (math.inf, None)
    for y in range(width * 2 // 3):
        for x in range(width):
            rho, q = ray_distance(width, focal, distance, x, y)
            result = min(result, (abs(rho - R), (x, y, q)))
    return result

def row_min(width, focal, distance):
    height = width * 2 // 3
    a = 18.0 / focal
    qstar = R * R / (distance * distance - R * R)
    result = (math.inf, None)
    for y in range(height):
        py = (1.0 - 2.0 * (y + 0.5) / height) * (12.0 / focal)
        x_target = (width * (1.0 + math.sqrt(max(0.0, qstar - py * py)) / a) - 1.0) / 2.0
        # Two mathematical neighbors, plus one on each side for Double index rounding.
        base = math.floor(x_target)
        for dx in (-1, 0, 1, 2):
            x = min(width - 1, max(width // 2, base + dx))
            rho, q = ray_distance(width, focal, distance, x, y)
            result = min(result, (abs(rho - R), (x, y, q)))
    return result

cases = [
    ('confirmed', 3.0, 161.27198111190464),
    ('portrait', 3.0, 50.0),
    ('hard-soft-dark-near-translated', math.hypot(2.3, 0.16), 85.0),
    ('warm-rotated', math.sqrt(0.8**2 + 0.3**2 + 2.3**2), 85.0),
    ('twenty-meter-eligibility', 20.0, 85.0),
    ('wide-eligibility', math.hypot(2.3, 0.16), 14.0),
    ('precision19-85', 19.0, 85.0),
    ('precision19-200', 19.0, 200.0),
    ('precision19.999999-85', 19.999999, 85.0),
    ('precision19.999999-200', 19.999999, 200.0),
    ('precision20-85', 20.0, 85.0),
    ('precision20-200', 20.0, 200.0),
    ('distant-light-camera', math.sqrt(0.8**2 + 0.2**2 + 2.3**2), 85.0),
]
records = []
maximum_row_min_error = 0
for name, distance, focal in cases:
    for width in (24, 48, 120, 192):
        exhaustive = all_min(width, focal, distance)
        bounded = row_min(width, focal, distance)
        error = abs(exhaustive[0] - bounded[0])
        maximum_row_min_error = max(maximum_row_min_error, error)
        assert error < 2e-14, (name, width, exhaustive, bounded)
        records.append(dict(name=name, width=width, height=width*2//3,
            distance=distance, focal=focal, minimum_clearance_m=exhaustive[0],
            nearest_pixel=exhaustive[1][:2], closest_q=exhaustive[1][2],
            guard_32=exhaustive[0] > 32*EPS*distance,
            guard_64=exhaustive[0] > 64*EPS*distance,
            margin_32_m=32*EPS*distance, margin_64_m=64*EPS*distance))
# Resolution coverage for common cameras and the confirmed counterexample.
width_summaries = []
for name, distance, focal in cases[:6]:
    rejected = []
    for width in range(24, 193, 3):
        clearance = row_min(width, focal, distance)[0]
        if clearance <= 64*EPS*distance:
            rejected.append(width)
    width_summaries.append(dict(name=name, rejected_widths_64=rejected, widths_checked=57))
result = dict(run_id=RUN, execution='Python analytic Double geometry only',
    source_revision='3d0e20616d0e771ad72161592c59105f591951c9',
    float_epsilon=EPS, records=records, width_summaries=width_summaries,
    maximum_row_min_error_m=maximum_row_min_error)
(ROOT / 'silhouette_guard_probe.json').write_text(json.dumps(result, indent=2) + '\n')
for item in records:
    if item['name'] in ('confirmed', 'portrait', 'hard-soft-dark-near-translated', 'warm-rotated') or item['width'] == 192:
        print(item['name'], item['width'], f"clearance={item['minimum_clearance_m']:.12g}",
              f"margin64={item['margin_64_m']:.12g}", f"pass64={item['guard_64']}", item['nearest_pixel'])
print('WIDTH_SUMMARIES', width_summaries)
print('maximum row min discrepancy m', maximum_row_min_error)
print('RUN', RUN)
