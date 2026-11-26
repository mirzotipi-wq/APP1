# Spatial geometry comparisons

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Latest source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`.

Native receipts are source-specific: 68c83 passed 171 methods, 9725 passed 176, and 4e694bc passed 184. The latest source adds the outward-Float projection regression and passed all 185 native / 39 spatial methods. See validation/NATIVE-60059a0.md for exact accounting and runtime limits.

## Authored and represented equipment

| Contract | SceneKit | RealityKit | Evidence and limit |
|---|---|---|---|
| Right-handed meters | Authored XYZ, no axis swap | Same | Core contract preserved; no Core source edits. |
| Point source position | Sphere and omni source centered at authored position | Sphere at lamp root | Native point-center test passed; RealityKit source review. |
| Aimed emitter front | Box center shifted behind authored front by half its depth | Face center z = −0.003 m, depth 0.006 m, front z = 0 | Native front-plane/source-origin checks include translated positions near (80, 2.1, 75). |
| Forward and roll | Complete Core right/up/+Z basis; native spotlight flips right and normal for −Z emission | Complete Core basis; emission child rotates π about Y | Native axis checks and independent cardinal/roll scalar comparisons. |
| Rectangle dimensions | Authored outer SCNBox width and height | Full authored face width and height | Native 1.2 × 0.7 m, rolls 37.5°, 90°, −125° and vertical aims passed; RealityKit correction is source/scalar evidence. |
| Undefined aim | Selectable world-aligned housing, no SCNLight | World-aligned housing, hidden face/source/aim markers | Native initial and recovery transitions passed at 4e694bc. |
| Authored camera | Body at authored position, lens on local −Z, Core target/up/lens | Body/lens −Z with the same Core framing | Native vertical camera and local lens test passed; RealityKit runtime unverified. |
| Stand | Positive-height fixture to world floor; detached below threshold | Stem plus floor cross base | Native identity, hit ownership and threshold transition passed. |

Native transform comparisons use 2e−5 m position tolerance for Float world transforms and 1e−6 axis/dimension tolerance. No acceptance threshold was changed. The two existing SpatialPreview assertions now use the represented bounds instead of Core-only bounds, with their original tolerances retained. Illustrative shading is not photometric calibration.

SceneKit's cosmetic chamfer supports the authored outer envelope and center front-plane anchor. It does not prove that every tessellated flat-face corner matches an ideal sharp Core rectangle.

## Reproduced Fit omission

The baseline witness places subject at (0, 2, −0.1), camera at (0, 2, 0.1), and a 4 × 4 m rectangle at (0, 2, 0) with coincident manual aim. Core intentionally excludes the undefined emitting face; the native housing is still displayed.

Two independent wave-01 workers calculated housing samples outside the old 360 × 280 viewport: SceneKit NDC (2.188813, 2.555797), RealityKit NDC (1.625761, 3.009950). These were mathematical projections, not native captures.

The App helper starts with validated Core bounds and adds:

| Representation | Additional envelope |
|---|---|
| Bust | x/z ±0.36 m; below 0.96 m and above 0.24 m |
| Camera body and lens | ±0.24 m in every world axis, conservatively covering orientation |
| Point fixture | ±0.12 m |
| Aimed housing and outline | Half authored/schematic width and height plus 0.03 m; local z from −0.15 to 0.08 m, transformed by Core basis or identity for undefined aim |
| Positive-height stand base | x/z ±0.24 m at world y = 0…0.028 m |
| Defined aim target | Sphere radius 0.0275 m, shared with the RealityKit marker |

The floor/grid are intentionally excluded. Floor-anchored stands make vertical translation different from horizontal translation; they remain at world y = 0. Core and Plan bounds semantics are unchanged.

## Fit and navigation projection

Fit uses the enclosing sphere and distance `max(0.8, radius) / sin(24°) × 1.12`. The smaller viewport axis retains a 48° field of view. SceneKit selects horizontal projection for a tall viewport and vertical projection for a wide viewport without resetting orbit.

RealityKit keeps Double state until native upload. Orbit pitch is bounded, pan remains in the camera plane with a target clamp of ±300 m, and distance is limited to 0.45…1500 m. Its far distance is orbit distance + 750 m, covering the bounded relative diagonal of target and authored world. That proof does not constrain SceneKit's separate free-camera controller.

Native tests exercise actual SceneKit projections for translated rigs, coincident large modifiers and high stands. They check 26 projected points across their declared cases, not 26 different layouts or every mesh vertex. The wave-08 portable witness checks 15 scenes, 760 primitive instances and 240 modeled frustum cases per projection model with no modeled failures. Its minimum plane clearance is 0.321782484 m. The ideal fitted sphere subtends at most 21.294250°, within the 24° half-angle.

Those portable calculations model geometry and Float angle quantization. They do not execute native quaternion conversion, camera-matrix construction, Float trigonometry, tessellation, culling or rasterization.

## Corrected rectangle face

Core rectangle width and height describe the emitting face, excluding housing. The old RealityKit face subtracted 0.012 m from each full dimension, producing a 6 mm inset at every edge.

| Authored rectangle | Old represented face | Area difference |
|---|---|---:|
| 1.2 × 0.7 m = 0.84 m² | 1.188 × 0.688 m = 0.817344 m² | 2.697% smaller |
| 0.05 × 0.05 m = 0.0025 m² | 0.038 × 0.038 m = 0.001444 m² | 42.24% smaller |

The rectangle face now scales the shared unit box directly by authored width and height. Its front remains at local z = 0. Directional schematic styling retains its inset. These comparisons establish source geometry, not a measured RealityKit raster or emission-energy change.

## Corrected Float projection boundary

Wave 08 found a source/scalar counterexample at an extreme subpixel viewport of 0.0001 × 3000. An ideal vertical field of view near 179.99999142° rounded down to Float 179.999984741°. The resulting horizontal half-angle was about 14.054°, narrower than Fit's 24°. In the test rig, the camera-marker center reached 20.535° and therefore fell outside that mathematical frustum.

The current source selects the smallest representable Float angle at least as wide as the ideal angle, advancing by one ULP only when nearest rounding narrowed it. If that enclosing value reaches 180°, the projection is rejected. Accepted parameters retain at least the intended smaller-axis angle.

One focused state regression covers six accepted and two rejected layouts, including practical layouts and already-outward/nextUp controls. The independent reviewer reproduced the old failure and approved the exact two-file patch. Prior tests used the ideal Double angle and missed this final conversion. This is not an observed ordinary narrow-layout or RealityKit runtime failure.

Private commit `a92b4fdc5bb8d3af75b3557949477a730462e000` and preserved GitHub commit `a69f6252e85123ae34e7ef7336fb12794529c80b` have the same tree. Source60059 includes that correction. See `validation/float-projection-review/` and `workers/w08/`.

## State and lifetime comparison

Metadata, output, pose, roll and valid selection edits retain continuing equipment nodes. Only kind or rectangle dimension changes replace shape resources. Deleted/invalid scene lifetimes discard equipment and hit maps; ancestry and live-UUID checks reject retained old hits even after UUID reuse.

Native tests at 4e694bc passed unchanged-scene callback replacement/clearing, deletion/invalidation lifetime, pending Camera-to-Orbit recovery and translated coincident-to-vertical emitter recovery. The latter uses fixed cardinal expectations independently of EmitterFrame and checks retained geometry and selection.

Parent SwiftUI identity remains a composition dependency. Lane 01 has implemented the requested presentation identity at pinned source5ccfbaae, but lane 05 has not merged it. See `OWNER_REQUESTS.md`; an adapter cannot retain a coordinator destroyed by its parent.
