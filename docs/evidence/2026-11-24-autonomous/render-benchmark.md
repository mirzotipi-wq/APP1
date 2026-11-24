# Portable study renderer baseline — 2026-11-24

## Finding and scope

On this shared Linux CPU host, the 144×96 mannequin fixture takes **140.659 ms median** with three 8×8 rectangular emitters, compared with **6.913 ms** with three point emitters (20.35×). An isolated 1,000-receiver batch takes **5.067 ms without visibility** and **28.771 ms with the actual mannequin visibility callback**. The measured difference is 23.704 ms, or 82.4% of the visibility-enabled batch time. This identifies the visibility path as a useful optimization target; it is not a function-level profile or a proven speedup estimate.

All 56 measured complete renders matched their workload's warm-up image byte for byte, with zero unsupported pixels. All 12 cancellation probes threw `StudyError.cancelled`; the largest recorded deadline-to-return delay was **3.122 ms**. The complete final benchmark workload took **2.680298 seconds**, excluding compilation and JSON encoding. The benchmark uses bounded iteration counts and no sleeps.

These are **portable CPU diagnostics only**. They do not pass the physical iPhone 13 performance gate, establish a GPU/Metal result, measure an interactive app frame rate, or measure thermal behavior, memory, photographic fidelity or accessibility. No quality score or milestone is promoted by this packet. The renderer was not changed.

## Provenance and environment

| Item | Recorded value |
|---|---|
| Renderer baseline revision | `d7a6830ef2f869ec2f35cde4e041e9384d2bfda8` |
| Date | 2026-11-24 UTC |
| OS | Debian GNU/Linux 13 (trixie), Linux kernel 6.18.57 |
| Architecture / compiler target | x86_64 / x86_64-unknown-linux-gnu |
| CPU model exposed by `/proc/cpuinfo` | AMD EPYC 9V74 80-Core Processor |
| Logical processors exposed | 9 (`ProcessInfo` and `getconf _NPROCESSORS_ONLN`) |
| Compiler | Swift 6.4.3 (`swift-6.4.3-RELEASE`) |
| Build flags | `swiftc -O`; no whole-module, unchecked-optimization or special CPU flags supplied |
| Concurrency of benchmark | One synchronous process, fixed workload order |
| Host controls | Shared container; no CPU affinity, frequency lock or exclusive-host control |
| Final harness SHA-256 | `e3fbbcea0e5b02bfb105298045b69d1727e26f7104765904d715484c471a3a9f` |
| Final executable SHA-256 | `39ea9a6106e98230ba599960b8842d4f1efe65f61748bc2dde875e94c97fb085` |
| Raw final JSON SHA-256 | `3387a975366cdb71c5519d5be807fc36c839faea430700a1f8a260937a65d3ee` |

The CPU model string is not a claim that 80 physical cores were available. `lscpu` could not enumerate topology because `/sys/devices/system/cpu/possible` was not exposed. Wall time includes host scheduling and contention from concurrent development work. Short samples show visible variation and should not be treated as hardware specifications.

`sourceRevision` identifies the unchanged renderer baseline, not a claim of a clean whole-repository checkout. The shared worktree also contained the new, unrelated `LightingProjectDocument.swift` while compiling the wildcard source set. All tracked core source files matched the stated baseline; a full compile-input source manifest is included below. The three renderer files were checked again after the run and remained unchanged.

## Reproduction

Run from the repository root with Swift 6.4.3 available on `PATH`. The actual compiler executable in this session was `/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc`.

```sh
swiftc --version
swiftc -O Sources/LightingCore/*.swift scripts/benchmark-study.swift -o /workspace/scratch/73dcd6a65726/verification/render-benchmark
/workspace/scratch/73dcd6a65726/verification/render-benchmark --samples 7 --revision d7a6830ef2f869ec2f35cde4e041e9384d2bfda8 > /workspace/scratch/73dcd6a65726/verification/render-benchmark-canonical.json
```

