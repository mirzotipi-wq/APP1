# Wave 08 geometry and projection witness

Frozen input: `4e694bc377c4825d1d2dd52fcd7900e534c75072`.
Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
This is portable source review and standard-library arithmetic, not native rendering or Swift test execution.

## Independent displayed-primitive oracle

`portable_geometry_witness.py` derives its oracle from the primitive sizes and transforms in `SpatialPreview.swift` and `StudioEntityGraph.swift`. A separate helper transcription supplies the tested envelope. Ellipsoid, capsule, cylinder and box support functions check complete continuous volumes against each AABB/frustum half-space. Sharp boxes conservatively enclose the chamfered SceneKit boxes. Including all selection outlines simultaneously conservatively covers every actual single-light selection.

| Display geometry | Derived envelope or argument |
| --- | --- |
| SceneKit bust | Head radius 0.19 m; capsule radius 0.23 m, total height 0.76 m, scale (1.2,1,0.65), center subject−0.55Y. Lowest point −0.93Y; horizontal semiaxes 0.276/0.1495 m. |
| RealityKit bust | Sphere radius 0.5 times the head/neck/torso/nose scales. Torso reaches −0.95Y; head reaches +0.215Y; horizontal yaw preserves the torso's maximum horizontal radius 0.29 m. Nose offset plus its maximum radius is 0.1925 m. All fit subject X/Z±0.36, Y−0.96/+0.24. |
| Camera marker | Both body/lens combinations lie within a radius below 0.19 m about the authored camera for every rigid orientation; helper radius is 0.24 m on each axis. |
| SceneKit fixture and selection | Box width/height increase by 0.04 m total. Directional selection Z is [−0.1339,+0.0039] when aimed, or ±0.0689 when coincident. Rectangles are thinner. Helper uses width/height half-size+0.03 and Z[−0.15,+0.08]. |
| RealityKit fixture and selection | Housing Z[−0.086,−0.006], face Z[−0.006,0]. Twelve edges each have 0.009 m thickness: extrema are width/height half-size+0.0245 and Z[−0.1075,+0.0215]. Point outline extends to 0.1145 m, inside helper±0.12. |
| Aim geometry | Square cross-section 0.005×0.005 m is enclosed by a tube of radius √2×0.0025 m. Source helper contains a ball of radius at least 0.055 m; target box contains a ball of radius 0.0275 m. Convexity encloses every tube section between endpoints. |
| Stands | SceneKit cylinder radius 0.015 m; RealityKit post 0.024 m square, both from world Y=0 to the light. Feet are 0.45×0.025×0.035 m and its X/Z swap at Y=0.014. Helper foot box X/Z±0.24 and Y[0,0.028] plus the fixture bounds enclose them. Vertical scene translation deliberately changes stand height. |

Floor and grid are excluded by the intended Fit contract. The aim cylinder is a conservative bound, not a claim about the native quaternion's precise twist.

## Ideal Fit argument and bounded checks

With validated center coordinates in [−100,100] and modifier dimensions ≤4 m, the largest helper local corner radius is √(2.03²+2.03²+0.15²). Therefore a conservative global envelope radius is ≤178.184328 m. Fit distance is at most 490.652737 m, so the 1,500 m upper clamp cannot activate for this ideal domain.

For envelope radius R and D=1.12×max(0.8,R)/sin(24°), its circumscribed sphere has angular radius asin(R/D)≤21.294250°. Both viewport half-angles are at least 24° in the ideal projection. The nearest possible depth D−R≥1.402899 m exceeds 0.02 m; R<750 m supplies far-plane clearance. This argument covers arbitrary camera directions around the same center and distance under orthonormal ideal transforms. It does not cover intentional pan/zoom or native numerical behavior.

The bounded fixture matrix contains 15 scenes and 760 displayed primitive instances; four viewport sizes and four orbit poses give 240 whole-shape frustum checks per projection model. All envelope checks pass (maximum excess 0); both ideal and Float-angle-only practical models have minimum plane clearance 0.321782484 m. The JSON records every scene, dimensions, orbit angles, source hash and result.

## Original counterexample and separate candidate

At width 0.0001, height 3000, empty scene subject (−100,1.5,0), camera (100,1.5,0), the original helper accepts Double vertical FOV 179.99999142077152°. Upload rounds to Float 179.99998474121094°, yielding horizontal half-angle 14.053987907538744°. The authored camera marker center is at 20.534834507590055° and normalized X=1.4963415439584467. This is an extreme subpixel arithmetic counterexample, not an observed native frame.

Candidate `a92b4fdc5bb8d3af75b3557949477a730462e000` rounds a downward nearest Float up by one ULP, rejects an enclosing angle of 180°, and returns that exactly representable angle as Double. The counterexample is rejected. Accepted 0.0003×3000 and 0.0002×3000 controls preserve at least the ideal smaller-axis angle. The single new native test covers six accepted and two rejected layouts but was not executed here.

Float-angle-only projection retains ideal geometry and camera bases. Native matrix construction, Float trigonometry, quaternion conversion, mesh generation, rasterization and gestures remain outside this witness. Original 4e native outcomes cannot validate this changed candidate.

