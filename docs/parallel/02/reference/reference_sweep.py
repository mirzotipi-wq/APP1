#!/usr/bin/env python3
"""Independent scalar point / spherical-edge rectangle reference (stdlib only).

The rectangle uses the projected solid-angle boundary integral:
E/L = |n dot sum(atan2(|a cross b|, a dot b) * normalize(a cross b))| / 2.
Vectors a,b are spherical polygon vertices, clipped to n's positive hemisphere.
This is independent of production's area midpoint / Duffy quadrature.
See PBRT 4e section4.2; derivation and limitations in REFERENCE-METHODS.md.
"""
import argparse, json, math, pathlib

def dot(a,b): return math.fsum(x*y for x,y in zip(a,b))
def cross(a,b): return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def norm(a):
    m=math.hypot(*a)
    return [x/m for x in a]
def rectangle(w,h,receiver,n,roll,intensity):
    t=math.radians(roll);r=[math.cos(t),math.sin(t),0];u=[-math.sin(t),math.cos(t),0]
    n=norm(n)
    vertices=[norm([r[k]*x+u[k]*y-receiver[k] for k in range(3)]) for x,y in [(-w/2,-h/2),(w/2,-h/2),(w/2,h/2),(-w/2,h/2)]]
    poly=[]
    for a,b in zip(vertices[-1:]+vertices[:-1],vertices):
        da,db=dot(n,a),dot(n,b)
        if da*db<0:
            t=da/(da-db);poly.append(norm([(1-t)*a[k]+t*b[k] for k in range(3)]))
        if db>=0:poly.append(b)
    if len(poly)<3:return 0.0
    contributions=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        c=cross(a,b);s=math.hypot(*c)
        if s:contributions.append(dot(n,c)/s*math.atan2(s,dot(a,b)))
    return intensity/(w*h)*abs(math.fsum(contributions))/2

def fixtures():
    rows=[]
    for distance in [.05,.1,.5,1,2,5,10,50]:
        for degrees in [0,15,45,60,89,90,120,180]:
            a=math.radians(degrees);normal=[math.sin(a),0,math.cos(a)]
            rows.append(dict(id=f'p-{distance}-{degrees}',kind='point',source=[0,0,distance],receiver=[0,0,0],normal=normal,candela=1375,expected=1375/(distance*distance)*max(0,math.cos(a))))
    for w,h in [(.05,.05),(.1,4),(.6,.9),(1,1),(4,.05),(4,4)]:
        for factor in [.25,.5,1,3]:
            d=max(.05,max(w,h)*factor)
            for roll in [0,37,90,179]:
                for ox,oy in [(0,0),(.3,-.2),(.8,.5)]:
                    receiver=[ox*w,oy*h,d]
                    for tilt in [0,35,80,100,130]:
                        a=math.radians(tilt);normal=[math.sin(a)*math.cos(.7),math.sin(a)*math.sin(.7),-math.cos(a)]
                        expected=rectangle(w,h,receiver,normal,roll,1375)
                        rows.append(dict(id=f'r-{w}-{h}-{factor}-{roll}-{ox}-{oy}-{tilt}',kind='rectangle',source=[0,0,0],receiver=receiver,normal=normal,width=w,height=h,roll=roll,candela=1375,expected=expected))
    return rows

def main():
    p=argparse.ArgumentParser();p.add_argument('--fixtures',type=pathlib.Path);p.add_argument('--actual',type=pathlib.Path);p.add_argument('--report',type=pathlib.Path);a=p.parse_args()
    if a.fixtures:a.fixtures.write_text(json.dumps(fixtures(),indent=2)+'\n')
    if a.actual:
        rows=json.loads(a.actual.read_text());report={'method':'spherical-edge projected solid angle; scalar inverse square/cosine','point_relative_limit':.01,'rectangle_relative_limit':.05,'zero_reference_absolute_lux_limit':1e-8,'rows':len(rows),'groups':{}}
        for kind in ['point','rectangle']:
            subset=[r for r in rows if r['kind']==kind];positive=[r for r in subset if r['expected']>1e-7];dark=[r for r in subset if r['expected']<=1e-7]
            for r in subset:
                if 'actual' not in r or r['actual'] is None:raise AssertionError(('unexpected unsupported',r['id']))
                if r['expected']>1e-7:r['relative_error']=abs(r['actual']/r['expected']-1)
            worst=max(positive,key=lambda r:r['relative_error'])
            limit=.01 if kind=='point' else .05
            assert worst['relative_error']<=limit,(kind,worst)
            max_abs=max([abs(r['actual']-r['expected']) for r in dark],default=0)
            assert max_abs<=1e-8,(kind,max_abs)
            report['groups'][kind]={'rows':len(subset),'positive_rows':len(positive),'dark_or_nearzero_rows':len(dark),'max_relative_error':worst['relative_error'],'worst_case':worst['id'],'expected_lux':worst['expected'],'actual_lux':worst['actual'],'maximum_dark_absolute_error_lux':max_abs}
        if a.report:a.report.write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps(report,indent=2))
if __name__=='__main__':main()
