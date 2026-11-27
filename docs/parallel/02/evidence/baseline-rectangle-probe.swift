import Foundation
import LightingCore
let n=UnitDirection(x:0,y:0,z:1)!
for c in [1e-321,1e-320,1e-310,1.0] {
 let e=LambertianRectangle(center:.init(x:0,y:0,z:0.05),right:UnitDirection(x:1,y:0,z:0)!,up:UnitDirection(x:0,y:-1,z:0)!,widthMeters:0.05,heightMeters:0.05,onAxisCandela:c)!
 let lux=Photometry.rectangularIlluminance(emitter:e,receiver:.init(x:0,y:0,z:0),receiverNormal:n)!
 let d=0.05,a=0.025, da=sqrt(d*d+a*a)
 let coefficient=4/(0.05*0.05)*a/da*atan(a/da)
 print(c,lux,coefficient*c,abs(lux/(coefficient*c)-1))
}
