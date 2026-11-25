# Focused Intel simulator compatibility review

Source: main `18f387aa0db3ac06d21dfe241eb6dcbbc19f9b4c`. Read-only review; no builds, test execution, code edits or new skips. Official label/toolchain availability is covered by a097's separate research.

**Recommendation:** an available `macos-26-intel` runner can retain the complete existing test inventory and assertions and produce a complete **Intel simulator** receipt. It cannot provide equivalent execution evidence for the ARM RealityKit branch. No source-level x86_64 compatibility blocker was found; actual success remains conditional on every required method executing and passing.

## Concrete compatibility findings

- **Inventory:** counted 110 native methods across 13 files and 36 UI methods across seven classes. No architecture-based test omissions or skip selectors exist. Three native methods use `#if DEBUG`, satisfied by the unchanged Debug test build; one UI method uses `targetEnvironment(simulator)`, satisfied on both architectures. The three shard selectors remain applicable.
- **RealityKit/CoreRE:** `RealityStudioPreview.surface` selects `SpatialPreview` under `simulator && arch(x86_64)` before constructing the RealityKit coordinator or its `StudioEntityGraph`. The note branch is also guarded. AR is unsupported on every simulator; `cameraEnabled` remains false, so its separate `ARView` is not created. Intel 3D/Fit therefore tests real SceneKit geometry and interaction, not RealityKit execution. The historical Intel crash was in CoreRE mesh initialization; this existing fallback directly avoids that path.
- **Metal:** three existing `StudyRendererTests` throw `XCTSkip` if `MTLCreateSystemDefaultDevice()` is nil: CPU parity, near-field routing, and cancellation/revalidation. The compiler-component probe proves shader compilation only. Require **110 actual native passes and zero required skips**, including all three GPU methods. Pipeline/library/parity errors with an available device remain failures; do not infer a GPU pass from CPU fallback.
- **Workflow:** changing only `runs-on` fails both current `uname -m == arm64` assertions. Any deliberate runner change must update those environment assertions accurately while retaining builds, all selectors, audits, thresholds and deadlines.
- **Accessibility:** prior Intel receipts include AX Code=-56 timeouts. Both current `.all` audits and their unconditionally-false issue handler must remain; successful completion on the new runner is unverified.

Historical precedent is scoped: source `22e51d7` used `macos-26-intel` and recorded 84/84 native passes without skips, actual Metal parity, and 11/11 studio/export passes including 3D/Fit. It supports feasibility, not current-source acceptance. Sources reviewed: workflow, project.yml, native shard map, NativeTests, UITests, RealityStudioPreview/ARPlacement/MetalStudyRenderer, and retained development evidence.

## Infrastructure repair diff review

Reviewed workflow SHA256: `21b50bc475911e06db3c10c857a14482b99e01f5c86c014a9329fd9f2f9933ed`.

**Scoped approval to publish the reviewed runner repair. No blocking finding.** Both Apple jobs now select the standard Intel label and require `x86_64`, pin `DEVELOPER_DIR` to Xcode 26.6, check simulator SDK 26.5, and fail closed unless the existing iPhone 17 Pro/iOS 26.5 destination is available.

The diff preserves native/UI selectors, all assertions, both complete accessibility audits, build/test commands, result exports, shard structure and deadlines. The added inline gate rejects every native skipped-method record and requires exactly one terminal `passed` outcome for each of the three required Metal methods. Missing, skipped, failed, duplicate or retried outcomes cannot satisfy it. It follows the existing pipefail-protected XCTest command and does not replace that command's success requirement.

Root reports the inline gate passed against the retained real native log, YAML/Python blocks parsed, 28 Python tests passed and all seven UI classes remain assigned once. Those are supplied validation receipts; this reviewer ran no tests. Runtime acceptance remains pending. Intel 3D evidence continues to cover SceneKit, with no ARM RealityKit claim.
