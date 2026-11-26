# Wave 04 — camera depth, normals and evidence challenge

Input: `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`. Exactly **10 actual contexts**, including acceptance coordinator W31 and **nine fresh specialists**, completed. Every specialist used `fork_turns:none`; the W34 recovery followup reused its existing context. Root alone integrates and pushes.

## Main result

W32 found a concrete failure in the camera-facing heuristic: a clipped head entry can expose a front-facing neck surface inside the head. The pinned scan visited 2,048 poses, scanned 760,320 pixels and found 22 clipped poses accepted by the guard. The actual 40 render calls returned **32 images and eight invalidCamera throws**, not forty images. Root preserved the failure, replaced the heuristic with a direct first-surface depth check, and reran the forty retained calls: all threw invalidCamera. Candidate provenance is in the external source-hash receipt, because the reused raw probe embeds its original labels.

W34 supplied one 55-line real-mesh shadow-origin/geometric-hemisphere regression. Its original worker report correctly says Swift unrun by that worker. Root subsequently integrated it and passed seven emitter methods with zero failures; full Debug before that additional test passed 384 tests. W40 independently challenged the candidate's clipped-panel and exact-depth handling without finding a counterexample in its bounded arithmetic/source review.

W31 verified all twelve original/current PPMs and scene JSONs are byte-identical with zero unsupported metadata and exact-magenta pixels. W37 actually viewed both twelve-tile contact sheets plus three paired original/current bust images. The pointed crown is present in the originals and follows the authored profile.

## Actual workers

| Worker | Role | Tool-returned runtime ID |
|---|---|---|
| W31 | acceptance | `/root/wave04` |
| W32 | geometry/data | `/root/wave04/geometry` |
| W33 | API | `/root/wave04/api` |
| W34 | implementation | `/root/wave04/implementation` |
| W35 | concurrency | `/root/wave04/concurrency` |
| W36 | resource | `/root/wave04/resource` |
| W37 | consumer | `/root/wave04/consumer` |
| W38 | accessibility/privacy | `/root/wave04/accessibility_privacy` |
| W39 | platform/performance | `/root/wave04/platform_performance` |
| W40 | independent review | `/root/wave04/independent_review` |

Each individual report and the machine-readable ledger record assignment, input, designated private path, actual checks, limitations and provenance. No source/test edits by specialists other than W34's assigned test patch.

## Evidence limits

W33 verified error-order/catch distinctions; malformed lighting can fail before per-pixel clipping discovery. W35's executed Python model covered 6,561 patterns with at most eight further pixel starts and no modeled partial publication. W36 verified immutable pinned mesh storage and exact BVH recurrence via GitHub/JS; its candidate one-traversal assessment remained conditional because the candidate was unavailable to that worker. W38 reviewed actual UI text/semantics and the local synthetic path; no native accessibility or runtime privacy audit is claimed.

W39 independently bound retained results to ace9: 383 Debug and 383 Release tests; 163 native tests including nine pipeline methods; eight frame, twelve cancellation and four visibility workloads; two percentile recomputations. Actual simulator Metal evidence covers sphere/panel fixtures. Those results do not establish candidate Release/native/benchmark/image acceptance. No milestone, physical calibration, device performance or release readiness was promoted.

## Storage and recovery

Persistent ENOSPC first interrupted unused-worktree/report creation. Root moved later Git metadata to a temporary control clone. A subsequent environment outage/reset removed the private trees. Original W31/W32/W33/W34/W40 reports and W32 raw probes survived the persistent checkout; their bytes are preserved. W35's reported local files were absent after recovery. W35–W39 now have clearly labelled concise reports and complete returned messages in `wave04-evidence/*-final-inline.md`; W36's exact returned model JSON is also retained. These are not claimed as byte recovery of missing original files. W36–W39 did not originally persist local reports.

Root reported accepted code checkpoint `c9ff1a71c173774e7b7c794e475f8bdf5d633853`. No worker cleanup or ref mutation occurred. Remaining runtime normal-transition/translated-depth challenges may proceed in wave 8; W37 has no outstanding image-display blocker.
