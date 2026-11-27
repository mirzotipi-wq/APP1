"""Independent scalar math witness; does not execute Swift or native adapters."""
import hashlib
import itertools
import json
import math
from pathlib import Path
import struct
import subprocess
import sys

OUT = Path('/tmp/keyfill05-be879deb/waves/w04/geometry')
REPO = '/tmp/keyfill05-be879deb/repo'
PIN = '956a3b1d70cb3d67ba136821d9828be80aee1c3b'
FILES = [
    'AGENTS.md', 'docs/ARCHITECTURE.md', 'docs/DESIGN.md',
    'docs/acceptance/m02-m03-code.md', 'App/SpatialViewportGeometry.swift',
    'App/StudioEntityGraph.swift', 'App/RealityStudioPreview.swift',
    'App/SpatialPreview.swift', 'Sources/LightingCore/Scene.swift',
    'Sources/LightingCore/StudioOptics.swift', 'Sources/LightingCore/StudioSceneBounds.swift',
    'NativeTests/SpatialViewportStateTests.swift', 'NativeTests/SpatialInteractionTests.swift',
]
sources = {}
commands = []
reviewed_only = '--reviewed-only' in sys.argv
for path in FILES:
    args = ['git', '-C', REPO, 'show', PIN + ':' + path]
    commands.append(' '.join(args))
    if not reviewed_only:
        sources[path] = subprocess.check_output(args)
if not reviewed_only:
    g = sources['App/SpatialViewportGeometry.swift'].decode()
    for required in ['0.45...1_500', 'max(0.8, bounds.radiusMeters) / sin(24 * .pi / 180) * 1.12',
                     'distance + 750', 'to: -300...300', '[-0.15, 0.08]', '/ 2 + 0.03']:
        assert required in g, required
    assert 'near: 0.02' in sources['App/RealityStudioPreview.swift'].decode()
    assert '-100...100' in sources['Sources/LightingCore/Scene.swift'].decode()
    assert '0.05...4' in sources['Sources/LightingCore/StudioOptics.swift'].decode()

def norm(v):
    return math.sqrt(sum(x*x for x in v))

def dot(a, b):
    return sum(x*y for x, y in zip(a, b))

def sub(a, b):
    return tuple(x-y for x, y in zip(a, b))

def add(a, b):
    return tuple(x+y for x, y in zip(a, b))

def unit(v):
    return tuple(x/norm(v) for x in v)

def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])

def f32(x):
    return struct.unpack('f', struct.pack('f', x))[0]

def bounds(points):
    return tuple(min(p[i] for p in points) for i in range(3)), tuple(max(p[i] for p in points) for i in range(3))

def box(center, low, high):
    return [add(center, p) for p in itertools.product(*zip(low, high))]

def coincident_four_meter(center):
    points = box(center, (-.36, -.96, -.36), (.36, .24, .36))
    points += box(center, (-.24, -.24, -.24), (.24, .24, .24))
    points += box(center, (-2.03, -2.03, -.15), (2.03, 2.03, .08))
    if center[1] > .05:
        points += box((center[0], .014, center[2]), (-.24, -.014, -.24), (.24, .014, .24))
    return bounds(points)

