#!/usr/bin/env python3
"""Copied Python binary64 arithmetic, not execution of Swift or the renderer.
Run: python W50-arithmetic-review.py
Witness checks reproduce numerical boundaries; they are not candidate test passes.
"""
import sys, math, struct, json, platform, hashlib
from pathlib import Path
from itertools import permutations
Q = math.ulp(0.0)
N = sys.float_info.min
checks = []
def check(name, condition):
    checks.append({'name': name, 'witness_or_model_check_satisfied': bool(condition)})
def dot(a,b): return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]
def normalize(a, stable=False):
    length = math.hypot(*a) if stable else math.sqrt(dot(a,a))
    return tuple(x/length for x in a) if math.isfinite(length) and length > 0 else None
def material(n,l,v,nl,stable=False):
    nv=max(0.0,dot(n,v))
    h=normalize(tuple(l[i]+v[i] for i in range(3)),stable)
    if nv<=0 or h is None: return 0.0, None
    nh=min(1.0,max(0.0,dot(n,h)))
    vh=min(1.0,max(0.0,dot(v,h)))
    alpha=.05*.05
    a2=alpha*alpha
    d=nh*nh*(a2-1)+1
    distribution=a2/(d*d)
    denominator=2*(nl*math.sqrt(nv*nv*(1-a2)+a2)+nv*math.sqrt(nl*nl*(1-a2)+a2))
    fresnel=.08+(1-.08)*pow(1-vh,5)
    response=distribution*fresnel/denominator if denominator>0 else 0.0
    return response, {'nl':nl,'nv':nv,'denominator':denominator,'distribution':distribution,'fresnel':fresnel}
def prepare(c,count):
    scale=c if c/count<N else 1.0
    return (c if scale==1 else 1.0)/count,scale
def point(c,position,n,v,stable=False):
    r2=dot(position,position)
    wi=tuple(a/math.sqrt(r2) for a in position)
    nl=min(1.0,max(0.0,dot(n,wi)))
    base,scale=prepare(c,1)
    lux=base*1.0*nl/r2
    response,parts=material(n,wi,v,nl,stable)
    signal=lux*response/1000
    return {'output_scale':scale,'unit_lux':lux,'response':response,
            'lux':lux*scale,'signal_y':signal*scale,'material_parts':parts}
threshold=[]
for c in [math.nextafter(N,0),N]:
    base,scale=prepare(c,1)
    old=c*1.0*1e-17/.0036
    candidate=(base*1.0*1e-17/.0036)*scale
    late=(1.0*1.0*1e-17/.0036)*c
    threshold.append({'candela':c,'candela_hex':c.hex(),'trigger':scale!=1,'old':old,'candidate':candidate,'late':late})
check('below_threshold_intensity_loss_repaired',threshold[0]['old']==0 and threshold[0]['candidate']>0)
check('at_threshold_loss_outside_trigger',threshold[1]['candidate']==0 and threshold[1]['late']>0)

# Public-input-shaped mirrored directions: their normalization remains finite,
# but the half-vector (2e-170,0,0) has squared norm rounded to zero.
s=1e-170
n=normalize((1.0,0.0,s));v=normalize((2*s,0.0,-1.0))
mirror=point(Q,(0.0,0.0,.06),n,v)
mirror_stable=point(Q,(0.0,0.0,.06),n,v,True)
check('triggered_half_vector_underflow_witness',mirror['output_scale']!=1 and mirror['signal_y']==0 and math.isfinite(mirror_stable['response']) and mirror_stable['signal_y']>0)

# Finite geometric directions with tiny positive N dot L and N dot V. The
# standalone response can overflow even though the cancelled product is finite.
s=1e-320
n=(0.0,0.0,1.0);v=normalize((1.0,0.0,s))
overflow=point(N/2,(.06,0.0,.06*s),n,v)
parts=overflow['material_parts']
cancelled=(overflow['unit_lux']/parts['denominator'])*(parts['distribution']*parts['fresnel'])/1000*(N/2)
check('triggered_separate_response_overflow_witness',math.isinf(overflow['response']) and math.isinf(overflow['signal_y']) and math.isfinite(cancelled) and cancelled>0)

