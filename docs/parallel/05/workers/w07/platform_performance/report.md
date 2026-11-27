# Wave07 — platform and performance

**Disposition:** retained native execution passes at `9725fb1177a5c7afbdf798ffd627e65e604c75b1`; current `4e694bc377c4825d1d2dd52fcd7900e534c75072` has verified Apple compilation, with native execution pending.

## Executed evidence

Independent parsing of [the preserved log](../../../validation/native-9725fb1.log), blob `c75a9a6aceb854eee77fd0c9b5ffa242ce2fd250`, finds 542 XCTest passes: 366 macOS package methods and **176 native methods**, each native method starting/passing exactly once. Native failures, skips, duplicates and omissions: zero.

| Spatial class | Passes |
|---|---:|
| SpatialEmitterGeometryTests | 5 |
| SpatialEntityUpdateTests | 3 |
| SpatialInteractionTests | 9 |
| SpatialPreviewTests | 3 |
| SpatialViewportStateTests | 10 |
| **Total** | **30** |

Actual environment: Intel x86_64 macOS 26.6.1/25G76; Xcode 26.6/17F113; Apple Swift 6.3.3; XcodeGen 2.46.0; iPhone 17 Pro simulator, iOS 26.5. Debug test-bundle and Release app builds succeeded. The log records `** TEST EXECUTE SUCCEEDED **`, “Required Metal methods executed and passed; no native methods skipped.” and exact 176-method accounting. Dedicated job steps confirm finalized XCTest export succeeded.

The 100-update node-count/identity regression passed; this measures neither allocations nor frame rate. Two SceneKit attachment names and the archive digest match [the retained capture receipt](../../../captures/receipt-9725fb1.json). This reviewer checked provenance, not the PNGs visually.

## Current source boundary

At **2026-11-26 14:58:23 UTC**, run 45838950713 core job 139978271046 succeeded; native job 139980771221 remained queued. Dedicated steps for studio-optics job 139980771431 independently show **Build native UI test bundle: completed/success**; selected UI execution remained in progress.

Pinned project/workflow inspection establishes Debug `KeyAndFill`, `CODE_SIGNING_ALLOWED=NO`, unfiltered `build-for-testing`, with app, native and UI test targets. Independent source inventory is **184 native/38 spatial**: eight additions, zero removed prior methods. Compilation does not execute those additions. Retain their pending status and the RealityKit rendering boundary. No FPS, allocation, physical-device, gesture-delivery or VoiceOver result follows from this evidence.
