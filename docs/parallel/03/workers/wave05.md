# Wave 5 — bounded tiny direct-light response

**Complete: ten actual workers; accepted for root integration with explicit numerical scope.** No worker committed, pushed, merged, deleted a worktree or claimed native/device acceptance. Root alone publishes `finish/03-cpu-study-mannequin`.

## Immutable input and deliverable

All workers started from `c9ff1a71c173774e7b7c794e475f8bdf5d633853` in separate detached trees from `/tmp/keyfill03-7f4b/worker-control`. The initially absent control clone was recreated with shared immutable objects, sparse evidence exclusion and the original GitHub promisor remote. Persistent-volume free space was46MiB at setup; no cleanup was performed.

The correction is private to `StudyLighting`: positive emitters whose per-sample Double candela is subnormal or rounds to zero are prepared at unit output; each completed emitter’s visible lux, unoccluded lux and material XYZ are scaled once by original candela. Ordinary sample arithmetic/order, material equations, clipping, visibility, guards, counts, packed ABI and renderer/cancellation code remain unchanged. GPU packing restores candela before Float conversion, so these extreme inputs still pack as zero.

Original implementation patch and original tests remain in `wave05-evidence`. Root corrected the test-only ambiguous `pow` expression with an explicit Double annotation. The final reviewable two-file patch is [W44-implementation-root-corrected.patch](wave05-evidence/W44-implementation-root-corrected.patch); SHA256 `9287f45928ef86a121c0702c3de79893d3cc2e8b80b64a63945d2f5b4aa9b695`. Production SHA256 is `4ac702653392d64586d0a472576da64ebe3f68dad7339954232f7c5f6635b141`; corrected test Git blob is `04fbfd955802014332f57fcd9753273cd65e8304`. Corrected patch application check passed against the immutable W41 tree.

## Actual execution and retained failures

All Swift executions below belong to root; specialist source/arithmetic checks are labeled separately in their reports.

| Check | Actual result | Evidence |
|---|---|---|
| Frozen W42 public-API original probe | compile0; probe1;166checks/56failures | `wave05-evidence/W42-original-inputs.json`, `W42-original-result.log` |
| Same unchanged probe on candidate | compile0; probe0;166checks/0failures | `wave05-evidence/W42-candidate-compile.log`, `W42-candidate-result.log` |
| Initial full Debug compilation | compiler signal9 before tests; no test outcome | `../evidence/wave05-debug.log` |
| Empty retry / serial nonbatch compile | earlier exit1 retained; then ambiguous pow compile error before tests | root receipt; `../evidence/wave05-debug-serial.log` |
| Corrected full Debug |391tests/0failures;14.265s;session23298 exit0 | `../evidence/wave05-debug-corrected.log` |
| Release default WMO compilation | compiler signal9 before tests; no test outcome | `../evidence/wave05-release.log` |
| Optimized per-file Release |391tests/0failures;6.356s;session17319 exit0 | `../evidence/wave05-release-serial.log` |

Debug used `-j1 -Xswiftc -disable-batch-mode`; successful Release additionally used `-Xswiftc -no-whole-module-optimization`. Compiler/toolchain is Swift6.2.1 Linux. Per-file optimization is not a standard-WMO or native run. The earlier c9 CI source predates this tiny-output patch.

## Acceptance scope and findings

The preserved failing probe uses supported receiver separation and finite ordinary unit-output responses. It covers full/clipped rectangles at64/1024 samples plus tilted point/directional GGX, with frozen positive/finite/unit-linearity and independent closed-form expectations. Five focused package methods cover mixed-light ordering, support guards and exact packed geometry/rows. W41 exact source comparisons and W45’s bounded-work review found no changed sample/pixel evaluation path.

W43/W47 confirm original positive Double output controls activity and guards even when Float32 packing is zero. Exact-zero output remains inactive. W47 retrieved both exact cross-lane consumer blobs and preserves source receipts. W48’s finite-case quantization witnesses remain black in RGB8; there is no new UI, persistence, photo or network path. W46 finds unchanged maximum prepared counts768interactive/12288reference. Added field data is logically6KiB/96KiB at those counts, not measured allocation or RSS.

W50 independently accepts intensity scaling and preserves three limits: outside-trigger normal-candela cosine underflow, extreme half-vector squared-length underflow, and separate extreme-grazing BRDF overflow. These Python witnesses are not Swift tests. The patch does not claim universal extreme-input correctness, visible light from negligible output, physical calibration, device performance or native accessibility.

## Actual worker accounting

Each canonical path below is the actual identifier returned by the tool; no separate UUID was supplied. There are nine fresh specialist contexts plus W41. Precreated trees and followups do not increase the count.

| Worker | Role | Actual runtime ID | Report |
|---|---|---|---|
| W41 | acceptance | `/root/wave05` | [W41-acceptance.md](W41-acceptance.md) |
| W42 | geometry/data | `/root/wave05/w42_geometry` | [W42-geometry.md](W42-geometry.md) |
| W43 | API | `/root/wave05/w43_api` | [W43-api.md](W43-api.md) |
| W44 | implementation | `/root/wave05/w44_implementation` | [W44-implementation.md](W44-implementation.md) |
| W45 | concurrency | `/root/wave05/w45_concurrency` | [W45-concurrency.md](W45-concurrency.md) |
| W46 | resource | `/root/wave05/w46_resource` | [W46-resource.md](W46-resource.md) |
| W47 | consumer | `/root/wave05/w47_consumer` | [W47-consumer.md](W47-consumer.md) |
| W48 | accessibility/privacy | `/root/wave05/w48_accessibility_privacy` | [W48-accessibility-privacy.md](W48-accessibility-privacy.md) |
| W49 | platform/performance | `/root/wave05/w49_platform_performance` | [W49-platform-performance.md](W49-platform-performance.md) |
| W50 | independent-review | `/root/wave05/w50_independent_review` | [W50-independent-review.md](W50-independent-review.md) |

## Remaining integration evidence

No wave-worker blocker remains. Root keeps standard-WMO/native current-source CI separate and carries the final campaign requirements for twelve ordinary render outputs/hashes, six parity fixtures with exact masks, eight precision fixtures, and the optimized eight-frame/twelve-cancellation/four-visibility host benchmark. Earlier results may only be carried with explicit unchanged-source justification. Timing remains diagnostic.

W49 listed these three categories before the final Release receipt; its report has an attributed coordinator closeout update. Its two failed candidate reads came from shortened brief paths missing `docs/parallel/03/`, not lost canonical artifacts. All corrections and prior failures remain visible. Full machine-readable accounting, source identities and root receipts are in [wave05.json](wave05.json). Artifact hashes are in [wave05-artifacts.json](wave05-artifacts.json). Root must verify remote preservation before any worker-tree cleanup.