packing=[]
for count in [1,64,1024]:
    for c in [Q,16*Q,N/2,math.nextafter(N,0),N,32*N,64*N,1024*N,math.nextafter(count*N,0),count*N,1.0,100000.0]:
        base,scale=prepare(c,count)
        packed=struct.pack('f',base*scale)
        old=struct.pack('f',c/count)
        check('packing_count_%d_c_%s'%(count,c.hex()),packed==old)
        packing.append({'count':count,'candela_hex':c.hex(),'trigger':scale!=1,'old_double':c/count,'new_double':base*scale,'same_float32_bits':packed==old,'float32':struct.unpack('f',packed)[0]})

# Explicit state-only translation of the while/defer mechanism. Events are
# supplied scalars; this does not execute clipping, visibility, or Swift defer.
def add(a,b):return tuple(x+y for x,y in zip(a,b))
def mul(a,s):return tuple(x*s for x in a)
def state_model(groups):
    acc=(0.0,)*5
    for name,scale,events in groups:
        prior=acc
        if scale!=1:acc=(0.0,)*5
        try:
            for e in events:
                if e=='throw':raise ValueError('invalidSurface')
                acc=add(acc,e)
        finally:
            if scale!=1:acc=add(prior,mul(acc,scale))
    return acc
permutation_count=0
for ordinary in [1.0,N]:
    groups=[('ordinary',1.0,[(ordinary,ordinary,ordinary/1000,ordinary/1000,ordinary/1000)]),
      ('tiny_point',Q,[(277.777,277.777,4e6,4e6,4e6)]),
      ('tiny_occluded',N/2,[(200.,0.,0.,0.,0.)]),
      ('tiny_backface',16*Q,[]),
      ('tiny_clipped_area',32*N,[(1.,.5,.001,.001,.001)]*64)]
    for order in permutations(groups):
        expected=(0.0,)*5
        for group in order:expected=add(expected,state_model([group]))
        actual=state_model(order)
        permutation_count+=1
        check('group_permutation_%d'%permutation_count,actual==expected and actual[1]<=actual[0])
try:
    state_model([('ordinary',1,[(1.,1.,1.,1.,1.)]),('tiny_invalid',Q,[(200.,200.,1.,1.,1.),'throw'])])
    propagated=False
except ValueError as e:
    propagated=str(e)=='invalidSurface'
check('invalid_surface_propagates_through_finally_model',propagated)

# Positive weighting after the trigger boundary remains a separate failure mode.
weighted={'per_cell':N,'weight':1e-17,'r2':.0036}
weighted['early']=N*weighted['weight']/weighted['r2']
weighted['late']=N*(weighted['weight']/weighted['r2'])
check('outside_trigger_positive_weight_loss',weighted['early']==0 and weighted['late']>0)

def clean(o):
    if isinstance(o,float) and not math.isfinite(o):return repr(o)
    if isinstance(o,dict):return {k:clean(v) for k,v in o.items()}
    if isinstance(o,(list,tuple)):return [clean(v) for v in o]
    return o
root=Path(__file__).resolve().parent
hashes={n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in ['W44-implementation.patch','W44-ReferenceStudy.swift','W44-StudyTinyOutputTests.swift']}
result={'execution_kind':'copied Python arithmetic and scalar state model; NOT actual Swift, XCTest, renderer, clipping, or visibility execution',
 'python':sys.version,'platform':platform.platform(),'base':'c9ff1a71c173774e7b7c794e475f8bdf5d633853','candidate_sha256':hashes,
 'checks':len(checks),'checks_unsatisfied':sum(not c['witness_or_model_check_satisfied'] for c in checks),
 'threshold':threshold,'half_vector_underflow':{'directions':{'normal':(1.,0.,1e-170),'view':(2e-170,0.,-1.),'point':(0.,0.,.06)},'candidate_arithmetic':mirror,'stable_half_vector_arithmetic':mirror_stable},
 'response_overflow':{'candidate_arithmetic':overflow,'finite_reassociated_product':cancelled},
 'positive_weight_loss_scalar_only':weighted,'packing_cases':packing,'state_permutations':permutation_count,'individual_checks':checks}
print(json.dumps(clean(result),indent=2,allow_nan=False))
raise SystemExit(0 if result['checks_unsatisfied']==0 else 1)
