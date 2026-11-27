#!/usr/bin/env python3
"""Portable source-derived witness, not Swift/native execution. Python stdlib only.
SUT model: helper_bounds()/fit(). Independent oracle: displayed_shapes() support
functions from adapter primitive dimensions. Full-shape half-space checks avoid
sampling surfaces; the small named fixture matrix is not exhaustive scene input.
Frozen 4e source is hashed through git show even when a private candidate exists.
"""
import argparse, hashlib, itertools, json, math, platform, struct, subprocess
from dataclasses import dataclass
from pathlib import Path

SHA = "4e694bc377c4825d1d2dd52fcd7900e534c75072"
BASE = "f150f98e35dd735927075aac4d2f8b02295c6a67"
I = ((1.,0.,0.), (0.,1.,0.), (0.,0.,1.))
add = lambda a,b: tuple(x+y for x,y in zip(a,b))
mul = lambda a,s: tuple(x*s for x in a)
sub = lambda a,b: add(a,mul(b,-1))
dot = lambda a,b: sum(x*y for x,y in zip(a,b))
norm = lambda a: math.sqrt(dot(a,a))
unit = lambda a: mul(a,1/norm(a))
cross = lambda a,b: (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def apply(b,p):
    return tuple(sum(b[j][i]*p[j] for j in range(3)) for i in range(3))
def frame(p,t,roll=0):
    d=sub(t,p)
    if norm(d)==0: return None
    n=unit(d)
    r=unit(cross((0,1,0),n)) if math.hypot(n[0],n[2])>1e-12 else I[0]
    u=unit(cross(n,r))
    c,s=math.cos(math.radians(roll)),math.sin(math.radians(roll))
    if roll in (90,-90,180,-180): c,s={90:(0,1),-90:(0,-1),180:(-1,0),-180:(-1,0)}[roll]
    return unit(add(mul(r,c),mul(u,s))),unit(add(mul(r,-s),mul(u,c))),n
def f32(x): return struct.unpack(">f",struct.pack(">f",x))[0]
def next32(x): return struct.unpack(">f",struct.pack(">I",struct.unpack(">I",struct.pack(">f",x))[0]+1))[0]
def ideal_fov(w,h):
    return 48. if w>=h else 2*math.atan(math.tan(24*math.pi/180)*(h/w))*180/math.pi
def candidate_fov(w,h):
    v=ideal_fov(w,h); n=f32(v)
    n=next32(n) if n<v else n
    return n if n<180 else None

@dataclass
class Shape:
    label: str
    center: tuple
    half: tuple
    basis: tuple = I
    kind: str = "box"
    segment: float = 0.
    def support(self,n):
        d=tuple(dot(n,b) for b in self.basis)
        if self.kind=="box": h=sum(abs(x)*a for x,a in zip(d,self.half))
        elif self.kind=="ellipsoid": h=norm(tuple(x*a for x,a in zip(d,self.half)))
        elif self.kind=="capsule":
            h=norm(tuple(x*a for x,a in zip(d,self.half)))+self.segment*abs(d[1])
        elif self.kind=="cylinder":
            h=self.half[0]*math.hypot(d[0],d[2])+self.half[1]*abs(d[1])
        else: raise ValueError(self.kind)
        return dot(n,self.center)+h
    def bounds(self):
        return tuple(-self.support(mul(a,-1)) for a in I),tuple(self.support(a) for a in I)

def light(p,kind="point",w=.6,h=.9,target=None,roll=0):
    return dict(p=p,kind=kind,w=w,h=h,target=target,roll=roll)
def scene(s=(0,1.5,0),c=(0,1.5,3),lights=()):
    return dict(subject=s,camera=c,lights=list(lights))
def helper_bounds(sc):
    # Direct transcription of the source helper, deliberately separate from
    # displayed_shapes(). Its constants are tested, not used as oracle radii.
    shapes=[Shape("helper.subject",add(sc["subject"],(0,-.36,0)),(.36,.60,.36)),
            Shape("helper.camera",sc["camera"],(.24,.24,.24))]
    for l in sc["lights"]:
        p=l["p"]; t=l["target"] or sc["subject"]
        b=frame(p,t,l["roll"]) if l["kind"]!="point" else None
        shapes.append(Shape("core.center",p,(0,0,0)))
        if l["kind"]!="point": shapes.append(Shape("core.target",t,(0,0,0)))
        if b: shapes.append(Shape("helper.target",t,(.0275,)*3))
        if l["kind"]=="point": shapes.append(Shape("helper.point",p,(.12,)*3))
        else:
            w,h=(l["w"],l["h"]) if l["kind"]=="rectangle" else (.22,.18)
            b=b or I
            shapes.append(Shape("helper.housing",add(p,apply(b,(0,0,-.035))),(w/2+.03,h/2+.03,.115),b))
        if p[1]>.05: shapes.append(Shape("helper.base",(p[0],.014,p[2]),(.24,.014,.24)))
    bs=[q.bounds() for q in shapes]
    return tuple(min(b[0][i] for b in bs) for i in range(3)),tuple(max(b[1][i] for b in bs) for i in range(3))

def displayed_shapes(sc):
    out=[]
    def shape(label,p,size,b=I,kind="box",segment=0):
        out.append(Shape(label,p,tuple(x/2 for x in size),b,kind,segment))
    s,c=sc["subject"],sc["camera"]
    facing=sub(c,s); yaw=math.atan2(facing[0],facing[2]) if math.hypot(facing[0],facing[2])>.0001 else 0
    yb=((math.cos(yaw),0,-math.sin(yaw)),I[1],(math.sin(yaw),0,math.cos(yaw)))
    shape("SCN.head",s,(.38,.38,.38),kind="ellipsoid")
    shape("SCN.torso",add(s,(0,-.55,0)),(.552,.46,.299),kind="capsule",segment=.15)
    for label,pos,size in [("head",(0,0,0),(.34,.43,.32)),("neck",(0,-.25,0),(.14,.24,.14)),
                           ("torso",(0,-.58,0),(.58,.74,.3)),("nose",(0,-.02,.155),(.055,.075,.075))]:
        shape("RK."+label,add(s,apply(yb,pos)),size,yb,"ellipsoid")
    cb=frame(c,s) if norm(sub(s,c))>=.05 else None
    cb=(mul(cb[0],-1),cb[1],mul(cb[2],-1)) if cb else I
    for label,pos,size in [("SCN.camera.body",(0,0,0),(.26,.18,.18)),
        ("SCN.camera.lens",(0,0,-.12),(.095,.095,.10)),
        ("RK.camera.body",(0,0,0),(.26,.17,.14)),("RK.camera.lens",(0,0,-.11),(.095,.095,.12))]:
        shape(label,add(c,apply(cb,pos)),size,cb)
    for idx,l in enumerate(sc["lights"]):
        p=l["p"]; t=l["target"] or s; point=l["kind"]=="point"
        b=frame(p,t,l["roll"]) if not point else None
        basis=b or I; w,h=(l["w"],l["h"]) if l["kind"]=="rectangle" else (.22,.18)
        def local(label,pos,size,kind="box"):
            shape(str(idx)+"."+label,add(p,apply(basis,pos)),size,basis,kind)
        if point:
            local("SCN.point+selection",(0,0,0),(.18*1.06,)*3,"ellipsoid")
            local("RK.point",(0,0,0),(.16,)*3,"ellipsoid")
        else:
            depth=.055 if l["kind"]=="rectangle" else .13
            z=-depth/2 if b else 0
            local("SCN.housing",(0,0,z),(w,h,depth))
            local("SCN.selection",(0,0,z),(w+.04,h+.04,depth*1.06))
            local("RK.housing",(0,0,-.046),(w,h,.08))
            if b: local("RK.face",(0,0,-.003),(w if l["kind"]=="rectangle" else w-.012,h if l["kind"]=="rectangle" else h-.012,.006))
        # Twelve actual box edges: .009 m thickness, not just center lines.
        size=(.22,.22,.22) if point else (w+.04,h+.04,.12)
        for ax in range(3):
            a,bb=(ax+1)%3,(ax+2)%3
            for sa,sb in itertools.product((-1,1),repeat=2):
                pos=[0,0,0 if point else -.043]
                pos[a]+=sa*size[a]/2; pos[bb]+=sb*size[bb]/2
                edge=[.009]*3; edge[ax]=size[ax]
                local("RK.outline",tuple(pos),tuple(edge))
        if p[1]>.05:
            shape(str(idx)+".SCN.stand",(p[0],p[1]/2,p[2]),(.03,p[1],.03),kind="cylinder")
            shape(str(idx)+".RK.stand",(p[0],p[1]/2,p[2]),(.024,p[1],.024))
            shape(str(idx)+".RK.footX",(p[0],.014,p[2]),(.45,.025,.035))
            shape(str(idx)+".RK.footZ",(p[0],.014,p[2]),(.035,.025,.45))
        if b and norm(sub(t,p))>.0001:
            # An enclosing circular tube covers the rotated .005 x L x .005
            # square box for ANY twist from simd_quatf(from:Y,to:direction).
            d=unit(sub(t,p)); side=unit(cross(d,I[0] if abs(d[0])<.9 else I[2]))
            tb=(side,d,unit(cross(side,d)))
            shape(str(idx)+".RK.aim_tube",mul(add(p,t),.5),(.005*math.sqrt(2),norm(sub(t,p)),.005*math.sqrt(2)),tb,"cylinder")
            shape(str(idx)+".RK.aim_target",t,(.055,)*3,kind="ellipsoid")
    return out

def fitted(bounds,yaw=.56,pitch=.36):
    lo,hi=bounds; center=mul(add(lo,hi),.5); r=norm(sub(hi,lo))/2
    distance=min(1500,max(.45,max(.8,r)/math.sin(math.radians(24))*1.12))
    eye=add(center,mul((math.sin(yaw)*math.cos(pitch),math.sin(pitch),math.cos(yaw)*math.cos(pitch)),distance))
    forward=unit(sub(center,eye)); right=unit(cross(forward,I[1])); up=cross(right,forward)
    return eye,right,up,forward,distance,r
def frustum_margin(shapes,bounds,w,h,yaw,pitch,angle):
    eye,right,up,forward,distance,r=fitted(bounds,yaw,pitch)
    tv=math.tan(angle*math.pi/360); th=tv*w/h
    planes=[(sub(mul(right,s),mul(forward,th)),0) for s in (-1,1)]
    planes += [(sub(mul(up,s),mul(forward,tv)),0) for s in (-1,1)]
    planes += [(mul(forward,-1),-.02),(forward,distance+750)]
    worst=(float("inf"),"")
    for n,offset in planes:
        for q in shapes:
            margin=(dot(n,eye)+offset-q.support(n))/norm(n)
            if margin<worst[0]: worst=(margin,q.label)
    return dict(min_plane_clearance_m=worst[0],limiting_shape=worst[1])

def fixtures():
    portrait=scene(lights=[light((-1.5,2.1,1.2)),light((1.5,1.7,1.5)),light((.8,2.2,-1.2))])
    out={"ordinary":portrait}
    for label,d in [("translated_x80_z75",(80,0,75)),("translated_y75",(0,75,0))]:
        out[label]=scene(add(portrait["subject"],d),add(portrait["camera"],d),
                         [dict(l,p=add(l["p"],d)) for l in portrait["lights"]])
    out["coincident_4m"]=scene((0,2,-.1),(0,2,.1),[light((0,2,0),"rectangle",4,4,(0,2,0))])
    out["empty"]=scene()
    out["empty_coincident_boundary"]=scene((100,-100,100),(100,-100,100))
    out["sparse_no_stand"]=scene(lights=[light((2,.05,-1),"rectangle",.05,.05,(0,1.5,0),37)])
    out["tall_stand"]=scene((0,90,0),(0,90,3),[light((-2,100,1),"rectangle",4,.05,roll=89)])
    out["crowded_12"]=scene(lights=[light((-99 if i%2==0 else 99,i*8,i*17-95),"rectangle",4,.05,roll=i*29-170) for i in range(12)])
    aims=[((1,2,3),37),((0,4,0),90),((0,-2,0),-90),((-3,1,-2),-137.25),((2,-3,4),180),((0,2,0),0)]
    out["arbitrary_aim_roll"]=scene((-.7,1.3,.4),(2.7,-1.2,-3.1),[light((0,2,0),"directional" if i%2 else "rectangle",.05 if i%2 else 4,4 if i%2 else .05,t,r) for i,(t,r) in enumerate(aims)])
    for name,c in [("above",(0,4,0)),("below",(0,-2,0)),("back",(0,1.5,-3)),("side",(3,1.5,0)),("oblique",(-4,3,-2))]:
        out["authored_camera_"+name]=scene(c=c)
    return out

def run(repo):
    source_paths=["App/SpatialViewportGeometry.swift","App/SpatialPreview.swift","App/StudioEntityGraph.swift","App/RealityStudioPreview.swift",
                  "Sources/LightingCore/Scene.swift","Sources/LightingCore/StudioOptics.swift","Sources/LightingCore/StudioSceneBounds.swift","Sources/LightingCore/CameraFraming.swift"]
    hashes={p:hashlib.sha256(subprocess.check_output(["git","show",SHA+":"+p],cwd=repo)).hexdigest() for p in source_paths}
    layouts=[(360,240),(120,600),(600,120),(1,1000)]
    poses=[(.56,.36),(0,0),(2.4,-1.2),(-2.1,1.35)]
    rows=[]; failures=[]
    for name,sc in fixtures().items():
        shapes=displayed_shapes(sc); bounds=helper_bounds(sc); lo,hi=bounds
        excess=max(max(q.support(a)-hi[i],q.support(mul(a,-1))+lo[i]) for q in shapes for i,a in enumerate(I))
        ideal=[]; uploaded=[]
        for w,h in layouts:
            for yaw,pitch in poses:
                ideal.append(frustum_margin(shapes,bounds,w,h,yaw,pitch,ideal_fov(w,h)))
                uploaded.append(frustum_margin(shapes,bounds,w,h,yaw,pitch,f32(ideal_fov(w,h))))
        row=dict(name=name,scene=sc,primitives=len(shapes),bounds=bounds,max_envelope_excess_m=excess,
                 min_ideal_frustum_clearance_m=min(x["min_plane_clearance_m"] for x in ideal),
                 min_float_angle_only_clearance_m=min(x["min_plane_clearance_m"] for x in uploaded))
        if excess>1e-10 or row["min_ideal_frustum_clearance_m"]<0 or row["min_float_angle_only_clearance_m"]<0: failures.append(name)
        rows.append(row)
    stress=[]
    for w,h in layouts+[(.0003,3000),(.0002,3000),(.0001,3000),(.00001,1000)]:
        v=ideal_fov(w,h); n=f32(v); c=candidate_fov(w,h)
        stress.append(dict(width=w,height=h,ideal_vertical_degrees=v,nearest_float_degrees=n,old_accepts=n<180,
                          old_horizontal_half_degrees=math.degrees(math.atan(math.tan(n*math.pi/360)*w/h)),
                          candidate_vertical_degrees=c,candidate_accepts=c is not None,
                          candidate_horizontal_half_degrees=None if c is None else math.degrees(math.atan(math.tan(c*math.pi/360)*w/h))))
        if c is not None: assert c>=v and c<=next32(n) and c<180
    sc=scene((-100,1.5,0),(100,1.5,0))
    b=helper_bounds(sc); eye,right,up,fw,d,r=fitted(b); delta=sub(sc["camera"],eye)
    marker_angle=math.degrees(math.atan(abs(dot(delta,right))/dot(delta,fw)))
    v=ideal_fov(.0001,3000); n=f32(v)
    counter=dict(scene=sc,width=.0001,height=3000,bounds=b,fit_distance_m=d,
                 ideal_vertical_degrees=v,uploaded_float_vertical_degrees=n,old_accepts=n<180,
                 intended_minimum_half_degrees=24,uploaded_horizontal_half_degrees=stress[-2]["old_horizontal_half_degrees"],
                 authored_camera_marker_center_horizontal_degrees=marker_angle,
                 marker_center_normalized_x=dot(delta,right)/(dot(delta,fw)*math.tan(n*math.pi/360)*(.0001/3000)),
                 candidate_accepts=candidate_fov(.0001,3000) is not None)
    assert counter["old_accepts"] and marker_angle>counter["uploaded_horizontal_half_degrees"] and not counter["candidate_accepts"]
    expansion=math.sqrt(2.03**2+2.03**2+.15**2); maxradius=math.sqrt(3)*(100+expansion)
    return dict(canonical_id="/root/w08_acceptance/implementation",status="completed_portable_witness_and_source_review",input_sha=SHA,baseline_sha=BASE,
                runtime=dict(python=platform.python_version(),host=platform.platform(),native_execution=False),
                evidence="Source-derived analytical primitive support and pinhole arithmetic; NOT native rendering, Swift tests, runtime telemetry, calibration, or universal floating-point verification.",
                source_sha256=hashes,fixture_count=len(rows),layouts=layouts,orbit_yaw_pitch=poses,
                full_shape_frustum_checks_per_projection_model=len(rows)*len(layouts)*len(poses),
                failures=failures,fixtures=rows,scalar_fov_cases=stress,extreme_subpixel_counterexample=counter,
                universal_ideal_sphere_argument=dict(max_validated_envelope_radius_m=maxradius,max_fit_distance_m=maxradius/math.sin(math.radians(24))*1.12,
                    minimum_fit_distance_m=.8/math.sin(math.radians(24))*1.12,
                    maximum_sphere_half_angle_degrees=math.degrees(math.asin(math.sin(math.radians(24))/1.12)),
                    assumptions="Validated authored coordinates [-100,100], dimensions [0.05,4], orthonormal emitter frames, ideal primitives, no pan/zoom after Fit. Floor and grid intentionally excluded."),
                limitations=["Bounded scene/orbit matrix; analytical envelope argument supplements it.",
                    "Box bounds conservatively enclose chamfers and actual outline thickness.",
                    "Aim box is enclosed by a circular tube of radius sqrt(2)*0.0025; marker radius .0275.",
                    "Float-angle-only calculations retain ideal geometry/camera transforms; no quaternion, native matrix, Float transcendental, mesh tessellation, pixel rasterization or gesture execution claim.",
                    "Fit does not promise containment after intentional pan/zoom, or fit the floor/grid.",
                    "Candidate native regression is added but unrun; original 4e runtime evidence cannot validate this candidate."])

if __name__=="__main__":
    parser=argparse.ArgumentParser(); parser.add_argument("--repo",type=Path,required=True); parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args(); result=run(args.repo)
    args.output.write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps({k:result[k] for k in ("input_sha","fixture_count","full_shape_frustum_checks_per_projection_model","failures","extreme_subpixel_counterexample")},indent=2))
    raise SystemExit(bool(result["failures"]))

