# M01 native repair and independent M03 archived removal — 2026-11-23

## Scope and evidence
Starting source e372d52dae6241b0688f3e48264e46520623f37c. Three source commits: cd4062fdb7954e4e7ea56781233f4a4bd3950e15, 2f5a225f50ee8439a28064e2cf9f516eacc75577, f64d425344a2a4bef02ce80599a21442a3f103ed. The implementation and observed CI are distinguished from pending behavior.

| Observed result | Exact source | Evidence |
|---|---|---|
| 89 portable tests pass both configurations; Apple 89 core tests pass and unsigned Debug app builds; native test compilation fails on API availability | 3628de6 | [Native log](https://github.com/mirzotipi-wq/APP1/actions/runs/45269453791/job/138025048902) |
| Native PDFKit 2/2; renderer 3/3; 8/9 UI (meter fails), including project library and persistence smoke | b8d0ef9 | [Native log](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/job/138016896671) |
| 89 portable tests pass both configurations after guarded import test change | cd4062f | [Core job](https://github.com/mirzotipi-wq/APP1/actions/runs/45274080732/job/138041191178) |
| 90 portable tests pass both configurations, state and syntax, fixtures and parity pass | 2f5a225 | [Core job](https://github.com/mirzotipi-wq/APP1/actions/runs/45274202947/job/138041617075) |
| 92/92 Debug and Release, zero failures; completed core job; simulator in_progress, current step: Record Apple toolchain and test the portable package on macOS; conclusion pending | f64d425 | [Current run](https://github.com/mirzotipi-wq/APP1/actions/runs/45274350597) |

Historical native environment: macOS 26.6.1, Xcode 26.6, iOS Simulator SDK 26.5. Old actual Metal fixture results: hard, soft, warm-rotated, dark, near-field and translated all passed; maximum channel difference 1/255, none above 4, all invalid counts matched. Renderer remains diagnostic and uncalibrated; no real iPhone performance or physical reference evidence. [Historical actual XCTest artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/artifacts/14865356504) listed but screenshots not inspected here.

## Acceptance and self-review
- Preserve iOS 17 baseline and import path. Read the same temporary file as the FileRepresentation callback on every OS; exercise the public Transferable initializer only where available. No underlying test or privacy invariant removed.
- Replace generic group-level accessibility identifier with scoped full-width button and a meaningful expansion value. UI regression waits for actual lux, then rechecks it after a balance change. Portable default portrait test proves nonzero lux and a changed display without changing illuminance.
- Archived inactive records only. Stable ID, confirmation, cancellation, no deletion of active/open projects, stale save rejection, capacity recovery, atomic write, reopen and preservation of other projects. External exports and legacy portrait.json intentionally retained; not secure erasure. New tests exercise invalid IDs, active/unarchived protection, stale deletion and persistence.
- No actual agent orchestration, independent reviewer or physical-device validation. No changes to protected requirements. Local container Swift 6.2.1 has no Xcode and git cannot resolve github.com; actual GitHub Actions used instead. Native syntax check does not prove Apple SDK compatibility.

M01 remains active pending current native evidence, all release gates remain. Evidence floor remains 20/100, not a product quality or completion percentage.