For a later source version, supply that version's revision rather than copying this revision label. The script also accepts `--samples` from 3 through 21; the default is 7. It refuses a debug-assert build. Final compilation and execution returned exit status 0, with no diagnostics. The final raw JSON is embedded at the end of this report so the evidence does not depend on a transient executable or output file.

## Fixed fixtures and measurement method

The sphere and mannequin use the same scene, camera and emitters. The subject is at `(0, 1.5, 0)` meters, the camera at `(0, 1.60, 1.7)` meters, with an 85 mm full-frame 36×24 mm lens, 5600 K white balance and +1.25 exposure stops. Source positions and intensity are the existing portrait recipe:

| Light | Position in meters | Candela | Kelvin | Area variant dimensions |
|---|---|---:|---:|---|
| Key | (−1.5, 2.1, 1.2) | 900 | 5600 | 1.0×1.2 m |
| Fill | (1.5, 1.7, 1.5) | 300 | 5600 | 0.8×0.8 m |
| Rim | (0.8, 2.2, −1.2) | 450 | 3200 | 0.4×0.8 m |

Point3 uses three isotropic point sources. Area3 uses rectangles with the existing default source orientation and the renderer's interactive 8×8 midpoint quadrature: **192 source samples per receiver**, versus 3 for point3. Area12 is a cancellation stress case only: each of the three rectangular sources is repeated four times with unique fixed UUIDs and one quarter of its original candela, producing 768 source samples per receiver. The renderer's original maximum of 12 lights is retained.

There is no random sampling or random seed. Geometry, camera rays, emitter grids, receiver selection and light UUIDs are fixed. Each complete-render workload receives one measured warm-up, followed by seven measured calls; output comparison and FNV-1a checksum calculation occur outside the timing interval. Full-frame time includes the public render call's setup, validation, direct lighting, intersections, color transformation and RGBA output. The first mannequin warm-up also initializes the shared head mesh/BVH; it is reported separately and is not evidence of a repeatable cold-start distribution.

Timing uses `DispatchTime.now().uptimeNanoseconds`, a monotonic clock. p50 and p95 use nearest rank, `ceil(p × n) − 1`, on sorted samples. **With seven samples, p95 is the maximum observed sample**, not a statistically reliable production tail estimate. No samples or outliers were removed. Earlier development runs of the harness informed its output schema; only the final harness run is the canonical baseline below, with all of its measurements retained. There has been no renderer optimization or before/after speedup comparison.

## Whole-frame measurements

All values below are milliseconds per completed render.

| Workload | Pixels | Source samples / receiver | Warm-up | p50 | p95 |
|---|---|---:|---:|---:|---:|
| sphere-point3-72 | 72×48 | 3 | 0.675 | 0.648 | 0.718 |
| sphere-point3-144 | 144×96 | 3 | 3.293 | 2.482 | 2.906 |
| sphere-area3-72 | 72×48 | 192 | 16.889 | 14.597 | 15.165 |
| sphere-area3-144 | 144×96 | 192 | 67.770 | 56.918 | 68.393 |
| bust-point3-72 | 72×48 | 3 | 34.248 | 1.927 | 2.493 |
| bust-point3-144 | 144×96 | 3 | 8.768 | 6.913 | 8.240 |
| bust-area3-72 | 72×48 | 192 | 33.687 | 44.556 | 49.212 |
| bust-area3-144 | 144×96 | 192 | 156.546 | 140.659 | 164.839 |

### Raw frame samples and output checks

All seven samples, in execution order, are included. FNV-1a is a noncryptographic output fingerprint for quick comparisons; the actual determinism check compared complete `StudyImage` values. Every recorded image had zero unsupported pixels.

