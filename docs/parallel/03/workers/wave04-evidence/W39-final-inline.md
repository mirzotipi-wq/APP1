## W39 platform/performance reconciliation

**Identity:** runtime/canonical path `/root/wave04/platform_performance`; role W39. Assigned worktree `/tmp/keyfill03-7f4b/workers/W39-platform-performance` remained inaccessible. Immutable GitHub inspection and JavaScript arithmetic only; no local tests, builds, changes, or persistence.

**Pinned inputs:** repository `mirzotipi-wq/APP1`; source `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`; retained evidence commit `03d5823f59b92b68d634303ef443af49be84a1bf`; native log blob `2f8854b794a4df4eb7ed19a0446478a98fa8d33c`. Read the four mandatory instructions plus affected source, benchmark implementation and native renderer tests.

**Source binding verified.** `github_fetch_file` plus independent JS SHA-256, checked against the known `abc` digest, reproduced all three manifest hashes:

- `PortraitStudy.swift`: `cdc88507467f31b4e873a8579aa08b954c846dfdb7d2594ed0fc94f51f751db8`; Git blob `8784480e13099dffbffaad8c8e9ad837316e5ab9`.
- `App/ReferenceStudyPreview.swift`: `f609041d40414637955ff8cf1d143c3269c0305a7a0dba8d937c845e95ecf4e2`.
- `NativeTests/StudyPreviewPipelineTests.swift`: `4d609ac715176d372bc3d0af408f8bf3892633c8f70b238d2284881578213b79`.

**Retained CPU results:** Debug and Release each contain exactly **383 passed cases, zero failures/skips**, with terminal totals matching the manifest; 14.500/6.295 seconds respectively. Platform is Swift 6.2.1, x86_64 Linux. Log blobs: Debug `2397fa0356224d26de9c7b431d6d264a7101abf7`; Release `9989526f2153adaf0a450bed3867ebe3f2545025`.

**Benchmark verified:** blob `4f5c8ea4ca8b7c6d873a02c408943ad7c31fb178` names ace9, Debian 13, AMD EPYC 9V74, optimized CPU execution. Inventory is eight frames: sphere/bust × point3/area3 × 72/144; twelve cancellation probes: area3/area12 bust144 × 5/25 ms × three; four visibility workloads: point3/area3 × enabled/disabled, 34 receivers and 1,000 evaluations/sample. Frame/visibility workloads retain seven samples; frame warm-ups exist, unsupported counts are zero, and all twelve probes report cancellation. Source enforces repeated-frame equality.

JS nearest-rank recomputation matched reported values:

| Workload | p50 ms | p95 ms |
|---|---:|---:|
| sphere-point3-72 | 0.651399 | 0.807533 |
| bust-area3-144 | 166.168528 | 210.596648 |

**Native scope:** isolated the native XCTest section from earlier host tests: **163 started/passed, zero failures/skips; nine pipeline methods**. Log checks out ace9 and records successful Debug `xcodebuild … -only-testing:KeyAndFillTests test-without-building`, Xcode 26.6, iPhone 17 Pro **simulator**, iOS 26.5. Actual Metal outputs cover hard, soft, warm-rotated, dark, near-field and translated fixtures; maximum channel difference ≤1 and invalid masks match. These exercise sphere/panel GPU rendering. Mannequin rendering remains CPU, with native routing coverage. This is neither physical-device performance nor Release native-test evidence.

**Candidate limitation:** retained results bind the older near-plane-clipped intersection implementation. They do **not** validate candidate PortraitStudy SHA-256 `f406fb496129d82f81dc429cc3bb002fc1b168b5ed771edcff8e449d5e2757cb`. Root’s 384 Debug result predates W34’s extra test; W34’s seven emitter methods are reported separately. Neither establishes candidate Release/native/benchmark/image acceptance. Revalidate affected checks against integrated candidate bytes. No mismatch found in checked bindings, counts or percentiles.
