# Wave 06 implementation report

Actual tool canonical ID: `/root/w06_acceptance/implementation`.
Campaign baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Frozen input: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`.
Test commit: `d112069f8c4fa4a1770c130fe6c8491fe9c21817`.
Production commit: `e66319bf8ee54925ae2121154adfbc4a6bbd099c`.
Private worktree: `/tmp/keyfill05-be879deb/worktrees/w06-implementation`.

## Result

Added `NativeTests/SpatialAimRecoveryTests.swift`, containing one method. It exercises the same UUID through -Z aim/+90-degree roll, coincident aim, and translated +Y aim/-90-degree roll. It retains the fixture, source node, visible outline and stand plus unchanged geometry, preserves selection, verifies the centered world-aligned undefined housing, requires actual SCNLight suppression/restoration, and checks authored front/source/stand positions and complete fixture/source bases against literal independent vectors. SceneKit has no separate aim-marker node. Existing camera recovery coverage made a second method unnecessary.

After the geometry review confirmed the contract and the lead relayed root authorization, changed only RealityKit's rectangular `face.scale` branch and its comment in `App/StudioEntityGraph.swift`. Rectangle width/height now equal the authored emitting-face dimensions; directional inset, face depth, front plane and all other source bytes are preserved. Core, shared composition, Plan, AR and Study were not edited.

## Evidence and limits

`git diff --check` passed. Bounded source checks confirm the exact two-path scope, clean private worktree and one new method. The source-bound scalar witness calculates 2.697142857% former area shortfall for 1.2×0.7 m and 42.24% for 0.05×0.05 m; both become zero. Directional dimensions remain 0.208×0.168 m and the face front remains z=0. This is transcribed decimal arithmetic, not native execution.

Native tests, compilation and type checking are **UNRUN**. Existing position/axis tolerances remain unchanged. Recommend independent aggregate-patch review and later native execution; no runtime or visual acceptance is claimed.

## Capturable artifacts

- Aggregate patch: `/tmp/keyfill05-be879deb/waves/w06/implementation/change.patch` — SHA256 `4c26f04190d2428a6ebc355b1ff93d7e25151d545a89f0b4026f9938ce4f95b7`.
- Test source: `/tmp/keyfill05-be879deb/waves/w06/implementation/SpatialAimRecoveryTests.swift` — SHA256 `17a4a59ed520298a0143fe3d6ccc1589f36af3414fcf51bf81d9c1ad491e16a0`.
- Production source: `/tmp/keyfill05-be879deb/waves/w06/implementation/StudioEntityGraph.swift` — SHA256 `a969106d321096bd2a573c1b0ddbb6b3c70192dfd86a792ec1a8a249089a783b`.
- Scalar witness: `/tmp/keyfill05-be879deb/waves/w06/implementation/face-scale-witness.json`; reproducible script alongside it.
- Source receipt: `/tmp/keyfill05-be879deb/waves/w06/implementation/source-checks.json`. Initial test-only artifacts are retained separately.