| Workload | Seven measured milliseconds | RGBA FNV-1a 64 |
|---|---|---|
| sphere-point3-72 | 0.648011, 0.672798, 0.581552, 0.544577, 0.604326, 0.718205, 0.682642 | `44040625ad4aa562` |
| sphere-point3-144 | 2.906158, 2.876424, 2.482219, 2.359427, 2.206831, 2.288402, 2.579254 | `7ee862b85545eb4d` |
| sphere-area3-72 | 15.164900, 14.861130, 14.375841, 14.481597, 13.963018, 14.596869, 15.156908 | `2fc527b7cb7f76cf` |
| sphere-area3-144 | 56.826580, 56.917583, 55.688071, 56.188979, 58.569933, 68.392655, 60.839828 | `569c3081461f54c1` |
| bust-point3-72 | 1.889100, 1.734171, 2.083057, 1.934668, 1.926977, 1.808771, 2.492936 | `2359c769f1e22b62` |
| bust-point3-144 | 8.240426, 6.865347, 6.669897, 6.913448, 6.695746, 6.982210, 7.685984 | `3477fe1a9b3ba564` |
| bust-area3-72 | 34.542565, 49.212051, 44.779180, 33.536043, 44.657188, 44.555618, 42.538353 | `48caa59a611dd5f7` |
| bust-area3-144 | 130.472110, 140.659147, 164.838509, 153.132397, 131.508311, 129.157161, 141.343120 | `f7d2b587a3b675a0` |

## Visibility isolation

The harness casts a fixed 12×8 camera-ray grid once and retains the **34 actual visible receivers**. Each retains its hit location, shading normal, geometric normal, view direction and real mannequin material. A batch cycles deterministically through those receivers for **1,000 evaluations**. `StudyLighting` construction, receiver selection, primary-ray intersections, image allocation and display color conversion are outside the timed batch. The evaluator still computes its direct-light material/color response; every output component is accumulated and emitted as `signalComponentSum` so it cannot be discarded as an unused result. One complete batch warms each configuration before seven measured batches.

Visibility Off passes no occlusion callback. Visibility On invokes the actual finite-segment `PortraitGeometry.occludes`, including panel, head BVH and analytic parts. Both retain geometric-normal hemisphere checks. This controlled toggle measures the combined visibility path; it does **not** isolate the BVH from the analytic parts or attribute costs to individual machine instructions. Because blocked samples skip their later material response, the timing difference is a net change, not a pure sum of visibility calls.

| Workload | Visibility | p50 ms / 1,000 | p95 ms / 1,000 | Seven measured milliseconds |
|---|---|---:|---:|---|
| bust-point3-receivers | Off | 0.099 | 0.170 | 0.100219, 0.169731, 0.098476, 0.098486, 0.098717, 0.122842, 0.098346 |
| bust-point3-receivers | On | 0.385 | 0.406 | 0.406392, 0.385412, 0.372653, 0.388215, 0.372652, 0.372743, 0.384640 |
| bust-area3-receivers | Off | 5.067 | 5.787 | 5.067261, 4.992270, 5.005259, 4.993953, 5.466884, 5.786958, 5.085298 |
| bust-area3-receivers | On | 28.771 | 35.749 | 28.770925, 35.749164, 34.964060, 29.448314, 22.343492, 22.579982, 24.448512 |

The area-source batch expands the sample loop by 64×. Both the whole-frame and receiver results support prioritizing area-source visibility. The mannequin also carries primary-intersection and geometry setup costs absent from this isolation; do not extrapolate the microbenchmark percentage directly to the full frame.

## Cancellation measurements

Each probe renders the actual 144×96 mannequin and supplies the public cancellation callback. At every poll, the callback reads monotonic elapsed time, returns false before a 5 ms or 25 ms target, and true at the first poll at or after it. Each target/workload is repeated three times. The table records every probe, including the immediately preceding false poll, first true poll, return time and callback count. **All probes cancelled successfully.**

This is deadline-to-observation and unwind behavior of the synchronous CPU API. No background task, actor scheduler or UI event was used, so these results do not measure real task-cancellation delivery or visible responsiveness. The renderer currently polls before setup, at row boundaries and on completion. The largest recorded interval straddling a target was **5.126 ms**; this is not a bound on every row or every possible scene.

