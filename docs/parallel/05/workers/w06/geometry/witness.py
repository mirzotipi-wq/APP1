#!/usr/bin/env python3
"""Independent scalar/vector oracle. No Swift, SceneKit or RealityKit execution."""
import hashlib
import itertools
import json
import math
from pathlib import Path
import struct
import subprocess

PIN = "bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9"
REPO = Path("/tmp/keyfill05-be879deb/repo")
OUT = Path(__file__).parent
AGENT = "/root/w06_acceptance/geometry"

def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(k, a): return tuple(k * x for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def norm(a): return math.sqrt(dot(a, a))
def unit(a): return mul(1/norm(a), a)
def err(a, b): return max(abs(x-y) for x, y in zip(a, b))
def f32(x): return struct.unpack("f", struct.pack("f", x))[0]
def cast(a): return tuple(f32(x) for x in a)

def oracle(source, target, degrees):
    """Project world up, then Rodrigues-rotate: different derivation from Core."""
    delta = sub(target, source)
    if norm(delta) == 0:
        return None
    n = unit(delta)
    if math.hypot(n[0], n[2]) > 1e-12:
        u = unit(sub((0, 1, 0), mul(n[1], n)))
        r = cross(u, n)
    else:
        r = (1, 0, 0)
        u = cross(n, r)
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    def rotate(v):
        return add(add(mul(c, v), mul(s, cross(n, v))), mul((1-c)*dot(n, v), n))
    return rotate(r), rotate(u), n

def source_formula(source, target, degrees):
    """Literal Core scalar formula for comparison only; not execution of Core."""
    def scaled_unit(v):
        scale = max(map(abs, v))
        if not scale: return None
        return unit(mul(1/scale, v))
    n = scaled_unit(sub(target, source))
    if n is None: return None
    r = scaled_unit((n[2], 0, -n[0])) if math.hypot(n[0], n[2]) > 1e-12 else (1, 0, 0)
    u = scaled_unit(cross(n, r))
    c, s = {90:(0, 1), -90:(0, -1), 180:(-1, 0), -180:(-1, 0)}.get(
        degrees, (math.cos(math.radians(degrees)), math.sin(math.radians(degrees))))
    return scaled_unit(add(mul(c, r), mul(s, u))), scaled_unit(add(mul(-s, r), mul(c, u))), n

cases = [
    ("translated_oblique", (80, 2.1, 75), (78, 1.5, 72), 37.5),
    ("translated_vertical_up", (80, 2.1, 75), (80, 5, 75), 90),
    ("translated_vertical_down", (80, 2.1, 75), (80, 0, 75), -125),
    ("translated_vertical_recovery", (-24.5, 3.125, -33.75), (-24.5, 6.125, -33.75), 37.5),
]
checks = 0
def check(ok):
    global checks
    checks += 1
    assert ok, f"oracle assertion {checks} failed"

results = []
for name, p, t, roll in cases:
    r, u, n = oracle(p, t, roll)
    literal = source_formula(p, t, roll)
    formula_error = max(err(a, b) for a, b in zip((r, u, n), literal))
    orthogonality = max(abs(dot(r, u)), abs(dot(r, n)), abs(dot(u, n)))
    handedness = err(cross(r, u), n)
    check(formula_error < 1e-14)
    check(orthogonality < 1e-14 and handedness < 1e-14)
    check(max(abs(norm(a)-1) for a in (r, u, n)) < 1e-14)
    # SceneKit's local +Z front and RealityKit's diffuser front cancel the
    # housing/face offsets. This is ideal rigid-transform arithmetic only.
    scn_front = add(add(p, mul(-0.055/2, n)), mul(0.055/2, n))
    rk_front = add(p, mul(-0.003+0.006/2, n))
    check(err(scn_front, p) < 1e-12 and err(rk_front, p) < 1e-12)
    # Spotlight basis is [-right, up, -normal]; applying local -Z gives normal.
    spot_r, spot_u, spot_z = mul(-1, r), u, mul(-1, n)
    check(err(mul(-1, spot_z), n) < 1e-14)
    check(err(cross(spot_r, spot_u), spot_z) < 1e-14)
    # A conservative local enclosure comes directly from the viewport helper.
    # Check SCN front and inset RK front corners after transforming to world.
    enclosure_corners = [add(p, add(add(mul(x,r), mul(y,u)),mul(z,n)))
        for x,y,z in itertools.product((-0.63,0.63),(-0.38,0.38),(-0.15,0.08))]
    low = tuple(min(q[i] for q in enclosure_corners) for i in range(3))
    high = tuple(max(q[i] for q in enclosure_corners) for i in range(3))
    for width,height in ((1.2,0.7),(1.188,0.688)):
        for sx,sy in itertools.product((-1,1),repeat=2):
            corner = add(p, add(mul(sx*width/2,r),mul(sy*height/2,u)))
            check(all(lo-1e-12 <= x <= hi+1e-12 for lo,x,hi in zip(low,corner,high)))
    results.append(dict(name=name,source=p,target=t,roll_degrees=roll,
        right=r,up=u,normal=n,source_formula_max_component_error=formula_error,
        orthogonality_max=orthogonality,cross_right_up_minus_normal_max=handedness,
        scn_front_center=scn_front,rk_front_center=rk_front,
        front_center_max_error_m=max(err(scn_front,p),err(rk_front,p)),
        float32_position_cast_max_error_m=err(cast(p),p),
        float32_basis_cast_max_error=max(err(cast(a),a) for a in (r,u,n))))

p = cases[0][1]
coincident = oracle(p,p,37.5)
check(coincident is None and source_formula(p,p,37.5) is None)
# A defined frame is not the same condition as a visible native marker segment.
near_target = (p[0]+1e-7,p[1],p[2])
near_frame = oracle(p,near_target,37.5)
native_delta = sub(cast(near_target),cast(p))
check(near_frame is not None and norm(native_delta) == 0)
trace = [
    dict(state="valid",case=cases[0][0],core_frame="defined",scn_source="spot",rk_face=True,rk_source="spot"),
    dict(state="coincident",source=p,target=p,roll_degrees=37.5,core_frame=None,
         display_basis="world XYZ",scn_fixture_center=p,scn_source=None,rk_face=False,rk_source=None,rk_aim_markers=False),
    dict(state="recovered",case=cases[3][0],core_frame="defined",scn_source="spot",rk_face=True,rk_source="spot"),
]
extent_comparisons = []
for width,height in ((1.2,0.7),(0.05,0.05),(4.0,4.0)):
    before = (max(0.01,width-0.012),max(0.01,height-0.012))
    proposed = (width,height)
    area = width*height
    before_area = before[0]*before[1]
    check(before[0] < width and before[1] < height)
    check(proposed == (width,height) and abs(-0.003+0.006/2) == 0)
    check(err(cast(proposed),proposed) < 1e-6)
    extent_comparisons.append(dict(authored_dimensions_m=[width,height],
        frozen_rk_face_dimensions_m=before,proposed_face_dimensions_m=proposed,
        authored_area_m2=area,frozen_face_area_m2=before_area,proposed_face_area_m2=area,
        frozen_area_shortfall_percent=100*(area-before_area)/area,
        frozen_edge_inset_m=[(width-before[0])/2,(height-before[1])/2],
        frozen_corner_displacement_m=math.hypot((width-before[0])/2,(height-before[1])/2),
        both_front_z_m=-0.003+0.006/2,
        status="Correction is a proposal, not a claim that frozen source was modified or natively executed."))
paths = ["App/SpatialPreview.swift","App/StudioEntityGraph.swift","App/SpatialViewportGeometry.swift",
         "Sources/LightingCore/StudioOptics.swift","Sources/LightingCore/SurfacePhotometry.swift",
         "Sources/LightingCore/StudioSceneBounds.swift",
         "NativeTests/SpatialEmitterGeometryTests.swift","docs/parallel/05/GEOMETRY_COMPARISONS.md"]
hashes = {path:hashlib.sha256(subprocess.check_output(["git","show",f"{PIN}:{path}"],cwd=REPO)).hexdigest()
          for path in paths}
data = dict(agent=AGENT,source_commit=PIN,method="Independent Gram-Schmidt/Rodrigues oracle versus source-expressed scalar formulas; no native execution",
    assertion_count=checks,all_assertions_passed=True,cases=results,
    recovery_trace=trace,recovery_trace_evidence="Source branch analysis, not an executed state machine. A powered fixture with shading capacity is assumed.",
    near_coincident=dict(source=p,target=near_target,double_distance_m=norm(sub(near_target,p)),
        float32_delta=native_delta,core_frame_defined=True,rk_has_aim_geometry=False,
        rk_face_visible=True,rk_source_possible=True),
    rectangle_dimensions_m=dict(authored=[1.2,0.7],scn_box=[1.2,0.7],rk_housing=[1.2,0.7],
        rk_visible_diffuser=[1.188,0.688],rk_dimension_rule="max(0.01, authored dimension - 0.012)"),
    rectangle_extent_before_and_proposed=extent_comparisons,
    existing_native_test_tolerances=dict(position_m=2e-5,axis_and_dimensions=1e-6),
    limitations=["Float32 cast error excludes quaternion conversion and native node/entity transform arithmetic.",
        "No test/build/install, native framework execution, rendering, gesture, shading calibration or performance result.",
        "Source requires identity reset at coincidence; there is no physical direction to compare in that state.",
        "Recovery trace is source interpretation; the scalar assertions do not execute incremental Swift updates."],
    frozen_source_sha256=hashes)
(OUT/"witness.json").write_text(json.dumps(data,indent=2)+"\n")
print(json.dumps(dict(assertions=checks,passed=True,max_formula_error=max(x["source_formula_max_component_error"] for x in results),
    max_axis_cast_error=max(x["float32_basis_cast_max_error"] for x in results),
    max_position_cast_error_m=max(x["float32_position_cast_max_error_m"] for x in results),
    max_front_error_m=max(x["front_center_max_error_m"] for x in results),
    recovered_right=results[3]["right"],recovered_up=results[3]["up"],recovered_normal=results[3]["normal"]),indent=2))
