# Wave 03 — grazing intersection and early cancellation review

Input: `1cefc654630a86ab320e58283957f4e91d6cbce6`. Ten actual contexts completed: acceptance leader W21 and nine fresh specialists. Root is excluded. This wave made no production source changes, commits, pushes, builds or renders.

## Acceptance

No blocker was found for the two reviewed corrections: an area-scaled triangle determinant with cached geometric normals, and a sphere cancellation poll before preparation. Acceptance is limited to this input and these corrections. Later camera clipping and preview changes require their own evidence; this review does not promote a milestone or establish release readiness.

The preserved polar witness has twice-area `1.521850571147037e-7 m²` and absolute determinant `1.521850570274425e-15`. The old absolute `1e-14` cutoff rejects it; the new scaled cutoff is approximately `1.521850571147037e-21`. W22 reproduced the recorded normalized-plane witness exactly and found one matching face for each of 50 forward/reverse rays among 5,248 triangles. Both translated arithmetic methods agreed on 150 finite windows per method.

W30 independently solved 25 selected rays with a 90-digit pivoted linear system. All 75 windows matched; weights remained between 0.333331660400 and 0.333335006267. Maximum deviation from the prescribed 50 µm distance was 2.08891933004e-9 m, below the existing 1e-8 m test tolerance. Seven valid crossings fail the original cutoff, establishing that both added grazing methods exercise the original defect. W30 reused prescribed vertices/raw rays, not intersection expectations. Neither arithmetic probe is a new Swift/BVH execution.

W21 reconciled root's retained logs: 380 unique passing methods each in Debug and Release, with no incomplete method. The original 24-method run retains 21 passes, three failed methods and 25 assertions. All 42 selective-manifest hashes match the input. The omitted visibility-test hash is preserved separately in W21's receipt. These Swift runs belong to root.

## Actual worker record

| Worker | Actual runtime ID | Completed check |
|---|---|---|
| W21 acceptance | `/root/wave03` | Source/log reconciliation and scope synthesis |
| W22 geometry/data | `/root/wave03/geometry_data` | 50 unique forward/reverse rays; 150 windows per method |
| W23 API | `/root/wave03/api` | Validated caller domain, signatures and half-open intervals |
| W24 implementation | `/root/wave03/implementation` | Cached normal arithmetic/winding and fixed-geometry limits |
| W25 concurrency | `/root/wave03/concurrency` | Preparation/pixel/final polling and cooperative limits |
| W26 resource | `/root/wave03/resource` | 164 KiB logical added payload; fixed counts and bounds |
| W27 consumer | `/root/wave03/consumer` | 25 original hash receipts; unchanged 12/6/8 definitions |
| W28 accessibility/privacy | `/root/wave03/accessibility_privacy` | Masks, visible states and unchanged photo behavior |
| W29 platform/performance | `/root/wave03/platform_performance` | Minimum current-source benchmark evidence |
| W30 independent review | `/root/wave03/independent_review` | Alternative high-precision oracle and original-failure sensitivity |

Each `Wxx-role.md` report records its actual checks and limits. `wave03.json` contains exact paths, hashes, statuses and the 12-file retained probe inventory. Runtime exposes canonical task names; no opaque ID is invented.

## Limits and remaining integration evidence

Public signatures, mesh vertices, sample/width/cache limits, fixture definitions, acceptance tolerances, endpoint/tie handling and mask recovery are unchanged. Cached storage adds 32 scalar bytes per retained triangle, or 164 KiB logical payload; actual SIMD stride, Array capacity and RSS were not measured. Fixed geometry supplies finite values; arbitrary unbounded geometry is outside the established safety argument.

Precancellation preserves resolution-error precedence. A false preparation poll still permits setup before the next check; pixel polls preserve the eight-evaluation bound. Cancellation remains cooperative, including a check/use window after a final false guard. No elapsed-time guarantee is inferred.

Original PPM hashes prove retained RGB bytes, not fresh alpha/mask validity. The recovered successful twelve-image comparison lacks its original comparison file. Fresh affected renders/visual review and explicit unchanged-path justification or execution for parity/precision remain integration requirements. The separately recorded close-camera defect at this input is outside the two corrections reviewed here.

The minimum performance refresh is one existing `-O` harness run at the exact compiled revision: eight frame workloads, twelve cancellation probes and four visibility workloads, one warm-up and at least seven measured samples per timed workload, with raw samples/p50/p95 and host/compiler metadata. Require all twelve `cancelled=true` records explicitly: process success alone permits false when no deadline was observed. No new cold-start gate is proposed. Native/Metal, device and physical results are not claimed.

## Executor interruption

The persistent checkout retained saved W21/W22/W23 probe files and completed reports when an executor replacement removed `/tmp`. W26's report write was rejected before process creation; W21 later preserved its returned findings without claiming a Python execution. W27's successful hash check survived as a report/terminal outcome, but its optional detailed JSON was lost before copying.

W21 recreated all ten private paths at the same input without cleanup. Final coordinator verification found ten clean detached paths, ten reports and twelve readable retained probe artifacts. Those recovery verifications are attributed to W21. Fresh-context counting comes from the ten actual runtime IDs, not recreated directories or followups.