| Probe | Workload | Target ms | Polls | Prior false poll ms | True poll ms | Returned ms | Return − target ms |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | bust-area3-144 | 5 | 27 | 4.703933 | 6.226019 | 6.245168 | 1.245168 |
| 2 | bust-area3-144 | 5 | 27 | 4.547361 | 5.954958 | 5.956040 | 0.956040 |
| 3 | bust-area3-144 | 5 | 26 | 3.011955 | 5.446774 | 5.448477 | 0.448477 |
| 4 | bust-area3-144 | 25 | 37 | 24.633987 | 26.515376 | 26.521175 | 1.521175 |
| 5 | bust-area3-144 | 25 | 38 | 24.120095 | 25.913203 | 25.919362 | 0.919362 |
| 6 | bust-area3-144 | 25 | 38 | 23.645523 | 25.422136 | 25.428285 | 0.428285 |
| 7 | bust-area12-144 | 5 | 24 | 3.004604 | 6.885357 | 6.887870 | 1.887870 |
| 8 | bust-area12-144 | 5 | 24 | 2.939578 | 7.004614 | 7.007498 | 2.007498 |
| 9 | bust-area12-144 | 5 | 24 | 3.589521 | 7.352109 | 7.354742 | 2.354742 |
| 10 | bust-area12-144 | 25 | 28 | 23.080484 | 28.117571 | 28.122088 | 3.122088 |
| 11 | bust-area12-144 | 25 | 28 | 21.263200 | 26.183274 | 26.187470 | 1.187470 |
| 12 | bust-area12-144 | 25 | 28 | 21.985691 | 27.111620 | 27.117679 | 2.117679 |

## Source-supported next optimization

1. **First measure a finite-segment BVH visibility optimization.** `StudyLighting.evaluate` calls `PortraitGeometry.occludes` for each contributing source sample. `PortraitHeadMesh.occludes` recursively visits bounding boxes; `Bounds.intersects` currently divides by the same ray direction for each visited node and each nonparallel axis. Precomputing reciprocal direction and parallel-axis flags once per shadow ray is a specific, limited candidate. Preserve the existing padded bounds, near-parallel branch, two-sided triangle intersection, finite segment limits and geometric-normal shadow offset. This recommendation is an inference from the measured visibility-path cost plus source inspection; a profiler has not demonstrated that division itself dominates.
2. **Keep source sampling and geometry fidelity fixed during that experiment.** Retain the 8×8 rectangle grid and same fixture outputs; reducing samples would change the image/accuracy contract and would not establish an equivalent optimization. Re-run the independent brute-force BVH oracle, complete renderer tests and this exact harness on the same host/configuration. Require matching fixture RGBA, zero unsupported pixels and no segment-boundary regressions before accepting a speedup. Shared-host timing noise requires repeat paired runs if an improvement is close to the observed spread.
3. **If real UI cancellation measurements expose a gap, evaluate polling between small pixel blocks.** Row-only polling leaves a full row's lighting work between checks; adding a check after a bounded number of pixels is a narrower candidate than a check for every light sample. This benchmark establishes successful cancellation and the recorded intervals, not a device responsiveness defect or a universal latency guarantee. Re-measure overhead and actual Swift-task delivery before adopting the change.

No renderer change was made in this work package. Physical-device sustained frame times, GPU behavior, memory and thermal gates remain unverified.

## Compile-input source manifest

SHA-256 values captured after the final compile and run. Tracked core files had no diff from the baseline at that check. `LightingProjectDocument.swift` was new unrelated work in the shared worktree and is listed explicitly for provenance.