def check_fit(name, low, high):
    center = tuple((a+b)/2 for a, b in zip(low, high))
    radius = norm(sub(high, low))/2
    distance = min(1500, max(.45, max(.8, radius)/math.sin(math.radians(24))*1.12))
    yaw, pitch = .56, .36
    pose = add(center, (math.sin(yaw)*math.cos(pitch)*distance,
                        math.sin(pitch)*distance,
                        math.cos(yaw)*math.cos(pitch)*distance))
    # Build projection basis independently from the resulting camera location.
    back = unit(sub(pose, center))
    right = unit(cross((0, 1, 0), back))
    up = cross(back, right)
    depths, extents = [], []
    for width, height in [(360, 240), (120, 600), (600, 120), (1, 1000)]:
        vertical = 48 if width >= height else math.degrees(2*math.atan(math.tan(math.radians(24))*height/width))
        # Approximate the actual RealityKit upload's Float angle, not Double alone.
        native_angle = f32(vertical)
        for corner in itertools.product(*zip(low, high)):
            delta = sub(corner, pose)
            depth = -dot(delta, back)
            half_height = depth*math.tan(math.radians(native_angle)/2)
            sx = dot(delta, right)/(half_height*width/height)
            sy = dot(delta, up)/half_height
            assert .02 < depth < distance+750
            assert abs(sx) < 1 and abs(sy) < 1
            depths.append(depth)
            extents.append(max(abs(sx), abs(sy)))
    return dict(name=name, minimum=low, maximum=high, radius_m=radius, fit_distance_m=distance,
                depth_min_m=min(depths), depth_max_m=max(depths), far_m=distance+750,
                max_absolute_normalized_screen_coordinate=max(extents), corner_projections=len(depths))

# Every authored center is within +/-100. An arbitrarily oriented 4 m housing
# is inside a sphere of radius sqrt(2.03^2 + 2.03^2 + .15^2).
margin = norm((2.03, 2.03, .15))
extent = 100 + margin
radius_max = math.sqrt(3)*extent
factor = 1.12/math.sin(math.radians(24))
max_target_to_geometry = math.sqrt(3)*(300+extent)
proof = dict(housing_radius_m=margin, global_coordinate_envelope_m=extent,
             radius_upper_bound_m=radius_max, fit_distance_upper_bound_m=radius_max*factor,
             fit_near_depth_lower_bound_m=.8*(factor-1),
             max_target_to_geometry_distance_m=max_target_to_geometry,
             far_plane_slack_lower_bound_m=750-max_target_to_geometry)
assert radius_max*factor < 1500
assert .8*(factor-1) > .02
assert max_target_to_geometry < 750
cases = [check_fit('all-valid-geometry-conservative-envelope', (-extent,)*3, (extent,)*3)]
for name, point in [('high-100m-stand-4m-coincident', (100, 100, 100)),
                    ('negative-extreme-4m-coincident', (-100, -100, -100))]:
    cases.append(check_fit(name, *coincident_four_meter(point)))

# Exact-pose witness corresponding to the extreme-pan regression.
target = (300, 300, -300)
back = unit((1, 1, -1))
distance = .45
camera = add(target, tuple(distance*x for x in back))
opposite = (-100, -100, 100)
depth = -dot(sub(opposite, camera), back)
assert 690 < depth < distance+750
pan_scale = 2*7*math.tan(math.radians(24))/240
pan = (-math.cos(.56)*10*pan_scale, 0, math.sin(.56)*10*pan_scale)
assert abs(norm(pan)-10*pan_scale) < 1e-12
result = dict(agent='/root/w04_acceptance/geometry', input_sha=PIN,
              kind='Python scalar derivation, not Swift/native execution',
              source_recheck='not performed; reviewed-only mode after executor reset' if reviewed_only else 'passed',
              proof=proof, cases=cases,
              extreme_pan=dict(target=target, distance_m=distance, depth_m=depth, far_m=distance+750),
              pan_10pt_at_7m_min_axis_240pt_displacement_m=norm(pan),
              source_sha256={p:hashlib.sha256(data).hexdigest() for p,data in sources.items()},
              assertions='passed')
commands.insert(0, '# Source reads succeeded before executor reset; these list the pinned git-show inputs.')
commands.append('# After reset, initial witness.py invocation exited 1: git could not chdir to missing repo (exit 128).')
commands.append('python3 /tmp/keyfill05-be879deb/waves/w04/geometry/witness.py --reviewed-only')
(OUT/'commands.txt').write_text('\n'.join(commands)+'\n')
(OUT/'witness.json').write_text(json.dumps(result, indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k != 'source_sha256'}, indent=2))
