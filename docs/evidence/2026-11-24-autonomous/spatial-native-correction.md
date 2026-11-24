# Spatial preview native failure diagnosis and correction

## Observed failure

Source `ff8b683098a720b4c7abdddf212f85a79f3cfd39`, [GitHub Actions run 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829), executed 42 native test methods. Forty methods passed. Two methods in `SpatialPreviewTests` failed with 33 assertions:

- `testTranslatedRigAndModifierFitActualSceneKitProjection`: the 16 corner projections had negative X coordinates and depth greater than 1, across landscape and portrait viewports.
- `testEmptyExtremeRigHasFiniteFitAndCameraModeRemainsPhysical`: the returned FOV differed from the Double domain value by approximately `3.94e-8` degrees.
- `testOrdinarySceneEditPreservesOrbitButExplicitFitRestoresCamera` passed.

These results are actual native failures, retained as evidence. They do not establish that a corrected candidate has passed.

## Projection diagnosis

The failing synchronous test updated the model scene graph and immediately queried `projectPoint` in the same main-thread call. Its projected values match the initial, uncommitted camera at the world origin: vertical FOV 48 degrees, default near plane 1, default far plane 100. They do not match the fitted camera's transformed position or explicit near plane 0.02 and far plane at least 400.

For the declared fixture, an independent calculation reconstructed the emitter corners and obtained world bounds:

```text
minimum = (76.90139475700636, 0.6682178936723648, 73.8)
maximum = (81.5, 3.5317821063276353, 78.04110973719389)
```

With the initial identity camera, the predicted projection is:

```text
pixelX = width / 2 - height / (2 * tan(24 degrees)) * worldX / worldZ
depth  = 100 / 99 + (100 / 99) / worldZ
```

| Viewport | Predicted X for successive X/Z corner pairs | Actual native values |
|---|---|---|
| 360 × 280 | −147.6594916, −129.8529809, −167.2531110, −148.3817936 | −147.65952, −129.85301, −167.2531, −148.3818 |
| 240 × 400 | −348.0849880, −322.6471155, −376.0758728, −349.1168480 | −348.085, −322.64716, −376.0758, −349.11682 |

The predicted depths are `1.0237880156579344` and `1.023044201369081`, matching the logged `1.023788` and `1.0230441` within Float representation. Each pair occurs twice because the two Y bounds do not affect X or depth for this initial camera. This numerical agreement supports uncommitted presentation state as the cause; it does not justify changing fitting distance or dropping the visibility assertions.

Apple documents that scene changes are collected in an automatic transaction and applied to the presentation scene graph at the next run-loop iteration. A synchronous test that does not advance that boundary must explicitly synchronize it before querying rendered projection. Apple also advises avoiding explicit `flush()` in ordinary application updates where the run loop already performs it.

## Corrections

- `App/SpatialPreview.swift` groups geometry, camera pose, lens, clipping and controller-target updates in an explicit zero-duration transaction with implicit actions disabled. Viewport-axis changes use the same atomic, nonanimated policy. This prevents those changes from inheriting an enclosing animation duration. It adds no application-side flush or blocking render.
- The independent reviewer added `SCNTransaction.flush()` after native test layout and before projection queries. Every finite/X/Y/depth clipping assertion remains present and unchanged.
- The orbit fit's bounds, radius, distance, orientation and user-orbit preservation behavior remain unchanged.

## FOV representation

The observed angle is exactly the Float32 round trip of the expected domain value:

```text
expected Double = 26.991466561591626
Double(Float(expected)) = 26.991466522216797
native returned value = 26.991466522216797
```

The independent reviewer replaced the sub-representation `1e-8` degree tolerance with one ULP of `Float(expected)`. The physical camera angle remains derived from `CameraFraming`, and camera-position and projection-direction checks remain intact. This correction is supported by the exact observed representation, not a broad visual tolerance.

## Verification status

- Independent Python geometry/projection calculation executed and matched the logged failure values above.
- Swift frontend syntax parsing of the changed native source passed on Linux Swift 6.4.3.
- Scoped `git diff --check` passed.
- Apple SDK compilation and execution of the corrected candidate are **pending**. The existing failed run must not be relabeled as passing.
- No device rendering, calibration, performance or release gate is established by this packet.

## Primary references

- [Apple: SCNTransaction and automatic presentation updates](https://developer.apple.com/documentation/scenekit/scntransaction)
- [Apple: SCNTransaction.flush()](https://developer.apple.com/documentation/scenekit/scntransaction/flush())
- [Apple: projectPoint and normalized clipping depth](https://developer.apple.com/documentation/scenekit/scnscenerenderer/projectpoint(_:))
- [Apple: zNear default](https://developer.apple.com/documentation/scenekit/scncamera/znear)
- [Apple: zFar default](https://developer.apple.com/documentation/scenekit/scncamera/zfar)
