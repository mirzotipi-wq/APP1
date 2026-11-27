# Wave 10 — Platform and performance

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; documentation parent: `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`.

**Disposition:** no additional reproducible lane-05 defect; no edit proposed. I inspected pinned source/contracts and root-supplied logs/capture metadata, enumerated methods and verified hashes. No local build, installation or native execution occurred.

**Verified execution:** run 45851365897 / job 140022794410 completed successfully, confirmed by root at 16:52:09 UTC. `docs/parallel/05/validation/native-60059a0.log` and its complete contiguous `native-60059a0-unit-output.log` independently reconcile **185 native / 39 spatial passes**: 11 arithmetic/state helpers and 28 direct SceneKit methods. Every expected method has exactly one ordered start/pass; no omissions, failures, skips, duplicates or unexpected events. The new Float regression passed. Earlier 184/38 evidence remains historical. Debug/native-test-bundle and Release simulator builds succeeded. Diagnostic warm-up failed before the actual successful tests.

The runtime was x86_64 iPhone 17 Pro / iOS 26.5, macOS 26.6.1, Xcode 26.6 build 17F113. `App/RealityStudioPreview.swift` selects SceneKit before constructing RealityKit on that target. RealityKit compilation establishes no supported-runtime/device execution. Direct methods establish node/state/projection behavior, without renderer-thread atomicity, deallocation or delivered-gesture acceptance.

Current original SceneKit snapshots and `docs/parallel/05/captures/receipt-60059a0.json` have verified hashes and new attachment metadata; pixels exactly match 4e. `docs/parallel/05/captures/receipt-full-app-60059a0.json` documents the passed 3D/Fit/manual-fallback method. It asserts selected mode after tapping Fit, without validating camera pose or orbit/pan/pinch.

`docs/parallel/05/validation/core-60059a0.log` confirms 366 Debug / 366 Release / 100 tooling passes. Its eight frame workloads, twelve cancellation probes and four visibility workloads use seven measured samples: CPU host diagnostics only.

At 16:52:09, export retained nine passes/one failure; app-accessibility failed Plan-mode meter reachability before 3D/Camera; library was running, optics completing, room queued. Root supplied the latest accessibility status. Owning lanes must resolve these and integrate lane-01 presentation identity. Supported-device RealityKit, manual accessibility and FPS/RSS/thermal evidence remain absent.

Historical pending cutoffs, four executor outages and wave-01 summary-only recovery remain explicit. Planning targets are unmeasured. Detailed provenance and hashes: `evidence.json`.
