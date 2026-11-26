import LightingCore
let scales = [Double.leastNonzeroMagnitude, 1e-320, 1.0, 1e300, Double.greatestFiniteMagnitude]
for x in scales {
 let xyz = RelativeXYZ(x:x,y:x,z:x)
 print(x, String(describing:xyz.chromaticity), String(describing:PreviewColorimetry.display(xyz,settings:.init(exposureStops:6))))
}
