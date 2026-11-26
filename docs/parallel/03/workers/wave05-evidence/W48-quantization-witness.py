# Python binary64/Float32 quantization witness; not a Swift renderer execution.
import json, math, platform, struct, sys
from pathlib import Path

def matrix(m,v): return tuple(sum(a*b for a,b in zip(row,v)) for row in m)
B=((.8951,.2664,-.1614),(-.7502,1.7135,.0367),(.0389,-.0685,1.0296))
BI=((.9869929,-.1470543,.1599627),(.4323053,.5183603,.0492912),(-.0085287,.0400428,.9684867))
RGB=((3.24096994,-1.53738318,-.49861076),(-.96924364,1.87596750,.04155506),(.05563008,-.20397696,1.05697151))
def blackbody(k):
    total=[0.,0.,0.]
    for nm in range(380,781,5):
        def lobe(c,l,r):
            t=(nm-c)*(l if nm<c else r)
            return math.exp(-.5*t*t)
        matching=(max(0,1.056*lobe(599.8,.0264,.0323)+.362*lobe(442.,.0624,.0374)-.065*lobe(501.1,.049,.0382)),
                  max(0,.821*lobe(568.8,.0213,.0247)+.286*lobe(530.9,.0613,.0322)),
                  max(0,1.217*lobe(437.,.0845,.0278)+.681*lobe(459.,.0385,.0725)))
        spectrum=(560/nm)**5/math.expm1(1.438776877e7/(nm*k))
        weight=.5 if nm in (380,780) else 1.
        total=[a+b*(spectrum*weight) for a,b in zip(total,matching)]
    return tuple(x/total[1] for x in total)
def display(xyz):
    white=blackbody(5600.)
    d65=(.3127/.3290,1.,(1-.3127-.3290)/.3290)
    ratio=tuple(a/b for a,b in zip(matrix(B,d65),matrix(B,white)))
    adapted=matrix(BI,tuple(a*b for a,b in zip(matrix(B,xyz),ratio)))
    rgb=matrix(RGB,adapted)
    assert all(math.isfinite(x) for x in rgb) and adapted[1]>=0
    if adapted[1]==0: return (0.,0.,0.)
    luminance=adapted[1]/(1+adapted[1]); tone=tuple(x/(1+adapted[1]) for x in rgb); t=1.
    for component in tone:
        delta=component-luminance
        if delta>0: t=min(t,(1-luminance)/delta)
        if delta<0: t=min(t,-luminance/delta)
    values=[]
    for component in tone:
        linear=min(1.,max(0.,luminance+t*(component-luminance)))
        values.append(12.92*linear if linear<=.0031308 else 1.055*linear**(1/2.4)-.055)
    return tuple(values)
quantum=float.fromhex('0x0.0000000000001p-1022')
color=blackbody(5600.)
cosine=.1; a2=.05**4; fresnel=.08+.92*(1-cosine)**5
response=fresnel/(a2*4*cosine*math.sqrt(cosine*cosine*(1-a2)+a2))
rows=[]; checks=[]
for kind,emission in [('point',1.),('directional',.5)]:
    for intensity in (quantum,sys.float_info.min/2):
        unit_y=(emission*cosine/(.06*.06))*response/1000
        xyz=tuple((v*unit_y)*intensity for v in color)
        encoded=display(xyz)
        bytes_rgb=[math.floor(min(1.,max(0.,v))*255+.5) for v in encoded]
        packed=struct.unpack('f',struct.pack('f',intensity))[0]
        values={'kind':kind,'intensity_hex':intensity.hex(),'signal_xyz':xyz,'display_rgb':encoded,'rgb8':bytes_rgb,'packed_candela_float32':packed}
        rows.append(values)
        checks += [all(math.isfinite(x) and x>0 for x in xyz),packed==0,bytes_rgb==[0,0,0]]
result={'scope':'Python arithmetic transcribed from finite analytic W44 grazing example and existing Colorimetry transform; not actual Swift/Metal/UI execution','host':platform.platform(),'python':sys.version,'checks':len(checks),'failed_checks':sum(not x for x in checks),'rows':rows}
assert all(checks),result
path=Path(sys.argv[1]); path.write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'checks':len(checks),'failed_checks':sum(not x for x in checks),'rows':rows},indent=2))
