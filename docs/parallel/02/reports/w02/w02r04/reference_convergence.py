"""Refine only the held-over W01R04 rolled partial-face reference.

Direct world-space cosine integral on analytic y slices. No production Swift,
clipping algorithm, triangle map, or production quadrature is used here.
"""
import hashlib
import json
import math
from pathlib import Path

source = Path('/tmp/keyfill02/docs/parallel/02/reports/w01/w01r04/roll_area_probe.json')
saved = json.loads(source.read_text())
fixture = saved['input']


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def unit(a):
    length = math.sqrt(dot(a, a))
    return tuple(x / length for x in a)


center = fixture['center']
normal = unit(tuple(t - c for t, c in zip(fixture['target'], center)))
zero_right = unit((normal[2], 0, -normal[0]))
angle = math.radians(fixture['roll'])
# Rodrigues rotation is independently expressed from the production frame API.
turn = cross(normal, zero_right)
right = tuple(z * math.cos(angle) + t * math.sin(angle)
              + n * dot(normal, zero_right) * (1 - math.cos(angle))
              for z, t, n in zip(zero_right, turn, normal))
up = cross(normal, right)
receiver = fixture['receiver']
receiver_normal = unit(fixture['receiverNormal'])
width, height = fixture['width'], fixture['height']


def integrate(count):
    def weight(i):
        return 1 if i in (0, count) else (4 if i % 2 else 2)

    dy = height / count
    total = 0.0
    for j in range(count + 1):
        y = -height / 2 + j * dy
        # For this one fixture, positive receiver incidence is x + .35y > .216.
        xmin = 0.216 - 0.35 * y
        dx = (width / 2 - xmin) / count
        row = 0.0
        for i in range(count + 1):
            x = xmin + i * dx
            point = tuple(c + r * x + u * y for c, r, u in zip(center, right, up))
            ray = tuple(p - q for p, q in zip(receiver, point))
            distance_squared = dot(ray, ray)
            direction = tuple(v / math.sqrt(distance_squared) for v in ray)
            emitter_cosine = max(0.0, dot(normal, direction))
            receiver_cosine = max(0.0, -dot(receiver_normal, direction))
            row += weight(i) * emitter_cosine * receiver_cosine / distance_squared
        total += weight(j) * row * dx / 3
    return fixture['onAxisCandela'] / (width * height) * total * dy / 3


rows = [{'intervals_per_axis': n, 'lux': integrate(n)} for n in (80, 160, 320)]
expected = saved['independent_simpson_lux']
print(json.dumps({
    'fixture_source': str(source),
    'fixture_source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'method': 'Composite Simpson, direct world-space cosines, analytic y slices',
    'stored_reference_lux': expected,
    'rows': rows,
    'relative_refinement_delta_160_to_320': abs(rows[1]['lux'] - rows[2]['lux']) / rows[2]['lux'],
    'stored_reference_relative_delta_to_320': abs(expected - rows[2]['lux']) / rows[2]['lux'],
    'focused_fixture_relative_tolerance': 1e-6,
    'unchanged_area_contract_relative_tolerance': 0.05,
}, indent=2))
