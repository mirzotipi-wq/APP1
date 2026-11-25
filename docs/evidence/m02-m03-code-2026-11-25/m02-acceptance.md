# M02 accepted under the code-only contract

Date: 25 November 2026. Contract: `m02-m03-code-v2`. Final core source: `90d36f9120289a33ff8af37d626ea959830ddd38`. M02 is complete under this owner-approved development scope; M03 starts after this acceptance. This is not release or physical validation.

## Implemented and verified

- Conservative area-emitter facing rejection preserves the5cm near-plane boundary. Independent comparison covered69,126 baseline/candidate evaluations with exact Double outputs/callbacks/errors. Ten alternating benchmark pairs retained exact outputs, with consistent gains for deliberately away-facing emitters; ordinary-facing timing remains noisy.
- Completed-frame LRU cache is shared with portable tests and used by the native render actor. It bounds four entries,256KiB RGBA and64KiB validity masks; invalid/cancelled requests cannot publish/cache a frame, and fallback invalidation preserves appropriate completed frames.
- Study work is cancelled while the scene is inactive and resumes for the current request on foregrounding. Mannequin work remains capped at144pixels and CPU cancellation is polled at most every eight pixel evaluations.
- Validation rejects over-twelve-light scenes before legacy scans while preserving unsupported-version precedence. Every supported schema's12/13 boundary is covered.
- Twelve deterministic software scenes retain actual scene JSON/PPM/PNG outputs and a validated manifest. Original six pixels remain unchanged. Independent reviewers inspected all twelve for geometry/shadow/color/exposure defects.

## Actual acceptance results

| Gate/check | Observed result |
|---|---|
| Final core Debug/Release |338/338 each, zero failures |
| Point/area photometry |Existing analytic/numerical, transform, color, grazing and invalid-input regressions pass without tolerance changes |
| Synthetic images |12/12, zero unsupported pixels; final source and CI outputs exactly match retained pixels |
| Shared Float32 kernel |6/6; maximum channel error1, invalid masks exact |
| Strict precision fixtures |8/8; maximum channel error0, invalid masks exact |
| Final optimized benchmark |8 frame workloads,12 observed cancellations,4 visibility workloads;7 samples/workload, exact revision |
| Apple Debug/Release builds |Both passed at a6ba92b |
| Native renderer/cache/Metal integration |110/110 exact-source native methods started and passed once, zero failures/skips/missing; all three explicit Metal methods passed; genuine result bundle exported |

`validation/m02-count-boundary.json` records final commands/input hashes and all portable outcomes. `validation/m02-final-benchmark.json` retains every final raw sample. `validation/m02-ci-core.json` records the completed GitHub core job. `validation/m02-ci-native.json` records actual successful required native steps; the finalized log independently confirms all110 expected methods passed once, with no missing or unexpected cases. Native App and NativeTests source is identical between a6ba92b and90d36f9. Only the count-first core guard differs, with identical supported-scene behavior and errors; all final portable checks were rerun. No older unrecorded-revision benchmark is used as the final gate proof.

## Scope and retained failures

Physical photography/calibration, photographer review, device frame-rate/memory/thermal measurements and manual device accessibility are removed external requirements, explicitly unperformed. Software fixtures and host timings do not establish those results. The whole initial application workflow is not declared green: its room/precision shard failed before tests because simulator System App startup exceeded ten minutes. That separate M03 verification failure is retained in `validation/ci-room-startup-failure.json` and its original boot log. Bounded startup recovery and complete required M03 workflows remain active work.
