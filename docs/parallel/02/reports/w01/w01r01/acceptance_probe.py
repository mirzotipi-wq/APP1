"""Independent Python numeric audit; not Swift execution or device evidence."""
import json, math, pathlib

OUTPUT = pathlib.Path(__file__).parent
# Fixed quadrature constants transcribed at the recorded input SHA.
GAUSS = [(0.009219682876640378, 0.023587668193255706), (0.0479413718147626, 0.05346966299765953), (0.11504866290284765, 0.08003916427167321), (0.20634102285669126, 0.10158371336153287), (0.31608425050090994, 0.1167462682691773), (0.43738329574426554, 0.12457352290670134), (0.5626167042557344, 0.12457352290670134), (0.6839157494990901, 0.1167462682691773), (0.7936589771433087, 0.10158371336153287), (0.8849513370971523, 0.08003916427167321), (0.9520586281852375, 0.05346966299765953), (0.9907803171233596, 0.023587668193255706)]
assert len(GAUSS) == 12

def normalize(v):
    scale = max(map(abs, v))
    a = [x / scale for x in v]
    length = math.sqrt(sum(x*x for x in a))
    return [x / length for x in a]

def production_transcription(w, h, receiver, normal, cd=1000):
    rx, ry, d = receiver
    nx, ny, nz = normalize(normal)
    if abs(d) < max(.05, w/4, h/4): return None
    if d < 0 or cd == 0: return 0.
    def incidence(x, y): return nx*(x-rx)+ny*(y-ry)-nz*d
    vertices = [(x,y,incidence(x,y)) for x,y in [(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]]
    if all(p[2] <= 0 for p in vertices): return 0.
    if all(p[2] >= 0 for p in vertices):
        return sum(cd/1024*d*incidence(x,y)/((x-rx)**2+(y-ry)**2+d*d)**2
                   for j in range(32) for i in range(32)
                   for x,y in [(((i+.5)/32-.5)*w,((j+.5)/32-.5)*h)])
    polygon=[]
    for i,b in enumerate(vertices):
        a=vertices[i-1]
        if a[2]*b[2] < 0:
            t=a[2]/(a[2]-b[2])
            polygon.append((a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1]),0.))
        if b[2]>=0: polygon.append(b)
    result=0.
    a=polygon[0]
    for b,c in zip(polygon[1:-1],polygon[2:]):
        ab=(b[0]-a[0],b[1]-a[1]); ac=(c[0]-a[0],c[1]-a[1])
        det=abs(ab[0]*ac[1]-ab[1]*ac[0])
        for u,wu in GAUSS:
            for v,wv in GAUSS:
                cw=(1-u)*v; aw=(1-u)*(1-v)
                x=a[0]+u*ab[0]+cw*ac[0]; y=a[1]+u*ab[1]+cw*ac[1]
                projection=aw*a[2]+u*b[2]+cw*c[2]
                result += det*wu*wv*(1-u)*d*projection/((x-rx)**2+(y-ry)**2+d*d)**2
    return cd/(w*h)*result

def simpson(f, a, b, n):
    if b<=a: return 0.
    step=(b-a)/n
    return step/3*sum((1 if i in (0,n) else (4 if i%2 else 2))*f(a+i*step) for i in range(n+1))

def reference(w,h,receiver,normal,n=160):
    rx,ry,d=receiver; nx,ny,nz=normalize(normal)
    cuts=[-w/2,w/2]
    if nx:
        cuts += [x for y in [-h/2,h/2] for x in [rx+(nz*d-ny*(y-ry))/nx] if -w/2<x<w/2]
    cuts.sort()
    def column(x):
        a,b=-h/2,h/2
        if ny:
            bound=ry+(nz*d-nx*(x-rx))/ny
            if ny>0: a=max(a,bound)
            else: b=min(b,bound)
        elif nx*(x-rx)-nz*d<=0: return 0.
        return simpson(lambda y: d*max(0,nx*(x-rx)+ny*(y-ry)-nz*d)/((x-rx)**2+(y-ry)**2+d*d)**2,a,b,n)
    return 1000/(w*h)*sum(simpson(column,a,b,n) for a,b in zip(cuts[:-1],cuts[1:]))

fixtures=[
    (1,1,(0,0,.25),(0,0,-1)),
    (4,.05,(0,0,1),(0,0,-1)),
    (.05,4,(.3,.7,1),(.2,-.3,-1)),
    (1,.6,(0,0,.25),(1,0,.49999/.25)),
    (1,.6,(0,0,.25),(1,1,.79999/.25)),
    (1,.6,(.4,.2,.25),(1,.5,-.1)),
    (1,1,(0,0,.25),(1,1,-.999999/.25)),
    (1,1,(0,0,.25),(1,1,-1.000001/.25)),
]
rows=[]
for w,h,r,n in fixtures:
    actual=production_transcription(w,h,r,n)
    ref=reference(w,h,r,n,160)
    fine=reference(w,h,r,n,320)
    row={'width':w,'height':h,'receiver':r,'normal':n,'transcribed_lux':actual,'reference_lux':fine,
         'relative_error':abs(actual/fine-1),'reference_refinement_delta':abs(ref/fine-1)}
    rows.append(row)
    assert row['relative_error']<.05, row
    assert row['reference_refinement_delta']<1e-5, row
assert production_transcription(1,1,(0,0,.249999),(0,0,-1)) is None
assert production_transcription(1,1,(0,0,-1),(0,0,1)) == 0
assert production_transcription(1,1,(0,0,1),(0,0,1)) == 0
assert normalize((1e308,1e308,0)) == normalize((1,1,0))
result={'evidence_kind':'Python transcription versus independent Simpson reference; Swift not executed',
        'input_sha':'f150f98e35dd735927075aac4d2f8b02295c6a67','fixtures':rows,
        'maximum_relative_error':max(r['relative_error'] for r in rows),'boundary_checks':4}
(OUTPUT/'acceptance_results.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'fixtures':len(rows),'maximum_relative_error':result['maximum_relative_error'], 'boundary_checks':4}))
