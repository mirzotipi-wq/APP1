"""Independent Python transcriptions for a source review; this does NOT run Swift.

Production equations are transcribed from SurfacePhotometry.swift/Scene.swift.
The independent area reference integrates vertical slices with Gauss-Legendre
quadrature, without the production polygon clipping/triangle mapping.
Only Python's standard library is used. Writes results alongside this script.
"""
import json
import math
import random
from decimal import Decimal, localcontext
from pathlib import Path


def unit(v):
    if not all(math.isfinite(x) for x in v):
        return None
    s = max(map(abs, v))
    if s == 0:
        return None
    w = [x / s for x in v]
    n = math.sqrt(sum(x * x for x in w))
    return tuple(x / n for x in w)


def normal_lux(cd, d):
    if not (math.isfinite(cd) and 0 <= cd <= 100000 and math.isfinite(d) and d >= .05):
        return None
    return cd / (d * d)


def point(cd, delta, n):
    d = math.sqrt(sum(x * x for x in delta))
    e = normal_lux(cd, d)
    return None if e is None else e * min(1, max(0, sum(x / d * y for x, y in zip(delta, n))))


def gauss(n):
    """Generate symmetric Legendre nodes/weights on [0,1]."""
    out = []
    for i in range(1, n + 1):
        x = math.cos(math.pi * (i - .25) / (n + .5))
        for _ in range(30):
            p0, p1 = 1.0, x
            for k in range(2, n + 1):
                p0, p1 = p1, ((2*k-1)*x*p1 - (k-1)*p0)/k
            dp = n*(x*p1-p0)/(x*x-1)
            dx = p1 / dp
            x -= dx
            if abs(dx) < 2e-16:
                break
        out.append(((x+1)/2, 1/((1-x*x)*dp*dp)))
    return sorted(out)


G12 = [
    (.009219682876640378, .023587668193255706),
    (.0479413718147626, .05346966299765953),
    (.11504866290284765, .08003916427167321),
    (.20634102285669126, .10158371336153287),
    (.31608425050090994, .1167462682691773),
    (.43738329574426554, .12457352290670134),
    (.5626167042557344, .12457352290670134),
    (.6839157494990901, .1167462682691773),
    (.7936589771433087, .10158371336153287),
    (.8849513370971523, .08003916427167321),
    (.9520586281852375, .05346966299765953),
    (.9907803171233596, .023587668193255706),
]
G48 = gauss(48)