```text
f3d78baddf790d0ee7e3025e6e6f2b4b9645bfa2ee38cf46b3b6cb0913ab92f3  Sources/LightingCore/CameraFraming.swift
60898dc1b407679eccf51f94b45080027a36b252ef0ba6c508de23ee717b961e  Sources/LightingCore/Colorimetry.swift
3f55b9ea5495ef8f0eb03fca70094c25d09ec79f22d98ae8bf19e4d04136fa5a  Sources/LightingCore/GuidedLighting.swift
d13b475f48f3b43af408560838612e238002d54020366e27e88aab8cf9be7321  Sources/LightingCore/LightingPlan.swift
90336f0dec27880ecde5783dae89041c2e9e4aa3ea00c4d39388c4eea62808fd  Sources/LightingCore/LightingProjectDocument.swift
2cec669eae1b088c1a1e314a0e4f552ef7622e174d98d4ba796b6354c6a1e5d6  Sources/LightingCore/LightingRecipe.swift
d458166326832afdeee976b1f7ce5e58dc22e529f1dc5cb1473e2bba955a1a77  Sources/LightingCore/PortraitHeadMesh.swift
daef90e14efbf5085fae910d1e9ce246519f83ec9715447332e4db195be58568  Sources/LightingCore/PortraitStudy.swift
0b6689015a9102d5b5ca6f309553455b48c047534432bc2c2b99726a242d73c4  Sources/LightingCore/ProjectLibrary.swift
a4c9a478de099976d7ef7b6d7292493559f81821476c0ccf582773960ca3df64  Sources/LightingCore/ReferencePNG.swift
c6f313b5371cb004bfca47bb5d3e736d0eae279ef2ef56f43c70e6c9e8eb28f7  Sources/LightingCore/ReferenceStudy.swift
9e02a860c74ab296a38b15eaee57c1dee4b85df1efbe3aba7c9baf03d8672863  Sources/LightingCore/ReferenceTonalSummary.swift
4282003ebf74dee3e27146aeab254fd310f2c8d015e52431edf02c49d97c9e0b  Sources/LightingCore/RoomPlacement.swift
fbd552b5f35fa3fbacc10099b25eadf5853ab2bc9ae7013975db83c302513c74  Sources/LightingCore/Scene.swift
f411f4f57bae222a60802686bccee78fb418f75f8102030dcc8931a4f90622ee  Sources/LightingCore/SceneCodec.swift
0084bf564d8a7f2f01426ad0880146ae733800a7e79bceda03ad2a5f243e653e  Sources/LightingCore/SceneEditHistory.swift
4e1411ae2633433a173f6c49a0d36a3e99248794c83a8865b297d7377dcd5d83  Sources/LightingCore/SceneFileStore.swift
357b59ad21434f86e1c3faad391502a349fe94347c603654063e1905cd897321  Sources/LightingCore/StudioDisplayName.swift
1e12c4d5b0a9ba73ee90b56bf3f7f263bdb9b97aa7e6a5be4b553f5d2de14cfd  Sources/LightingCore/StudioNumericInput.swift
e1164e03f70d154a9d3b07c8d377bf2ac0b3c621079edb8093cf2fb9038ca284  Sources/LightingCore/StudioOptics.swift
05480eeac51b8564a499c000fc5418439be6067897408e2cc4b4ae11406c1206  Sources/LightingCore/StudioSceneBounds.swift
57a4aea6b75499ffd6740a979a395e4524e7ea32508b0d0590c87416fb244c6a  Sources/LightingCore/StudyValidationFixtures.swift
eb3e68a3723eab4d1de37b868a6f5cb26fbb1201fca48ee6cb33895c488718ee  Sources/LightingCore/SurfacePhotometry.swift
```

## Complete raw final report

