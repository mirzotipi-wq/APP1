# Spatial geometry comparisons

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Native receipts are source-specific:68c83 passed171 methods,9725fb1 passed176, and4e694bc passed184. Evidence below identifies its checkpoint; a subsequent Float-boundary correction requires its own execution.

## Authored and represented equipment

| Contract | SceneKit representation | RealityKit representation | Evidence and limit |
|---|---|---|---|
| Right-handed world in meters | Authored XYZ uploaded without axis swap | Same XYZ uploaded without axis swap | Core frame/unit contract preserved; no Core source edits |
| Point source position | Sphere center and omni source at authored position | Sphere at lamp root | Native point-center test passed at 68c83; RealityKit source review only |
| Aimed emitter front | Box center offset behind authored front by half its depth | Housing behind face; face center local z=-0.003 with depth0.006, so front is z=0 | Native front-plane and source-origin tests passed, including translated positions near (80,2.1,75) |
| Emitter forward and roll | Fixture basis uses core right/up/+Z; spotlight flips right and normal to emit along -Z | Fixture basis uses core frame; emission child rotates pi about Y | Native axis comparisons use 1e-6 tolerance; independent cardinal/roll scalar witnesses are portable evidence |
| Rectangle width/height | SCNBox width/height in authored meters | Scaled shared box face/housing in meters | Native 1.2x0.7m dimensions, roll37.5/90/-125 degrees and vertical aims passed |
| Undefined aim | Selectable world-aligned housing; no SCNLight | World-aligned housing; hidden face, source and aim markers | Native degenerate initial-state test passed; the recovery-transition test passed at4e694bc |
| Authored camera | Body at authored position, lens on local -Z; CameraFraming supplies target/up/lens | Body/lens local -Z and same CameraFraming | Native vertical camera and local-negative-Z lens test passed; RealityKit execution unavailable |
| Stand | Extends from positive-height fixture toward world floor; absent at/below threshold | Stand plus cross base at world floor | Native identity/selection tests passed; threshold-transition test passed at 9725fb1 |

Native transform comparisons allow 2e-5m positional error for Float32 world transforms and 1e-6 axis/dimension error. These are existing test tolerances, not altered acceptance thresholds. Native shading remains illustrative and is not a candela/area-source calibration.

## Fit defect and correction

The reproduced baseline rig places subject at (0,2,-0.1), camera at (0,2,0.1), and a 4x4m rectangular emitter at (0,2,0) with a coincident manual aim. Core bounds intentionally exclude an undefined emitting face. The visual housing still exists.

Two independent wave01 workers calculated housing samples outside the old viewport at 360x280: SceneKit NDC(2.188813,2.555797), RealityKit NDC(1.625761,3.009950). These were mathematical projections, not native captures.

SpatialViewportBounds extends the validated core bounds with the actual display envelopes: bust, camera body/lens, fixture housings and outlines, world-floor stand bases, and the 0.0275m aim-target marker. It excludes the floor/grid. Keeping this helper in App preserves lane06/Plan bounds semantics.

The fitted orbit uses a bounding sphere and a48-degree field of view on the smaller viewport axis, with12percent distance margin. SceneKit changes its projection axis on resize; RealityKit derives vertical field of view from the aspect ratio and rejects values that round to180 degrees as Float. The RealityKit navigation state keeps Double calculations until native upload, clamps distance to0.45...1500m and target to±300m, and uses far distance equal to orbit distance+750m. SceneKit native camera-controller navigation is a separate path; these RK clamps do not constrain its gestures.

The first native checkpoint passed actual SceneKit narrow-layout projection tests for high stands and coincident4m modifiers. The additional aim-marker/clipping methods passed in the 176-method native execution at 9725fb1. Pure projection witnesses do not establish native gesture delivery, RealityKit rendering or frame-rate behavior.

## Stable updates and selection

Metadata, output, position, roll and valid selection updates preserve continuing equipment nodes. Modifier kind or rectangle dimensions may replace shape resources while keeping the UUID-owned nodes. Deleted, invalid or replaced scene lifetimes discard equipment nodes and their hit maps. Hit resolution also checks current parent ownership and visibility, so a retained old node cannot select a reintroduced UUID.

The new SpatialEntityUpdateTests exercise point/directional/rectangle transitions, independent rectangle-axis resizing, and stand detach/reattach. New selection-lifetime and emitter-recovery regressions now cover the unchanged-scene callback boundary and degenerate-aim recovery; they passed natively at4e694bc. Parent SwiftUI identity is owned by lane01: recreating the wrapper still recreates its coordinator, so viewport preservation across first save requires the documented composition change.

See validation/NATIVE-68c83.md, captures/receipt-68c83.json and the worker ledgers for exact source and execution provenance.

## Wave06 correction and evidence precision

Core rectangle dimensions describe emitting-face corners and explicitly exclude the housing. The RealityKit face had subtracted0.012m from each full dimension, leaving a0.006m inset at each edge. A1.2x0.7m authored face was drawn1.188x0.688m (0.817344m² instead of0.84m²,2.697percent smaller). Avalid0.05x0.05m face was42.24percent smaller. The rectangle-only correction uses authored width and height directly on the centered1m unit box. Its front remains localz=0; directional schematic styling retains its previous inset. These are scalar/source comparisons, not an observed RealityKit rendering or photometric-output measurement.

SceneKit's chamfered box supports the authored outer width/height envelope, the center front-plane anchor and the core axis basis. Its cosmetic bevel means this is not proof that tessellated flat-face corner vertices exactly match an ideal sharp Core rectangle. Bounds are conservative display envelopes. No Core geometry or acceptance tolerance changes were made.

The new translated emitter-recovery regression checks fixed cardinal axes independent of EmitterFrame, retained nodes/shape/selection, suppressed light at coincident aim, and restored source after a vertical rolled aim. Existing tests already cover undefined-camera-to-vertical-pose/lens recovery, so another camera method was not added.

The9725 checkpoint now has actual176/176 native passes, including all30 spatial methods. Its captures and exact receipt are in validation/NATIVE-9725fb1.md. The later recovery/selection/emitter methods subsequently passed at4e694bc:184/184 native methods,38/38spatial. See validation/NATIVE-4e694bc.md.

## Outward Float projection boundary

Wave08 independently found a source/scalar counterexample at a subpixel0.0001×3000viewport. An ideal vertical field of view near179.99999142degrees rounded down to Float179.999984741degrees; the resulting derived horizontal half-angle was about14.05degrees, below the24degrees used by Fit. This was not an ordinary narrow-layout or observed RealityKit failure.

The reviewed two-file candidate rounds the native vertical angle outward by at most one Float ULP and rejects it if the enclosing representable angle reaches180degrees. Accepted projections therefore retain at least the intended smaller-axis angle at the parameter boundary. An independent scalar check covers six accepted and two rejected cases, including already-outward and nextUp controls. One new native-state regression explicitly checks the uploaded Float projection. Existing tests had projected with the ideal Double angle and missed this final conversion boundary. The candidate is preserved at a69f6252e85123ae34e7ef7336fb12794529c80b, with the same tree as private a92b4fdc;185native/39spatial is inventory, not yet execution. No Core, SceneKit camera-lens, gesture or selection policy changes.
