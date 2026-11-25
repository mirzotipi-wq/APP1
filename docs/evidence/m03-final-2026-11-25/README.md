# M03 completion campaign — 25 November 2026

## Current checkpoint

Source `c86fadd867322b816f400b003de461e0e418dc52` is committed on `main`; the previous source produced concrete room and accessibility failures, preserved below. M02 remains accepted under `m02-m03-code-v2`; M03 is in native validation. This packet records the new completion campaign, distinct from the previous worker campaigns. The requested 100 real agent contexts are being executed in bounded batches; the [live ledger](worker-ledger.json) lists only actual created contexts and completed reports at this checkpoint.

## Baseline findings and implementation

- Starting revision: `fd73004ddcb1b01e53e29d03bed093fb24b8a75a`.
- The preceding application run `45688029379` passed its portable suite, studio/export, ten Studio optics workflows, and library/reference workflows. Room/precision failed before all five selected methods started because the UI runner could not initialize Accessibility. The required app-accessibility test started and failed its text-size oracle; that failure is preserved separately from the unstarted room tests.
- The project-library screenshot showed action blue `#0088FF` against white (3.52:1). The sheets now use the tested adaptive palette for actions, secondary text, error text and selection/destructive cues. Name Save has explicit enabled and disabled foreground/background pairs.
- Project naming now has a scrollable Cancel action, a 44-point field, keyboard-preserving scrolling, and actual default/largest-text keyboard reachability checks.
- Exact numeric entry, target-lux and room measurement fields now reject oversized UTF-8 replacements before assigning draft state, retain the preceding draft, expose a clear accessible error and disable Apply/Set until a valid-sized edit. The light-name alert also bounds Unicode scalar input before retaining its draft. Decimal grammar, locale handling and numerical tolerances are unchanged.
- Inspector, settings, guide, arrangement, target-lux and room labels now use the same contrast-tested secondary/action palette. Room warning text, recipe errors and the room diagram use explicit tested pairs. The room-notes prominent action has a matching adaptive text color.
- White-balance presets now show a checkmark, stack at accessibility text sizes and retain their selected trait. The required default/largest-text workflow checks actual preset text, target sizes, state changes and Undo.
- Target-lux adjustment now accepts the explicitly achievable maximum output even when independent inverse rounding overshoots. It rejects the next representable lux above the actual forward-model maximum and preserves the existing accuracy bound; eight new regressions pass.
- Simulator startup now permits the existing single bounded recovery after a timed-out postflight inventory query. Identity, execution, signal and cleanup failures remain terminal.
- Native/UI method accounting now runs even after test failure, retains machine-readable expected/started/passed/failed/skipped/unstarted results, rejects foreign/malformed events, and enforces ordered start then pass.
- The text-size oracle no longer adds optional font leading to SwiftUI's visible text frame. It uses physical-pixel comparison without the prior one-point allowance, logs actual metrics, and retains screenshot review, exact labels, growth and 44-point checks.

## Verification

The [local receipt](local-validation.json) records source hashes, unchanged-source carry-forward and retained logs: **357 Debug, 357 Release and 92 tooling tests passed**, together with native Swift syntax, shard inventory, state structure, source icon/privacy validation and whitespace checks. Linux syntax parsing is not an Apple SDK build.

The [full native workflow](https://github.com/mirzotipi-wq/APP1/actions/runs/45709267885) must finish before M03 can be accepted: unsigned Debug/Release application builds, 118 native methods including required Metal execution, and 35 required UI methods. Current source changes do not yet have passing native/UI evidence in this checkpoint. The earlier 4d0c67d source passed 118 native, nine library and ten export methods; it failed one of five room methods and its one app-accessibility method. See the [executed receipt](validation/source-4d0c67d/native-ui/executed-summary.json).

Historical failed and unavailable results remain unchanged. No physical device, calibration, platform accessibility audit or release-readiness result is claimed by this packet.

## Repair and provenance checkpoint

The rejected room resize now preserves its error across identical text echoes. Measurement fields, Set/Rotate labels and the native rotation slider have larger control layouts, with runtime 44-point assertions awaiting execution. Frame comparison retains 44 points and admits only one endpoint ULP, with a strict sub-nanopoint precision guard; the failed Plan marker and raw frame remain retained. Actual library action pixels are now #0056B3 on white at 7.04:1, above 4.5:1, in the [observed screenshot receipt](validation/source-4d0c67d/native-ui/library/action-contrast.json).

The persistence wrapper observes the actual target filesystem/device with bounded commands and fails missing/inconsistent identity. A local compiler expression-limit failure is retained alongside the semantics-preserving typed fixture repair and successful complete EFBIG/interruption execution. All nine observed local targets were tmpfs; macOS filesystem execution remains part of the new CI requirement. See the [local atomic receipt](validation/source-c86fadd/local/atomic-receipt.json).