```json
{
  "architecture" : "x86_64",
  "cancellation" : [
    {
      "cancelled" : true,
      "checks" : 27,
      "deadlineToReturnMilliseconds" : 1.2451679999999996,
      "finishedAfterMilliseconds" : 6.245168,
      "name" : "bust-area3-144",
      "observedAtMilliseconds" : 6.226019,
      "precedingCheckAtMilliseconds" : 4.703933,
      "requestedAfterMilliseconds" : 5
    },
    {
      "cancelled" : true,
      "checks" : 27,
      "deadlineToReturnMilliseconds" : 0.9560399999999998,
      "finishedAfterMilliseconds" : 5.95604,
      "name" : "bust-area3-144",
      "observedAtMilliseconds" : 5.954958,
      "precedingCheckAtMilliseconds" : 4.547361,
      "requestedAfterMilliseconds" : 5
    },
    {
      "cancelled" : true,
      "checks" : 26,
      "deadlineToReturnMilliseconds" : 0.44847699999999957,
      "finishedAfterMilliseconds" : 5.448477,
      "name" : "bust-area3-144",
      "observedAtMilliseconds" : 5.446774,
      "precedingCheckAtMilliseconds" : 3.011955,
      "requestedAfterMilliseconds" : 5
    },
    {
      "cancelled" : true,
      "checks" : 37,
      "deadlineToReturnMilliseconds" : 1.5211749999999995,
      "finishedAfterMilliseconds" : 26.521175,
      "name" : "bust-area3-144",
      "observedAtMilliseconds" : 26.515376,
      "precedingCheckAtMilliseconds" : 24.633987,
      "requestedAfterMilliseconds" : 25
    },
    {
      "cancelled" : true,
      "checks" : 38,
      "deadlineToReturnMilliseconds" : 0.9193619999999996,
      "finishedAfterMilliseconds" : 25.919362,
      "name" : "bust-area3-144",
      "observedAtMilliseconds" : 25.913203,
      "precedingCheckAtMilliseconds" : 24.120095,
      "requestedAfterMilliseconds" : 25
    },
    {
      "cancelled" : true,
      "checks" : 38,
      "deadlineToReturnMilliseconds" : 0.4282849999999989,
      "finishedAfterMilliseconds" : 25.428285,
      "name" : "bust-area3-144",
      "observedAtMilliseconds" : 25.422136,
      "precedingCheckAtMilliseconds" : 23.645523,
      "requestedAfterMilliseconds" : 25
    },
    {
      "cancelled" : true,
      "checks" : 24,
      "deadlineToReturnMilliseconds" : 1.8878700000000004,
      "finishedAfterMilliseconds" : 6.88787,
      "name" : "bust-area12-144",
      "observedAtMilliseconds" : 6.885357,
      "precedingCheckAtMilliseconds" : 3.004604,
      "requestedAfterMilliseconds" : 5
    },
    {
      "cancelled" : true,
      "checks" : 24,
      "deadlineToReturnMilliseconds" : 2.007498,
      "finishedAfterMilliseconds" : 7.007498,
      "name" : "bust-area12-144",
      "observedAtMilliseconds" : 7.004614,
      "precedingCheckAtMilliseconds" : 2.939578,
      "requestedAfterMilliseconds" : 5
    },
    {
      "cancelled" : true,
      "checks" : 24,
      "deadlineToReturnMilliseconds" : 2.354742,
      "finishedAfterMilliseconds" : 7.354742,
      "name" : "bust-area12-144",
      "observedAtMilliseconds" : 7.352109,
      "precedingCheckAtMilliseconds" : 3.589521,
      "requestedAfterMilliseconds" : 5
    },
    {
      "cancelled" : true,
      "checks" : 28,
      "deadlineToReturnMilliseconds" : 3.1220880000000015,
      "finishedAfterMilliseconds" : 28.122088,
      "name" : "bust-area12-144",
      "observedAtMilliseconds" : 28.117571,
      "precedingCheckAtMilliseconds" : 23.080484,
      "requestedAfterMilliseconds" : 25
    },
    {
      "cancelled" : true,
      "checks" : 28,
      "deadlineToReturnMilliseconds" : 1.1874700000000011,
      "finishedAfterMilliseconds" : 26.18747,
      "name" : "bust-area12-144",
      "observedAtMilliseconds" : 26.183274,
      "precedingCheckAtMilliseconds" : 21.2632,
      "requestedAfterMilliseconds" : 25
    },
    {
      "cancelled" : true,
      "checks" : 28,
      "deadlineToReturnMilliseconds" : 2.117678999999999,
      "finishedAfterMilliseconds" : 27.117679,
      "name" : "bust-area12-144",
      "observedAtMilliseconds" : 27.11162,
      "precedingCheckAtMilliseconds" : 21.985691,
      "requestedAfterMilliseconds" : 25
    }
  ],
  "cpuModel" : "AMD EPYC 9V74 80-Core Processor",
  "fixtureDefinition" : "No random sampling or seed: fixed midpoint quadrature and stable fixture light UUIDs. Portrait recipe; camera (0,1.60,1.7)m, 85mm full-frame lens, 5600K white balance, +1.25 stops. Point3 uses recipe point emitters. Area3 replaces them with 1x1.2m, 0.8x0.8m and 0.4x0.8m rectangles, 8x8 samples each. Area12 repeats each area light four times at one quarter intensity for cancellation only.",
  "frames" : [
    {
      "height" : 48,
      "lightSamplesPerSurface" : 3,
      "name" : "sphere-point3-72",
      "rgbaFNV1a64" : "44040625ad4aa562",
      "timing" : {
        "p50Milliseconds" : 0.648011,
        "p95Milliseconds" : 0.718205,
        "samplesMilliseconds" : [
          0.648011,
          0.672798,
          0.581552,
          0.544577,
          0.604326,
          0.718205,
          0.682642
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 0.67451,
      "width" : 72
    },
    {
      "height" : 96,
      "lightSamplesPerSurface" : 3,
      "name" : "sphere-point3-144",
      "rgbaFNV1a64" : "7ee862b85545eb4d",
      "timing" : {
        "p50Milliseconds" : 2.482219,
        "p95Milliseconds" : 2.906158,
        "samplesMilliseconds" : [
          2.906158,
          2.876424,
          2.482219,
          2.359427,
          2.206831,
          2.288402,
          2.579254
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 3.292501,
      "width" : 144
    },
    {
      "height" : 48,
      "lightSamplesPerSurface" : 192,
      "name" : "sphere-area3-72",
      "rgbaFNV1a64" : "2fc527b7cb7f76cf",
      "timing" : {
        "p50Milliseconds" : 14.596869,
        "p95Milliseconds" : 15.1649,
        "samplesMilliseconds" : [
          15.1649,
          14.86113,
          14.375841,
          14.481597,
          13.963018,
          14.596869,
          15.156908
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 16.889437,
      "width" : 72
    },
    {
      "height" : 96,
      "lightSamplesPerSurface" : 192,
      "name" : "sphere-area3-144",
      "rgbaFNV1a64" : "569c3081461f54c1",
      "timing" : {
        "p50Milliseconds" : 56.917583,
        "p95Milliseconds" : 68.392655,
        "samplesMilliseconds" : [
          56.82658,
          56.917583,
          55.688071,
          56.188979,
          58.569933,
          68.392655,
          60.839828
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 67.770356,
      "width" : 144
    },
    {
      "height" : 48,
      "lightSamplesPerSurface" : 3,
      "name" : "bust-point3-72",
      "rgbaFNV1a64" : "2359c769f1e22b62",
      "timing" : {
        "p50Milliseconds" : 1.926977,
        "p95Milliseconds" : 2.492936,
        "samplesMilliseconds" : [
          1.8891,
          1.734171,
          2.083057,
          1.934668,
          1.926977,
          1.808771,
          2.492936
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 34.248059,
      "width" : 72
    },
    {
      "height" : 96,
      "lightSamplesPerSurface" : 3,
      "name" : "bust-point3-144",
      "rgbaFNV1a64" : "3477fe1a9b3ba564",
      "timing" : {
        "p50Milliseconds" : 6.913448,
        "p95Milliseconds" : 8.240426,
        "samplesMilliseconds" : [
          8.240426,
          6.865347,
          6.669897,
          6.913448,
          6.695746,
          6.98221,
          7.685984
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 8.768448,
      "width" : 144
    },
    {
      "height" : 48,
      "lightSamplesPerSurface" : 192,
      "name" : "bust-area3-72",
      "rgbaFNV1a64" : "48caa59a611dd5f7",
      "timing" : {
        "p50Milliseconds" : 44.555618,
        "p95Milliseconds" : 49.212051,
        "samplesMilliseconds" : [
          34.542565,
          49.212051,
          44.77918,
          33.536043,
          44.657188,
          44.555618,
          42.538353
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 33.687128,
      "width" : 72
    },
    {
      "height" : 96,
      "lightSamplesPerSurface" : 192,
      "name" : "bust-area3-144",
      "rgbaFNV1a64" : "f7d2b587a3b675a0",
      "timing" : {
        "p50Milliseconds" : 140.659147,
        "p95Milliseconds" : 164.838509,
        "samplesMilliseconds" : [
          130.47211,
          140.659147,
          164.838509,
          153.132397,
          131.508311,
          129.157161,
          141.34312
        ]
      },
      "unsupportedPixels" : 0,
      "warmupMilliseconds" : 156.546046,
      "width" : 144
    }
  ],
  "measuredSamplesPerWorkload" : 7,
  "methodology" : "One warm-up per workload; monotonic wall time; nearest-rank p50\/p95. Deterministic synchronous CPU renders. Cancellation uses monotonic deadlines in the real callback, not asynchronous UI scheduling. Receiver microbenchmarks omit image\/color conversion and primary intersections. Short-run shared-host diagnostics, not physical-device, GPU, thermal, memory or sustained frame-rate evidence.",
  "operatingSystem" : "Debian GNU\/Linux 13 (trixie)",
  "optimizedBuild" : true,
  "reportedActiveProcessors" : 9,
  "reportedProcessors" : 9,
  "sourceRevision" : "d7a6830ef2f869ec2f35cde4e041e9384d2bfda8",
  "totalWorkloadMilliseconds" : 2680.297955,
  "visibility" : [
    {
      "evaluationsPerSample" : 1000,
      "lightSamplesPerSurface" : 3,
      "name" : "bust-point3-receivers",
      "receivers" : 34,
      "signalComponentSum" : 265741.3705473256,
      "timing" : {
        "p50Milliseconds" : 0.098717,
        "p95Milliseconds" : 0.169731,
        "samplesMilliseconds" : [
          0.100219,
          0.169731,
          0.098476,
          0.098486,
          0.098717,
          0.122842,
          0.098346
        ]
      },
      "visibilityEnabled" : false
    },
    {
      "evaluationsPerSample" : 1000,
      "lightSamplesPerSurface" : 3,
      "name" : "bust-point3-receivers",
      "receivers" : 34,
      "signalComponentSum" : 263414.6483679028,
      "timing" : {
        "p50Milliseconds" : 0.38464,
        "p95Milliseconds" : 0.406392,
        "samplesMilliseconds" : [
          0.406392,
          0.385412,
          0.372653,
          0.388215,
          0.372652,
          0.372743,
          0.38464
        ]
      },
      "visibilityEnabled" : true
    },
    {
      "evaluationsPerSample" : 1000,
      "lightSamplesPerSurface" : 192,
      "name" : "bust-area3-receivers",
      "receivers" : 34,
      "signalComponentSum" : 184274.47029927865,
      "timing" : {
        "p50Milliseconds" : 5.067261,
        "p95Milliseconds" : 5.786958,
        "samplesMilliseconds" : [
          5.067261,
          4.99227,
          5.005259,
          4.993953,
          5.466884,
          5.786958,
          5.085298
        ]
      },
      "visibilityEnabled" : false
    },
    {
      "evaluationsPerSample" : 1000,
      "lightSamplesPerSurface" : 192,
      "name" : "bust-area3-receivers",
      "receivers" : 34,
      "signalComponentSum" : 181446.83898944466,
      "timing" : {
        "p50Milliseconds" : 28.770925,
        "p95Milliseconds" : 35.749164,
        "samplesMilliseconds" : [
          28.770925,
          35.749164,
          34.96406,
          29.448314,
          22.343492,
          22.579982,
          24.448512
        ]
      },
      "visibilityEnabled" : true
    }
  ]
}
```
