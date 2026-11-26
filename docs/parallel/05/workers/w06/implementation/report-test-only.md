# Wave 06 implementation report

Actual tool canonical ID: `/root/w06_acceptance/implementation`.
Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Frozen input: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`.
Private commit: `d112069f8c4fa4a1770c130fe6c8491fe9c21817`.
Private worktree: `/tmp/keyfill05-be879deb/worktrees/w06-implementation`.

## Result and reasoning

Added only `NativeTests/SpatialAimRecoveryTests.swift`, with one meaningful method, `testCoincidentAimRecoversRetainedLampAtTranslatedVerticalPose`. Existing assigned suites covered an initially undefined emitter and ordinary geometry changes but left the same-UUID valid → coincident → valid transition untested.

The fixture begins at (80, 2.1, 75), aimed along -Z with +90-degree roll. Coincident aim must retain the fixture, source node, visible outline and stand, retain their geometry objects and unchanged dimensions, keep live selection, center the housing with a world-aligned basis, and remove the actual SCNLight. Recovery moves the same UUID to (81, 2.1, 74), aims vertically along +Y with -90-degree roll, restores a real spotlight, and verifies the authored front position, source anchor, stand anchor and complete fixture/source bases. Expected cardinal vectors are literal; the regression does not call the production frame helper. SceneKit has no separate aim-marker node, so assertions use its actual housing/outline/stand graph.

The optional camera method was omitted because `SpatialInteractionTests` already covers defined → coincident → vertical camera/lens recovery. No production change or concrete production defect is claimed by this test package.

## Evidence and limits

`git diff --check` passed. A bounded source check verified the frozen HEAD, sole allowed changed path, exactly one method and no expected-value call to `EmitterFrame` or `StudioPhotometry.frame`. Native execution, compilation and type checking are **UNRUN**. No build, toolchain installation, production edit or shared-checkout mutation occurred. Existing 2e-5 position and 1e-6 axis/dimension tolerances are preserved. Recommend independent exact-patch review followed by the lane's next native execution.

## Capturable artifacts

- Patch: `/tmp/keyfill05-be879deb/waves/w06/implementation/change.patch` — SHA256 `2457d126a874a22a4a5185f6d95a7bcfff84c9adc5395d2a4553d0734ffe63c1`.
- Complete source: `/tmp/keyfill05-be879deb/waves/w06/implementation/SpatialAimRecoveryTests.swift` — SHA256 `17a4a59ed520298a0143fe3d6ccc1589f36af3414fcf51bf81d9c1ad491e16a0`.
- Source receipt: `/tmp/keyfill05-be879deb/waves/w06/implementation/source-checks.json`.
