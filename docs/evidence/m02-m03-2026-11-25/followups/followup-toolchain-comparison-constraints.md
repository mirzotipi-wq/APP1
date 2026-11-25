# Constraints for a controlled Xcode/runtime comparison

Read-only inspection, 2026-11-25 UTC, at published revision **cbf94cecb113c1f03b0b8c7287e763655c14ec11**. No build, alternate toolchain run, branch, implementation, or repository edit was performed. Source hashes and the declared 110 native / 36 UI method inventory are in `followup-toolchain-comparison-provenance.json`; those counts are source inventory, not execution evidence.

## Selected toolchain and Metal

`scripts/ensure-metal-toolchain.sh` inherits the job's `DEVELOPER_DIR`. It compiles a real iPhone-simulator shader to AIR with `xcrun --sdk iphonesimulator metal`, links a metallib, and requires a nonempty output. On failure it attempts `xcodebuild -downloadComponent metalToolchain` once, then repeats the real probe. The strict shell fails on a failed download or ineffective installation. The four Python checks are mocked control-flow tests and do not establish Apple compiler compatibility.

There is no hardcoded Xcode version inside that script. Keep its real compile/link, selected-toolchain provenance, raw log, and existing 12-minute step. A different Xcode installation may require its optional component; its actual success is unverified until executed.

Native execution separately requires each of these StudyRendererTests to have exactly one terminal `passed` outcome and rejects any native `skipped` outcome:

- `testMetalMatchesCPUOnAvailableDevice`
- `testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal`
- `testCancelledInitialParityValidationCanRetryMetalOnSameEngine`

A working compiler does not establish an available GPU. Conversely, the app's CPU fallback does not replace these required Metal results.

## Concrete comparison boundaries

| Proposed diagnostic | Required configuration consistency |
| --- | --- |
| Xcode 26.5 with iOS 26.5 on the current Intel pool | Select the explicit 26.5 bundle for every command; the current SDK 26.5 guard and exact iOS-26-5 / iPhone 17 Pro selection remain consistent. Rebuild for testing with that bundle; do not reuse the 26.6 products. |
| Xcode 26.3 with iOS 26.2 | Select the explicit 26.3 bundle **and** match SDK guard, exact runtime ID, device selection and diagnostic labels to 26.2. The workflow contains separate native and UI copies of those requirements. A bundle-only replacement would fail the retained 26.5 guard. |
| Same Xcode 26.3 / iOS 26.2 across Intel15 and Intel26 | Keep architecture, device, source, fixtures, selectors and assertions identical; record different host/image revisions. This compares host pools after changing the baseline toolchain/runtime, so it cannot isolate the original 26.6 failure by itself. |

All remain **diagnostic proposals**, not verified compatible configurations. The current host atomic-write helper also discovers the SDK through the selected Xcode and records explicit SDK/compiler provenance; retain that behavior.

The project declares iOS 17 minimum, Swift language mode 5.0, and package tools 5.9. The inspected source has an iOS 26 slider path and an iOS 18.2 reference-import assertion branch; both remain enabled on either 26.2 or 26.5. An iOS 18 comparison would change the slider path and is a poorer first control. This source review does not prove older compiler typechecking.

All Intel simulator versions select the existing x86_64 SceneKit preview before RealityKit initialization. Successful Intel evidence therefore remains SceneKit evidence, not ARM RealityKit or physical AR evidence.

## Protected coverage and evidence

`AGENTS.md`, `docs/QUALITY.md`, and `agents/OPERATING_PROTOCOL.md` prohibit weakening protected requirements, suppressing failures, replacing fixtures to hide regressions, or treating unrun tests as pass. They require actual toolchain/SDK/revision provenance; they do not freeze Xcode 26.6 as a protected product requirement.

Preserve the complete 110 native / 36 UI inventory and seven UI classes, current class-to-shard checks, all full `.all` audits with return-false handlers, every predicate/assertion, ten workflow repeats, and existing step/job deadlines. Keep Debug/Release builds, required Metal outcomes, native result export, and raw failed evidence. A tiny independent static audit control can help identify a platform-sensitive path but cannot count as APP1's audit or regression pass. If only the control or one shard is executed, report only that scope.

A version comparison does not close the manual real-device accessibility gate, physical performance/AR gates, or other unresolved quality requirements. Record outcomes by actual tested source and environment, and let the current frozen candidate finish before choosing the next experiment.