def rect(cd, w, h, receiver, n):
    """Transcription: center=(0,0,0), right=X, up=Y, emitter normal=Z."""
    rx, ry, depth = receiver
    if abs(depth) < max(.05, max(w,h)/4):
        return None
    if depth < 0 or cd == 0:
        return 0.0
    offset = sum(a*b for a,b in zip(receiver,n))
    vertices = [(x,y,n[0]*x+n[1]*y-offset) for x,y in
                [(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]]
    if all(v[2] <= 0 for v in vertices):
        return 0.0
    if all(v[2] >= 0 for v in vertices):
        per_cell = cd / 1024
        result = 0.0
        for j in range(32):
            y = ((j+.5)/32-.5)*h
            for i in range(32):
                x = ((i+.5)/32-.5)*w
                d = (rx-x, ry-y, depth)
                r2 = sum(v*v for v in d)
                direction = tuple(v/math.sqrt(r2) for v in d)
                em = min(1,max(0,direction[2]))
                inc = min(1,max(0,-sum(a*b for a,b in zip(direction,n))))
                result += per_cell * em * inc / r2
        return result
    polygon = []
    for i,b in enumerate(vertices):
        a = vertices[(i-1)%4]
        if (a[2] < 0 < b[2]) or (b[2] < 0 < a[2]):
            t = a[2]/(a[2]-b[2])
            polygon.append((a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t,0))
        if b[2] >= 0:
            polygon.append(b)
    integral = 0.0
    if len(polygon) < 3:
        return 0.0
    a = polygon[0]
    for i in range(1,len(polygon)-1):
        b,c = polygon[i:i+2]
        ab = (b[0]-a[0],b[1]-a[1])
        ac = (c[0]-a[0],c[1]-a[1])
        det = abs(ab[0]*ac[1]-ab[1]*ac[0])
        for u,wu in G12:
            remaining = 1-u
            for v,wv in G12:
                cw = remaining*v
                aw = remaining*(1-v)
                x,y = (a[k]+ab[k]*u+ac[k]*cw for k in range(2))
                inc = aw*a[2]+u*b[2]+cw*c[2]
                r2 = (rx-x)**2+(ry-y)**2+depth**2
                integral += det*wu*wv*remaining*depth*inc/(r2*r2)
    return cd/(w*h)*integral


def reference(cd,w,h,receiver,n):
    """Independent vertical-slice area reference, exact affine domain bounds."""
    rx,ry,z = receiver
    nx,ny,nz = n
    if z < 0:
        return 0.0
    offset = nx*rx+ny*ry+nz*z
    xbreaks = [-w/2,w/2]
    if nx != 0:
        for y in [-h/2,h/2]:
            crossing = (offset-ny*y)/nx
            if -w/2 < crossing < w/2:
                xbreaks.append(crossing)
    xbreaks.sort()
    integral = 0.0
    for x0,x1 in zip(xbreaks,xbreaks[1:]):
        for gx,wx in G48:
            x = x0+(x1-x0)*gx
            lo,hi = -h/2,h/2
            if ny > 0:
                lo = max(lo,(offset-nx*x)/ny)
            elif ny < 0:
                hi = min(hi,(offset-nx*x)/ny)
            elif nx*x-offset <= 0:
                continue
            if lo >= hi:
                continue
            for gy,wy in G48:
                y = lo+(hi-lo)*gy
                r2 = (x-rx)**2+(y-ry)**2+z*z
                inc = max(0,nx*x+ny*y-offset)
                integral += (x1-x0)*wx*(hi-lo)*wy*z*inc/(r2*r2)
    return cd/(w*h)*integral


def analytic(cd,w,h,d):
    a,b = w/2,h/2
    da,db = math.hypot(d,a),math.hypot(d,b)
    return 2*cd/(w*h)*(a/da*math.atan(b/da)+b/db*math.atan(a/db))


results = {"provenance": "Independent Python transcription, not executed Swift", "seed": 20261126}
normal_cases = [(3,4,0),(1e308,1e308,0),(1e-320,1e-320,0),(5e-324,0,0),(0,0,0),(math.nan,1,0),(math.inf,1,0)]
results["normalized_directions"] = [{"input":repr(v),"output":unit(v)} for v in normal_cases]
results["point"] = {
    "one_meter":point(400,(0,0,1),unit((0,0,1))),
    "two_meters":point(400,(0,0,2),unit((0,0,1))),
    "two_meters_receiver_60_degrees":point(400,(0,0,2),unit((math.sqrt(3),0,1))),
    "backface":point(400,(0,0,2),unit((0,0,-1))),
    "below_minimum":normal_lux(400,math.nextafter(.05,0)),
    "at_minimum":normal_lux(400,.05),
    "directional_60_degree_emission_60_degree_receiver":point(400,(0,0,2),unit((math.sqrt(3),0,1)))*.5,
}
results["rect_boundary"] = {
    "below_minimum":rect(1000,1,.6,(0,0,math.nextafter(.25,0)),(0,0,-1)),
    "at_minimum":rect(1000,1,.6,(0,0,.25),(0,0,-1)),
    "backface":rect(1000,1,.6,(0,0,-.25),(0,0,1)),
    "off_near_plane":rect(0,1,.6,(0,0,.1),(0,0,-1)),
}
parallel = []
for w,h,d in [(.05,.05,.05),(.1,.1,.05),(4,.05,1),(4,4,1),(1,.6,.25),(.05,4,1),(1,.6,20)]:
    actual = rect(1000,w,h,(0,0,d),(0,0,-1))
    expected = analytic(1000,w,h,d)
    parallel.append({"width":w,"height":h,"depth":d,"actual":actual,"analytic":expected,"relative_error":abs(actual/expected-1)})
results["parallel_rectangles"] = parallel
scales = []
for n0 in [(0.2,-0.1,-1),(1,.5,.1)]:
    n = unit(n0)
    r = (.2,-.1,.7)
    baseline = rect(875,.8,.5,r,n)
    for s in [.25,.5,2,4]:
        actual = rect(875,.8*s,.5*s,tuple(x*s for x in r),n)
        scales.append({"normal":n,"scale":s,"relative_scaled_error":abs(actual*s*s/baseline-1)})
results["rectangle_similarity"] = scales
rng = random.Random(20261126)
area = []
for _ in range(128):
    w,h = rng.choice([.05,.1,.3,1,4]),rng.choice([.05,.1,.3,1,4])
    size = max(w,h)
    z = max(.05,size/4)*rng.choice([1,1.0000001,2,10])
    r = (rng.uniform(-1.5,1.5)*size,rng.uniform(-1.5,1.5)*size,z)
    n = unit(tuple(rng.uniform(-1,1) for _ in range(3)))
    actual,expected = rect(1000,w,h,r,n),reference(1000,w,h,r,n)
    error = abs(actual/expected-1) if expected > 0 else abs(actual)
    area.append({"width":w,"height":h,"receiver":r,"normal":n,"actual":actual,"reference":expected,"relative_error":error})
for slope in [0,1]:
    for gap in [1e-2,1e-3,1e-5,1e-7]:
        cut = .5+.3*slope-gap
        n = unit((1,slope,cut/.25))
        actual = rect(1000,1,.6,(0,0,.25),n)
        expected = reference(1000,1,.6,(0,0,.25),n)
        area.append({"grazing_gap":gap,"slope":slope,"actual":actual,"reference":expected,"relative_error":abs(actual/expected-1)})
results["area_reference_cases"] = area
results["maximum_area_reference_relative_error"] = max(x["relative_error"] for x in area)
with localcontext() as ctx:
    ctx.prec = 80
    exact_d = Decimal.from_float(1e155)
    expected = float(Decimal(100000)/(exact_d*exact_d))
results["direct_api_overflow_reproducer"] = {
    "candela":100000,"distance_meters":1e155,
    "transcribed_result":normal_lux(100000,1e155),"decimal_reference":expected,
    "reason":"distance squared overflows although final lux is representable; outside bounded scene coordinate domain",
}
tiny = math.ulp(0.0)
results["accepted_subnormal_rectangle_edge"] = {
    "candela":tiny,"width":.05,"height":.05,"depth":.05,
    "transcribed_result":rect(tiny,.05,.05,(0,0,.05),(0,0,-1)),
    "closed_form_result":analytic(tiny,.05,.05,.05),
    "reason":"candela/1024 underflows before inverse area factor can amplify result",
}
results["derived_flux_at_1000_candela"] = {
    "isotropic_point_lumens":4*math.pi*1000,
    "one_sided_cosine_or_rectangle_lumens":math.pi*1000,
    "note":"Derived from angular integrals; no core lumen conversion API was found",
}
assert results["point"]["one_meter"] == 4*results["point"]["two_meters"]
assert max(x["relative_error"] for x in parallel) < .01
assert max(x["relative_scaled_error"] for x in scales) < 1e-12
assert results["maximum_area_reference_relative_error"] < .05
output = Path(__file__).with_name("invariant_results.json")
output.write_text(json.dumps(results,indent=2,allow_nan=False)+"\n")
print(json.dumps({"provenance":results["provenance"],
    "area_reference_cases":len(area),
    "maximum_area_reference_relative_error":results["maximum_area_reference_relative_error"],
    "maximum_parallel_relative_error":max(x["relative_error"] for x in parallel),
    "maximum_similarity_relative_error":max(x["relative_scaled_error"] for x in scales),
    "direct_api_overflow_reproducer":results["direct_api_overflow_reproducer"],
    "accepted_subnormal_rectangle_edge":results["accepted_subnormal_rectangle_edge"],
    "result_path":str(output)},indent=2))
