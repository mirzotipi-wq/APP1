"""Independent Python geometry/numerical probe; this does NOT execute Swift."""
import math, json

def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,s): return tuple(x*s for x in a)
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def norm(a): return math.sqrt(dot(a,a))
def unit(a):
    s=max(map(abs,a)); b=mul(a,1/s)
    return mul(b,1/norm(b))
def frame(source,target,degrees):
    n=unit(sub(target,source))
    r=unit((n[2],0,-n[0])) if math.hypot(n[0],n[2])>1e-12 else (1,0,0)
    u=unit(cross(n,r)); c=math.cos(math.radians(degrees)); s=math.sin(math.radians(degrees))
    return unit(add(mul(r,c),mul(u,s))),unit(add(mul(r,-s),mul(u,c))),n

gl=[(.009219682876640378,.023587668193255706),(.0479413718147626,.05346966299765953),(.11504866290284765,.08003916427167321),(.20634102285669126,.10158371336153287),(.31608425050090994,.1167462682691773),(.43738329574426554,.12457352290670134),(.5626167042557344,.12457352290670134),(.6839157494990901,.1167462682691773),(.7936589771433087,.10158371336153287),(.8849513370971523,.08003916427167321),(.9520586281852375,.05346966299765953),(.9907803171233596,.023587668193255706)]

def clipped_transcription(center,r,u,width,height,receiver,nr):
    tr=sub(receiver,center); n=cross(r,u); depth=dot(tr,n)
    assert depth >= max(.05,max(width,height)/4)
    nx,ny,offset=dot(r,nr),dot(u,nr),dot(tr,nr)
    vertices=[((x,y),nx*x+ny*y-offset) for x,y in [(-width/2,-height/2),(width/2,-height/2),(width/2,height/2),(-width/2,height/2)]]
    assert min(v[1] for v in vertices)<0<max(v[1] for v in vertices)
    polygon=[]
    for i,b in enumerate(vertices):
        a=vertices[i-1]
        if a[1]*b[1]<0:
            t=a[1]/(a[1]-b[1]); polygon.append((add(a[0],mul(sub(b[0],a[0]),t)),0))
        if b[1]>=0: polygon.append(b)
    integral=0.; area=0.; a=polygon[0]
    for i in range(1,len(polygon)-1):
        b,c=polygon[i:i+2]; ab=sub(b[0],a[0]); ac=sub(c[0],a[0]); det=abs(ab[0]*ac[1]-ab[1]*ac[0]); area+=det/2
        for x,wx in gl:
            for y,wy in gl:
                cw=(1-x)*y; aw=(1-x)*(1-y)
                p=add(add(a[0],mul(ab,x)),mul(ac,cw))
                incidence=aw*a[1]+x*b[1]+cw*c[1]
                delta=sub(sub(tr,mul(r,p[0])),mul(u,p[1])); r2=dot(delta,delta)
                integral+=det*wx*wy*(1-x)*depth*incidence/r2**2
    world=[add(center,add(mul(r,p[0]),mul(u,p[1]))) for p,_ in polygon]
    area_vector=(0.,0.,0.)
    for i,p in enumerate(world): area_vector=add(area_vector,cross(sub(p,center),sub(world[(i+1)%len(world)],center)))
    return {'lux':1000/(width*height)*integral,'clipped_local_area':area,'clipped_world_area':norm(area_vector)/2,'corners_incidence':[v[1] for v in vertices],'depth':depth,'polygon_vertices':len(polygon)}

center=(.4,1.5,-.3); target=(2.4,4.5,5.7); width=1.2; height=.6; roll=37.
r,u,n=frame(center,target,roll); r0,u0,_=frame(center,target,0)
receiver=add(center,add(add(mul(r,.15),mul(u,-.12)),mul(n,.6)))
nr=unit(add(add(r,mul(u,.35)),mul(n,.18)))
original=clipped_transcription(center,r,u,width,height,receiver,nr)
r90,u90,n90=frame(center,target,127)
equivalent=clipped_transcription(center,r90,u90,height,width,receiver,nr)

# Independent direct world-space cosine integral on analytic y slices.
# Here (sourcePoint - receiver) dot nr > 0 iff x + .35*y > .216.
# Simpson integration uses that domain directly, not clipping, a triangle fan,
# barycentric incidence, or the depth*incidence formula under examination.
N=160
def weight(i): return 1 if i in (0,N) else (4 if i%2 else 2)
dy=height/N; integral=0.
for j in range(N+1):
    y=-height/2+j*dy; xmin=.216-.35*y; dx=(width/2-xmin)/N; row=0.
    for i in range(N+1):
        x=xmin+i*dx; sourcepoint=add(center,add(mul(r,x),mul(u,y)))
        ray=sub(receiver,sourcepoint); distance=norm(ray); ray=mul(ray,1/distance)
        value=max(0,dot(n,ray))*max(0,-dot(nr,ray))/distance**2
        row+=weight(i)*value
    integral+=weight(j)*row*dx/3
reference=1000/(width*height)*integral*dy/3
# Rodrigues is an independently expressed rotation of zero-roll right about n.
a=math.radians(roll)
rodrigues=add(add(mul(r0,math.cos(a)),mul(cross(n,r0),math.sin(a))),mul(n,dot(n,r0)*(1-math.cos(a))))
results={
  'executed':'Python transcription and independent reference only; Swift not executed',
  'input':{'center':center,'target':target,'width':width,'height':height,'onAxisCandela':1000,'roll':roll,'receiver':receiver,'receiverNormal':nr},
  'frame':{'norms':[norm(r),norm(u),norm(n)],'pairwise_dots':[dot(r,u),dot(r,n),dot(u,n)],'right_cross_up_dot_normal':dot(cross(r,u),n),'positive_roll_rodrigues_max_error':max(map(abs,sub(r,rodrigues))),'physical_rectangle_area':norm(cross(mul(r,width),mul(u,height))),'nominal_rectangle_area':width*height},
  'original':original,'equivalent_roll_127_swapped_sides':equivalent,
  'independent_simpson_lux':reference,
  'transcription_relative_error':abs(original['lux']-reference)/reference,
  'equivalent_rectangle_relative_delta':abs(original['lux']-equivalent['lux'])/reference,
  'independent_clipped_area':(.6-.216)*.6,
}
assert max(abs(v) for v in results['frame']['pairwise_dots'])<1e-14
assert abs(results['frame']['right_cross_up_dot_normal']-1)<1e-14
assert results['frame']['positive_roll_rodrigues_max_error']<1e-14
assert abs(original['clipped_world_area']-results['independent_clipped_area'])<1e-14
assert results['transcription_relative_error']<1e-6
assert results['equivalent_rectangle_relative_delta']<1e-8
print(json.dumps(results,indent=2))
