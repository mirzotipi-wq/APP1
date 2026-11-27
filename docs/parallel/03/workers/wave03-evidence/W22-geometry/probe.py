#!/usr/bin/env python3
"""W22: translated binary64 arithmetic only; no Swift, BVH, or renderer run.

Shared data: prescribed surface/profile/topology. Plane/projected-area oracle
does not use Moller-Trumbore. Decimal checks exact represented float inputs.
"""
import json
import math
import platform
import re
from decimal import Decimal, localcontext
from pathlib import Path

ROOT = Path('/tmp/keyfill03-7f4b/workers/W22-geometry')
OUT = Path(__file__).parent
SOURCE = (ROOT / 'Sources/LightingCore/PortraitHeadMesh.swift').read_text()
PROFILE = [tuple(map(float, match)) for match in re.findall(
    r'\.init\(y:\s*([-\d.]+), width:\s*([-\d.]+), front:\s*([-\d.]+), back:\s*([-\d.]+)\)', SOURCE)]
assert len(PROFILE) == 12
ROWS, COLS = 42, 64

def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,s): return tuple(x*s for x in a)
def dot(a,b): return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
def cross(a,b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def length(a): return math.sqrt(dot(a,a))
def unit(a): return tuple(x/length(a) for x in a)
def area(a,b,c,i,j): return (b[i]-a[i])*(c[j]-a[j])-(b[j]-a[j])*(c[i]-a[i])

def profile(y,key):
    if y <= PROFILE[0][0]: return PROFILE[0][key]
    if y >= PROFILE[-1][0]: return PROFILE[-1][key]
    i = next(i for i in range(len(PROFILE)-1) if y <= PROFILE[i+1][0])
    def secant(j): return (PROFILE[j+1][key]-PROFILE[j][key])/(PROFILE[j+1][0]-PROFILE[j][0])
    def slope(j):
        if j == 0: return secant(0)
        if j == len(PROFILE)-1: return secant(j-1)
        a,b = secant(j-1),secant(j)
        return 2*a*b/(a+b) if a*b > 0 else 0
    h = PROFILE[i+1][0]-PROFILE[i][0]
    t = (y-PROFILE[i][0])/h
    t2,t3 = t*t,t*t*t
    a,b = PROFILE[i][key],PROFILE[i+1][key]
    return (2*t3-3*t2+1)*a+(t3-2*t2+t)*h*slope(i)+(-2*t3+3*t2)*b+(t3-t2)*h*slope(i+1)

def vertex(row,col):
    y = -0.133 + (0.143-(-0.133))*(1-math.cos(math.pi*(row/ROWS)))/2
    if y <= -0.133: return (0.,-0.133,0.026)
    if y >= 0.143: return (0.,0.143,-0.005)
    angle = 2*math.pi*(col%COLS)/COLS
    width = max(0.,profile(y,1))
    front,back = profile(y,2),profile(y,3)
    cosine = math.cos(angle)
    x = width*math.sin(angle)
    z = (front+back)/2 + (front-back)*cosine/2
    if cosine > 0:
        def bump(cx,cy,sx,sy):
            dx,dy = (x-cx)/sx,(y-cy)/sy
            return math.exp(-0.5*(dx*dx+dy*dy))
        relief = 0.020*bump(0,0.004,0.012,0.033)
        relief += 0.037*bump(0,-0.032,0.014,0.016)
        relief += 0.005*bump(0,-0.048,0.021,0.010)
        for sign in [-1.,1.]:
            relief -= 0.014*bump(sign*0.037,0.023,0.018,0.013)
            relief += 0.007*bump(sign*0.039,0.044,0.022,0.010)
            relief += 0.008*bump(sign*0.047,-0.026,0.022,0.020)
        relief += 0.005*bump(0,-0.071,0.030,0.006)
        relief -= 0.004*bump(0,-0.079,0.029,0.0035)
        relief += 0.004*bump(0,-0.087,0.026,0.006)
        z += relief*cosine*cosine*min(1,width/0.05)
    return (x,y,z)

class Triangle:
    def __init__(self,key,a,b,c):
        self.key,self.a,self.b,self.c = key,a,b,c
        self.e1,self.e2 = sub(b,a),sub(c,a)
        self.raw = cross(self.e1,self.e2)
        self.twice = length(self.raw)
        self.normal = tuple(x/self.twice for x in self.raw)
        largest = max(range(3),key=lambda i:abs(self.raw[i]))
        self.i,self.j = (largest+1)%3,(largest+2)%3
        self.signed = area(a,b,c,self.i,self.j)
    def weights(self,p):
        a,b,c,i,j = self.a,self.b,self.c,self.i,self.j
        return [area(p,b,c,i,j)/self.signed,area(a,p,c,i,j)/self.signed,area(a,b,p,i,j)/self.signed]
    def plane(self,o,d,lo,hi):
        den = dot(self.normal,d)
        if abs(den) <= 1e-14: return None
        t = dot(self.normal,sub(self.a,o))/den
        if not (lo <= t < hi): return None
        w = self.weights(add(o,mul(d,t)))
        return (t,w) if min(w) >= -1e-10 else None
    def mt(self,o,d,lo,hi,old=False):
        p = cross(d,self.e2)
        det = dot(self.e1,p)
        if abs(det) <= (1e-14 if old else self.twice*1e-14): return None
        inv,offset = 1/det,sub(o,self.a)
        u = dot(offset,p)*inv
        if not (-1e-10 <= u <= 1+1e-10): return None
        q = cross(offset,self.e1)
        v = dot(d,q)*inv
        if not (v >= -1e-10 and u+v <= 1+1e-10): return None
        t = dot(self.e2,q)*inv
        return (t,[1-u-v,u,v]) if lo <= t < hi else None

vertices = [[vertex(r,c) for c in range(COLS)] for r in range(ROWS+1)]
triangles = []
degenerate = 0
for r in range(ROWS):
    for c in range(COLS):
        n = (c+1)%COLS
        a,b,cc,d = vertices[r][c],vertices[r][n],vertices[r+1][c],vertices[r+1][n]
        for second,points in [(False,(a,b,cc)),(True,(b,d,cc))]:
            raw = cross(sub(points[1],points[0]),sub(points[2],points[0]))
            if dot(raw,raw) == 0:
                degenerate += 1
            else:
                assert dot(raw,raw) > 1e-24
                triangles.append(Triangle((r,c,second),*points))
lookup = {t.key:t for t in triangles}

def decvec(v): return tuple(Decimal.from_float(x) for x in v)
def exact_float_plane(tri,o,d):
    with localcontext() as ctx:
        ctx.prec = 70
        a,b,c,o,d = map(decvec,[tri.a,tri.b,tri.c,o,d])
        raw = cross(sub(b,a),sub(c,a))
        den = dot(raw,d)
        t = dot(raw,sub(a,o))/den
        p = add(o,mul(d,t))
        i,j = tri.i,tri.j
        ar = area(a,b,c,i,j)
        w = [area(p,b,c,i,j)/ar,area(a,p,c,i,j)/ar,area(a,b,p,i,j)/ar]
        return {'distance':str(t),'weights':list(map(str,w)),
                'incidence':str(den/dot(raw,raw).sqrt())}

origin = (3.404646637409472e-5,-0.1327573713979657,0.026792162348130817)
direction = (0.08733597770659,0.2924411459428683,0.9522870382178139)
faces = [(0,0,True),(0,16,True),(41,32,False),(10,7,False),(20,19,True),(30,37,False)]
base_rays = [('preserved',(0,0,True),origin,direction)]
for key in faces:
    tri = lookup[key]
    # Swift divides each component by 3: retain that operation exactly.
    centroid = tuple(x/3 for x in add(add(tri.a,tri.b),tri.c))
    tangent = unit(sub(tri.c,tri.a))
    for incidence in [1e-6,1e-8]:
        for sign in [-1.,1.]:
            d = unit(sub(mul(tangent,sign),mul(tri.normal,incidence)))
            o = sub(centroid,mul(d,5e-5))
            base_rays.append((f'{key}/{incidence}/{sign}',key,o,d))
rays = []
for name,key,o,d in base_rays:
    rays.append((name+'/forward',key,o,d))
    rays.append((name+'/reverse',key,add(o,mul(d,1e-4)),mul(d,-1)))

records = []
for name,key,o,d in rays:
    tri = lookup[key]
    rec = {'name':name,'face':key,'origin':o,'direction':d,'directionNorm':length(d),
           'incidence':dot(tri.normal,d),'twiceArea':tri.twice,
           'determinant':dot(tri.e1,cross(d,tri.e2)),
           'threshold':tri.twice*1e-14,'exactRepresentedInputPlane':exact_float_plane(tri,o,d)}
    for kind in ['plane','mt']:
        matches = [(t.key,getattr(t,kind)(o,d,1e-6,1e-4)) for t in triangles]
        matches = [(key,h) for key,h in matches if h is not None]
        rec[kind] = [{'face':key,'distance':h[0],'weights':h[1]} for key,h in matches]
        rec[kind+'Windows'] = [any(getattr(t,kind)(o,d,lo,hi) is not None for t in triangles)
                              for lo,hi in [(1e-6,4e-5),(1e-6,1e-4),(6e-5,1e-4)]]
    rec['oldAbsoluteDeterminantHit'] = any(t.mt(o,d,1e-6,1e-4,old=True) is not None for t in triangles)
    assert len(rec['plane']) == len(rec['mt']) == 1, rec
    assert tuple(rec['plane'][0]['face']) == tuple(rec['mt'][0]['face']) == key, rec
    assert rec['planeWindows'] == rec['mtWindows'] == [False,True,False], rec
    assert abs(rec['plane'][0]['distance']-rec['mt'][0]['distance']) <= 1e-8, rec
    assert 0.30 < min(rec['plane'][0]['weights']) <= max(rec['plane'][0]['weights']) < 0.37, rec
    records.append(rec)

# Independent angular-threshold stress: no plane crossing guarantee below the
# tested 1e-8 incidence because floating-point coordinate noise is amplified.
stress = []
for key in faces:
    tri = lookup[key]
    tangent = unit(sub(tri.c,tri.a))
    for incidence in [0.,1e-15,5e-15,9.9e-15,1e-14,1.01e-14,2e-14,1e-13,1e-12,1e-10,1e-8,1e-6]:
        for sign in [-1.,1.]:
            d = unit(sub(mul(tangent,sign),mul(tri.normal,incidence)))
            determinant = dot(tri.e1,cross(d,tri.e2))
            det_incidence = -determinant/tri.twice
            plane_incidence = dot(tri.normal,d)
            with localcontext() as ctx:
                ctx.prec = 70
                a,b,c,dd = map(decvec,[tri.a,tri.b,tri.c,d])
                raw = cross(sub(b,a),sub(c,a))
                exact = dot(raw,dd)/dot(raw,raw).sqrt()
                exact_pass = abs(exact)>Decimal.from_float(1e-14)
            stress.append({'face':key,'nominalIncidence':incidence,'sign':sign,
                'planeIncidence':plane_incidence,'determinantIncidence':det_incidence,
                'exactRepresentedIncidence':str(exact),'exactPass':exact_pass,
                'planePass':abs(plane_incidence)>1e-14,'determinantPass':abs(determinant)>tri.twice*1e-14})

stored = json.loads((ROOT/'docs/parallel/03/evidence/grazing-original.json').read_text())
assert records[0]['plane'][0]['distance'] == stored['oracleDistanceMeters']
assert records[0]['plane'][0]['weights'] == stored['oracleBarycentricWeights']
assert records[0]['incidence'] == stored['incidenceCosine']
assert records[0]['twiceArea'] == stored['triangleTwiceAreaSquareMeters']

summary = {'label':'Python translated arithmetic, not actual Swift/BVH execution',
    'inputSHA':'1cefc654630a86ab320e58283957f4e91d6cbce6','runtimeID':'/root/wave03/geometry_data',
    'host':platform.platform(),'python':platform.python_version(),
    'meshTriangles':len(triangles),'coincidentPoleTrianglesExcluded':degenerate,
    'storedWitnessPlaneValuesExactFloatMatch':True,
    'minTwiceArea':min(t.twice for t in triangles),'maxTwiceArea':max(t.twice for t in triangles),
    'cachedNormalMaxLengthError':max(abs(length(t.normal)-1) for t in triangles),
    'rays':len(records),'uniqueMatchingFaces':len(records),
    'finiteWindowChecksPerMethod':3*len(records),
    'maxPlaneMTDistanceDelta':max(abs(r['plane'][0]['distance']-r['mt'][0]['distance']) for r in records),
    'maxPlaneCentroidDistanceDelta':max(abs(r['plane'][0]['distance']-5e-5) for r in records),
    'minPlaneWeight':min(min(r['plane'][0]['weights']) for r in records),
    'maxPlaneWeight':max(max(r['plane'][0]['weights']) for r in records),
    'maxWeightSumError':max(abs(sum(r['plane'][0]['weights'])-1) for r in records),
    'oldThresholdMisses':sum(not r['oldAbsoluteDeterminantHit'] for r in records),
    'thresholdStressCases':len(stress),
    'thresholdStressPlaneMTDisagreements':[s for s in stress if s['planePass'] != s['determinantPass']],
    'thresholdStressMTExactDisagreements':[s for s in stress if s['exactPass'] != s['determinantPass']],
    'maxAngularFormulaDifference':max(abs(s['planeIncidence']-s['determinantIncidence']) for s in stress),
    'preserved':records[:2]}
(OUT/'results.json').write_text(json.dumps({'summary':summary,'rays':records,'thresholdStress':stress},indent=2)+'\n')
print(json.dumps(summary,indent=2))
