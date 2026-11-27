# Wave 07 — Acceptance

Worker: `/root/w07_acceptance` (`fork_turns:none`). Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`.

**Disposition:** SceneKit has successful native fallback evidence at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`. Current `4e694bc` has source review and Apple Debug compilation; its eight later methods and RealityKit correction require execution evidence.

| Evidence | Supported conclusion | Limit |
|---|---|---|
| Source | `RealityStudioPreview.surface` chooses SceneKit on x86_64 iOS simulators before constructing the RealityKit coordinator/graph. | Compile-time architecture choice; other architectures select RealityKit. |
| Native, 9725 | Run 45826141504/job 139935031405 passed 176 methods/30 spatial, Debug test-bundle and Release app builds. | The 30 mix pure viewport state and direct SceneKit tests; no delivered-gesture claim. |
| Captures, 9725 | Receipt records two original `SCNView.snapshot()` images in `UIWindow`, artifact 15123617978, hashes and prior visual review. | This worker did not independently inspect images. |
| Portable | Historical helper math and core package evidence are separately attributable. | Core CI/scalar witnesses cannot execute native renderers. |
| Current compile | Run45838950713/job139980771431: Debug build-for-testing succeeded, observed 14:58:23 UTC. | Native184-method execution queued; no current Release pass claimed. |
| Current inventory | Eight spatial files declare 38 methods: ten state and 28 SceneKit methods. Four navigation, three selection and one aim-recovery method postdate 9725. | Inventory is not execution. |
| Unestablished | RealityKit rendering, physical devices, manual VoiceOver, delivered gestures, allocation/RSS/FPS/thermal behavior and calibrated lighting. | No substitute pass. |

`SpatialPreview.updateView` refreshes callbacks before its unchanged-scene return and publishes geometry/camera changes synchronously with disabled SceneKit actions. Stable identities, stale-hit rejection, unavailable feedback and recovery have explicit source/tests. First-save `.id(generation)` reset remains lane01’s documented owner request.

Inspected pinned master/operating instructions, architecture/design/product/quality/roadmap, state/handoff, acceptance contract, lane05 geometry/owner/native/capture receipts, adapter source and spatial declarations. No wave07 production edit, source-ref update, threshold change or milestone promotion is proposed. Owner-scope differences inherited from main `9e0e2ba` are not lane05-authored. No builds, tests, host probes, new screenshots or image review occurred. Startup commands were unavailable when this wave began; later host recovery was parent-reported. The packet preserves exact inputs and ten real worker IDs.
