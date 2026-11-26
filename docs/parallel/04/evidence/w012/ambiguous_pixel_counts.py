#!/usr/bin/env python3
"""Focused analytic screen counts; not renderer or GPU execution."""
import json
import math
from pathlib import Path
ROOT=Path('/tmp/keyfill04-2987b1ee980d/results/w012')
EPS=2.0**-23
cases=[
 ('portrait',3.0,50.0,'active lights; existing eligible'),
 ('hard',math.hypot(2.3,.16),85.0,'active point lights; existing eligible'),
 ('soft',math.hypot(2.3,.16),85.0,'active area lights; existing eligible'),
 ('warm-rotated',math.sqrt(.8**2+.3**2+2.3**2),85.0,'active area/directional lights; existing eligible'),
 ('dark',math.hypot(2.3,.16),85.0,'no lights; existing eligible'),
 ('near-field',math.hypot(2.3,.16),85.0,'active near-source point; existing near-field guard rejects'),
 ('translated',math.hypot(2.3,.16),85.0,'active area lights; existing eligible; ideal translated distance'),
]
def count(width,d,f,multiplier):
    h=width*2//3
    margin=multiplier*EPS*d
    n=0
    for y in range(h):
        py=(1-2*(y+.5)/h)*(12/f)
        for x in range(width):
            px=(2*(x+.5)/width-1)*(18/f)
            q=px*px+py*py
            rho=d*math.sqrt(q/(1+q))
            n+=abs(rho-.22)<=margin
    return n
rows=[]
for name,d,f,note in cases:
    for w in (48,192):
        n32=count(w,d,f,32)
        n64=count(w,d,f,64)
        pixels=w*w*2//3
        rows.append(dict(scene=name,width=w,height=w*2//3,pixels=pixels,note=note,
         ambiguous_32=n32,ambiguous_64=n64,ambiguous_fraction_64=n64/pixels,
         maximum_mean_rgb_contribution_64_if_any_255=n64*255/pixels))
# Exact reported no-light scene, separately labeled; blanket shell can catch more
# pixels than actual shared-Float-vs-Double classification disagreements.
rows.append(dict(scene='confirmed-no-light',width=24,height=16,pixels=384,
 note='no lights; baseline observed two mismatches, not all shell pixels',
 ambiguous_32=count(24,3,161.27198111190464,32),ambiguous_64=count(24,3,161.27198111190464,64)))
result=dict(run_id='w012-ambiguous-counts-002',execution='Python analytic Double screen only',rows=rows)
(ROOT/'ambiguous_pixel_counts.json').write_text(json.dumps(result,indent=2)+'\n')
for row in rows:
 print(row['scene'],row['width'],'pixels',row['pixels'],'ambiguous32',row['ambiguous_32'],'ambiguous64',row['ambiguous_64'])
print('RUN w012-ambiguous-counts-002')
