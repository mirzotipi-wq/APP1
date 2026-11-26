# Spatial geometry comparisons

Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Current published source checkpoint: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`. Native evidence below belongs specifically to `68c83cca75f9ef8fd41fe6a33358b00e0790c45a` unless stated otherwise.

## Authored and represented equipment

| Contract | SceneKit representation | RealityKit representation | Evidence and limit |
|---|---|---|---|
| Right-handed world in meters | Authored XYZ uploaded without axis swap | Same XYZ uploaded without axis swap | Core frame/unit contract preserved; no Core source edits |
| Point source position | Sphere center and omni source at authored position | Sphere at lamp root | Native point-center test passed at 68c83; RealityKit source review only |
| Aimed emitter front | Box center offset behind authored front by half its depth | Housing behind face; face center local z=-0.003 with depth0.006, so front is z=0 | Native front-plane and source-origin tests passed, including translated positions near (80,2.1,75) |
| Emitter forward and roll | Fixture basis uses core right/up/+Z; spotlight flips right and normal to emit along -Z | Fixture basis uses core frame; emission child rotates pi about Y | Native axis comparisons use 1e-6 tolerance; independent cardinal/roll scalar witnesses are portable evidence |
| Rectangle width/height | SCNBox width/height in authored meters | Scaled shared box face/housing in meters | Native 1.2x0.7m dimensions, roll37.5/90/-125 degrees and vertical aims passed |
| Undefined aim | Selectable world-aligned housing; no SCNLight | World-aligned housing; hidden face, source and aim markers | Native degenerate initial-state test passed; a later recovery-transition test is still a targeted gap |
| Authored camera | Body at authored position, lens on local -Z; CameraFraming supplies target/up/lens | Body/lens local -Z and same CameraFraming | Native vertical camera and local-negative-Z lens test passed; RealityKit execution unavailable |
| Stand | Extends from positive-height fixture toward world floor; absent at/below threshold | Stand plus cross base at world floor | Native identity/selection tests passed; new threshold-transition test awaits current-checkpoint execution |

Native transform comparisons allow 2e-5m positional error for Float32 world transforms and 1e-6 axis/dimension error. These are existing test tolerances, not altered acceptance thresholds. Native shading remains illustrative and is not a candela/area-source calibration.

## Fit defect and correction

The reproduced baseline rig places subject at (0,2,-0.1), camera at (0,2,0.1), and a 4x4m rectangular emitter at (0,2,0) with a coincident manual aim. Core bounds intentionally exclude an undefined emitting face. The visual housing still exists.

Two independent wave01 workers calculated housing samples outside the old viewport at 360x280: SceneKit NDC(2.188813,2.555797), RealityKit NDC(1.625761,3.009950). These were mathematical projections, not native captures.

SpatialViewportBounds extends the validated core bounds with the actual display envelopes: bust, camera body/lens, fixture housings and outlines, world-floor stand bases, and the 0.0275m aim-target marker. It excludes the floor/grid. Keeping this helper in App preserves lane06/Plan bounds semantics.

The fitted orbit uses a bounding sphere and a48-degree field of view on the smaller viewport axis, with12percent distance margin. SceneKit changes its projection axis on resize; RealityKit derives vertical field of view from the aspect ratio and rejects values that round to180 degrees as Float. The RealityKit navigation state keeps Double calculations until native upload, clamps distance to0.45...1500m and target to±300m, and uses far distance equal to orbit distance+750m. SceneKit native camera-controller navigation is a separate path; these RK clamps do not constrain its gestures.

The first native checkpoint passed actual SceneKit narrow-layout projection tests for high stands and coincident4m modifiers. Current additional aim-marker/clipping tests require the newer176-method execution. Pure projection witnesses do not establish native gesture delivery, RealityKit rendering or frame-rate behavior.

## Stable updates and selection

Metadata, output, position, roll and valid selection updates preserve continuing equipment nodes. Modifier kind or rectangle dimensions may replace shape resources while keeping the UUID-owned nodes. Deleted, invalid or replaced scene lifetimes discard equipment nodes and their hit maps. Hit resolution also checks current parent ownership and visibility, so a retained old node cannot select a reintroduced UUID.

The new SpatialEntityUpdateTests exercise point/directional/rectangle transitions, independent rectangle-axis resizing, and stand detach/reattach. The unchanged-scene callback boundary and degenerate-aim recovery remain explicit targets for later waves. Parent SwiftUI identity is owned by lane01: recreating the wrapper still recreates its coordinator, so viewport preservation across first save requires the documented composition change.

See validation/NATIVE-68c83.md, captures/receipt-68c83.json and the worker ledgers for exact source and execution provenance.
