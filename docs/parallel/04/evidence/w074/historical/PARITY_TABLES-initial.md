# Key & Fill lane 04 parity and precision evidence

## Scope and reading rules

Frozen by worker 074 for wave 8 against input `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. The authoritative role packet is blob `7e17185f497cc4f85d54b44b87b0128e2b01d60c`; table schema is blob `a10154e1b24b0428df4abbd92af62a9044d688d4`. This document extracts retained execution; it does not report a new test run.

The shipped Swift Double CPU renderer is the reference for H6/H8/M6/M8. H6/H8 execute the shared Float32 kernel in a host C++ harness. M6/M8 execute actual Metal kernels on an iOS simulator. Their distinct source revisions, commands and logs are binding: the older simulator pass does not establish execution of later renderer changes or source7 cache additions. Mocked lifecycle tests, Swift CPU-only tests, requested buffer arithmetic and physical-device results are separate evidence classes.

**NR means not reported by the retained output**, not zero. RGB statistics are per channel. The “outliers” native print is `fractionAboveFour`, not a count. Neither harness prints the integer count of channels above four; every count cell therefore remains NR, even when the fraction is zero. Dimensions come from the pinned constructors/metadata rather than the parity print. Host `invalid=candidate/reference` is reordered into the two table count columns. Native unsupported counts are NR; they are not copied from host output. A nonzero unsupported count is compatible with exact mask equality.

Acceptance remains unchanged: canonical mean RGB error ≤1, fraction of channels with error >4 ≤0.005, matching unsupported counts and **every mask position**; strict eight additionally require maximum channel error ≤1. Canonical maximum is descriptive, not an added acceptance threshold. Cache limits remain four completed frames, 262144 RGBA bytes, 65536 mask bytes; mannequin is CPU-only with width ≤144. Those resource limits are not measurements in this table.

## Evidence identities and commands

Each row's evidence ID binds it to the complete provenance below.

| ID | Evidence class and exact tested source | Run / job | Raw log / metadata blobs | Terminal scope |
|---|---|---|---|---|
| H6 / H8 | Host C++ shared Float32 vs shipped Swift Double; `240000fd3f8cb75273eb279be9dcc7f204a5b29f` | [45848953002](https://github.com/mirzotipi-wq/APP1/actions/runs/45848953002) / `140009926092` | `b99b8d092e34a136b6e00e14e4b8e83b1ecd98e8` / `8d53d8b3bafdb8a9b5f079a583390be7ee827ae2` | Core job success; 379 Debug +379 Release tests, zero failures; six canonical and eight selected strict rows PASS |
| M6 / M8 | Actual simulator Metal vs shipped Swift Double; `88279ba0ee0262ea6c880580c8a85b56342abbff` | [45837392344](https://github.com/mirzotipi-wq/APP1/actions/runs/45837392344) / `139973865345` | `a87b4e2c42f5bd753c8312c95f22b6bd302bb78c` / `0ebfcebb81be765fc6b55cb5dbe41793fa672aeb` | 160 native methods, zero failures/skips; both parity methods passed; finalized XCTest export and method accounting passed |

Retained originals: [host log](evidence/ci/wave06-core-140009926092.log), [host metadata](evidence/ci/wave06-core-140009926092.json), [native log](evidence/ci/wave04-native-139973865345.log), [native metadata](evidence/ci/wave04-native-139973865345.json). Worker-specific raw aliases and machine-readable row extraction are in [the receipt](evidence/w074/input-receipt.json) and [retained-ci-extract.json](evidence/w074/retained-ci-extract.json).

H6/H8 ran on Ubuntu 24.04.5 x86_64 with Swift 6.4.3. Native ran on hosted Intel macOS 26.6.1, Apple Swift 6.3.3, Xcode 26.6 build 17F113 and iOS simulator SDK 26.5; this is not physical iPhone execution. The relevant commands below are copied from retained logs. They were not rerun by this worker.

H6:

```sh
swiftc -O Sources/LightingCore/*.swift scripts/prepare-kernel-fixtures.swift -o "$RUNNER_TEMP/prepare-kernel-fixtures"
"$RUNNER_TEMP/prepare-kernel-fixtures" "$RUNNER_TEMP/kernel-fixtures"
clang++ -std=c++17 -O2 -Wall -Wextra -Werror scripts/verify-kernel-host.cpp -o "$RUNNER_TEMP/verify-kernel-host"
"$RUNNER_TEMP/verify-kernel-host" "$RUNNER_TEMP"/kernel-fixtures/*.bin | tee study-kernel.log
```

H8 reuses that host verifier:

```sh
swiftc -O Sources/LightingCore/*.swift scripts/precision-boundary.swift -o "$RUNNER_TEMP/prepare-precision-boundary"
"$RUNNER_TEMP/prepare-precision-boundary" "$RUNNER_TEMP/precision-boundary"
"$RUNNER_TEMP/verify-kernel-host" --maximum-channel-error 1 \
  "$RUNNER_TEMP"/precision-boundary/area-camera-*.bin \
  "$RUNNER_TEMP"/precision-boundary/world-translation-*.bin | tee study-precision.log
```

The generator reports **33 prepared probes**, but this command selects only the six area-camera and two world-translation fixtures. It does not establish that all 33 probes passed.

M6/M8 used the same Debug XCTest command:

```sh
/Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug -destination id=12FCFD0F-7FCF-463F-A605-132A7E18B5D5 -derivedDataPath /Users/runner/work/_temp/keyfill-build -parallel-testing-enabled NO -resultBundlePath NativeTests.xcresult CODE_SIGNING_ALLOWED=NO "-only-testing:KeyAndFillTests" test-without-building
```

M6 method: `StudyRendererTests/testMetalMatchesCPUOnAvailableDevice`. M8 method: `StudyPrecisionMatrixTests/testMetalMatchesCPUForEightRequiredPrecisionFixtures`. Both throw `XCTSkip` without a Metal device; the retained run executed both and reports no skips. A future skip is unverified parity, never a passing row.

The host `core-test-log` artifact is `15132856675` (archive SHA256 `f36fe8e3a7c195882951aad9a1ab094ea7cbe3b450b3ad7d19c87601b962ff3c`). Native full artifact is `15130376495` (SHA256 `a656c267c87b6412be447c1b99f6f73542f37829e336e355f95068c045c15ec0`); compact artifact is `15130446442` (SHA256 `13025033fa75f2a997c276a80d8033fb5d77520051fddc21f9ad3c58d76408b5`). These are retained upload receipts, not newly downloaded archives.

## Exact fixture and assertion source identities

| Source path | Git blob SHA | Scope verified |
|---|---|---|
| `Sources/LightingCore/StudyValidationFixtures.swift` | `555677e7baf0931b6c629b635f617a9cc2356800` | Canonical six and StudyParityMetrics; same blob at input, host source and historical native source |
| `scripts/prepare-kernel-fixtures.swift` | `be419f64796e72d0523099ca783d0e15d490a293` | Canonical width96 generator; same at input and tested host source |
| `scripts/precision-boundary.swift` | `a8260cc021ea45aab5d1649ed8283e36a807e0ae` | Strict constructors, width192, UUID normalization and ≤20m relative guards; same at input and tested host source |
| `scripts/verify-kernel-host.cpp` | `6885ead6bb9c76679a4cef1cd84d457c7bd460e6` | Shared-kernel execution, mask mismatch count, exact thresholds and strict flag; same at input and tested host source |
| `NativeTests/StudyRendererTests.swift` | `ffe6a6804eb3aa1bf4268331ff1ec52eeba9a119` | Canonical raw Metal width96 and metrics.passes assertion; same at input and historical native source |
| `NativeTests/StudyPrecisionMatrixTests.swift` | `e101657aeea929186b0059df6963ee33d17769a5` | Eight strict raw Metal cases and mask/max assertions; same at input and historical native source |

Worker073 independently agrees with worker074 on strict fixture equivalence; [fixture review](evidence/w073/fixture-review.json) blob `a8901c224c1c3c8b6c13708bcfa9f66aa1d80d3a` and [source identities](evidence/w073/source-hashes.json) blob `a4799cb6148d1f8ff26158931dcbfa9fc67e07f0` retain that review. Both constructors use the canonical `soft` scene; camera distances `[19.0, 19.999999, 20.0]` crossed with focal lengths `[85.0, 200.0]`. Camera x/y equal subject x/y and z equals subject z plus distance. Both translations start from `fixtures[5]` (20m/200mm) and use offsets `(77,70,75)` and `(-77,-70,-75)`, moving subject, camera, all light positions and explicit aim targets. Both validate the scene, normalize UUIDs with `00000000-0000-4000-8000-%012d`, and guard camera distance and maximum light distance relative to the subject at ≤20m. Canonical names are identical except the host file extension `.bin`.

Both native methods deliberately call `renderValidationFixture`, exercising raw Metal kernels without production precision routing satisfying the comparison with CPU output. This is a validation bypass, not permission for production to publish an ineligible Metal frame. The matrix does not assert production supports(scene,width) for each strict case. Near-field validation also bypasses the normal engine's CPU route. Strict8 already shipped in wave4; this documentation introduces no new tests.

For M6, the print says only `invalid match true` (count equality). Exact mask equality is established by the passing `metrics.passes` assertion because `passes` requires `invalidMaskMatches`; no mismatch count is printed. For M8, `mask true` is printed and exact `Data` equality is asserted separately, alongside `metrics.passes` and max≤1. No native table cell turns those assertions into an emitted numerical mismatch count.

## Host canonical six (H6)

| Evidence | Exact emitted fixture name | Pixels | Mean RGB error | Max | >4 count | >4 fraction | Swift CPU unsupported | Backend unsupported | Exact-mask evidence | Terminal |
|---|---|---:|---:|---:|---|---:|---|---|---|---|
| H6 | `dark.bin` | 96×64 | 0 | 0 | NR | 0 | 0 | 0 | Printed mismatches = 0 | PASS |
| H6 | `hard.bin` | 96×64 | 0 | 0 | NR | 0 | 0 | 0 | Printed mismatches = 0 | PASS |
| H6 | `near-field.bin` | 96×64 | 0 | 0 | NR | 0 | 84 | 84 | Printed mismatches = 0 | PASS |
| H6 | `soft.bin` | 96×64 | 5.42535e-05 | 1 | NR | 0 | 0 | 0 | Printed mismatches = 0 | PASS |
| H6 | `translated.bin` | 96×64 | 5.42535e-05 | 1 | NR | 0 | 0 | 0 | Printed mismatches = 0 | PASS |
| H6 | `warm-rotated.bin` | 96×64 | 0 | 0 | NR | 0 | 0 | 0 | Printed mismatches = 0 | PASS |

The two nonzero means retain the host's printed precision `5.42535e-05`; they are not expanded from another backend's output. The near-field case intentionally contains 84 unsupported pixels at matching positions.

## Host strict eight (H8)

| Evidence | Exact emitted fixture name | Pixels | Mean RGB error | Max | >4 count | >4 fraction | Swift CPU unsupported | Backend unsupported | Exact-mask evidence | Terminal |
|---|---|---:|---:|---:|---|---:|---|---|---|---|
| H8 | `area-camera-19.0-lens-200.bin` | 192×128 | 0 | 0 | NR | 0 | 49 | 49 | Printed mismatches = 0 | PASS |
| H8 | `area-camera-19.0-lens-85.bin` | 192×128 | 0 | 0 | NR | 0 | 9 | 9 | Printed mismatches = 0 | PASS |
| H8 | `area-camera-19.999999-lens-200.bin` | 192×128 | 0 | 0 | NR | 0 | 19 | 19 | Printed mismatches = 0 | PASS |
| H8 | `area-camera-19.999999-lens-85.bin` | 192×128 | 0 | 0 | NR | 0 | 13 | 13 | Printed mismatches = 0 | PASS |
| H8 | `area-camera-20.0-lens-200.bin` | 192×128 | 0 | 0 | NR | 0 | 19 | 19 | Printed mismatches = 0 | PASS |
| H8 | `area-camera-20.0-lens-85.bin` | 192×128 | 0 | 0 | NR | 0 | 13 | 13 | Printed mismatches = 0 | PASS |
| H8 | `world-translation--77.bin` | 192×128 | 0 | 0 | NR | 0 | 19 | 19 | Printed mismatches = 0 | PASS |
| H8 | `world-translation-77.bin` | 192×128 | 0 | 0 | NR | 0 | 19 | 19 | Printed mismatches = 0 | PASS |

All eight rows explicitly print `max-limit=1` and PASS. Their unsupported masks match exactly despite nonzero counts.

## Actual simulator Metal canonical six (M6)

| Evidence | Exact emitted fixture name | Pixels | Mean RGB error | Max | >4 count | >4 fraction | Swift CPU unsupported | Backend unsupported | Exact-mask evidence | Terminal |
|---|---|---:|---:|---:|---|---:|---|---|---|---|
| M6 | `hard` | 96×64 | 0.0 | 0 | NR | 0.0 | NR | NR | Passing metrics.passes assertion | PASS |
| M6 | `soft` | 96×64 | 5.425347222222222e-05 | 1 | NR | 0.0 | NR | NR | Passing metrics.passes assertion | PASS |
| M6 | `warm-rotated` | 96×64 | 0.0 | 0 | NR | 0.0 | NR | NR | Passing metrics.passes assertion | PASS |
| M6 | `dark` | 96×64 | 0.0 | 0 | NR | 0.0 | NR | NR | Passing metrics.passes assertion | PASS |
| M6 | `near-field` | 96×64 | 0.0 | 0 | NR | 0.0 | NR | NR | Passing metrics.passes assertion | PASS |
| M6 | `translated` | 96×64 | 5.425347222222222e-05 | 1 | NR | 0.0 | NR | NR | Passing metrics.passes assertion | PASS |

All six emitted `invalid match true`. Only the retained passing method and unchanged `StudyParityMetrics.passes` source establish exact mask equality; native unsupported counts and mismatch counts remain unreported.

## Actual simulator Metal strict eight (M8)

| Evidence | Exact emitted fixture name | Pixels | Mean RGB error | Max | >4 count | >4 fraction | Swift CPU unsupported | Backend unsupported | Exact-mask evidence | Terminal |
|---|---|---:|---:|---:|---|---:|---|---|---|---|
| M8 | `area-camera-19.0-lens-85` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `area-camera-19.0-lens-200` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `area-camera-19.999999-lens-85` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `area-camera-19.999999-lens-200` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `area-camera-20.0-lens-85` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `area-camera-20.0-lens-200` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `world-translation-77` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |
| M8 | `world-translation--77` | 192×128 | 0.0 | 0 | NR | 0.0 | NR | NR | Printed true + Data assertion | PASS |

All eight emitted `mask true`, and the containing method passed its max≤1 and exact-mask assertions. A zero RGB error does not by itself prove mask equality; the printed boolean and assertions provide that evidence.

## Retained historical silhouette failure

This is a **host shared Float32 kernel versus independent C++ Double geometry transcription**, not a shipped Swift oracle run and not Metal execution.

| Evidence class | Source / exact blobs | Recorded command / fixture | Dimensions | Mean / max | >4 count / fraction | CPU / backend unsupported | Exact mask basis | Terminal |
|---|---|---|---:|---|---|---|---|---|
| Host C++ Float vs independent C++ Double transcription | Baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`; source `47ca11b56f33b9fca12100440f3aa134bbd25d14`; raw `9ebe4cd92827148c0a93c000269a08040a43b22b`; metadata `0936a84266df00d19ffde54232343f615025bdfe` | O2 command below; unnamed fixed no-light probe, focal `161.27198111190464`, distance3m, radius0.22m | 24×16 | 0.1076388888888889 /24 | NR /0.005208333333333333 | Swift CPU N/A /candidate0 printed | **Not reported**; candidate.w==0 count only, no mask comparison | **FAIL** existing fraction≤0.005; reproduction exit0 means the failure was reproduced |

```sh
g++ -std=c++17 -O2 -ffp-contract=off -Wall -Wextra -Werror docs/parallel/04/evidence/silhouette-probe.cpp -o /workspace/scratch/2987b1ee980d/build04/silhouette-probe && /workspace/scratch/2987b1ee980d/build04/silhouette-probe
```

Retained platform: Linux 6.18.57 x86_64 with glibc2.41; g++ Debian14.2.0-19. The raw output identifies pixels (9,0) and (14,0), C++ Double reference RGB(0,0,0), shared RGB(18,20,24), and Double discriminant `5.9699800658563618e-11`. The source fixes reference alpha at255 but does not perform or print a mask comparator. Do not relabel candidate `invalid=0` as measured exact-mask equality. Only an O2 command was reviewed here; no O0 outcome is asserted. Later Swift tests checking those two reference pixels do not establish a whole-frame Swift/Metal comparison.

Originals remain at [silhouette metadata](evidence/silhouette-probe-baseline.json), [raw output](evidence/silhouette-probe-baseline.log), and [source](evidence/silhouette-probe.cpp).

## Current limits and handoff

| Evidence or state | Status at this freeze | Permitted interpretation |
|---|---|---|
| Source6 native job `140012314020`, source `240000fd3f8cb75273eb279be9dcc7f204a5b29f` | Runtime running; root has not supplied terminal evidence | Build success is not a native execution pass. H6/H8 pass is not M6/M8 execution at source6. Root alone polls. |
| Native5 | Cancelled | Never a pass; no fabricated per-case outcome |
| Source7 `NativeTests/StudyRenderCacheTests.swift`, blob `dd068965cf56312ea0feb90578ca9461ba6b1054` | Four appended methods; 25 prior methods preserved,29 total; additions uncompiled/unrun | No source7 runtime claim. This file is distinct from unchanged renderer and precision test files. |
| Current production renderer (`App/MetalStudyRenderer.swift`) | Blob `8c1acd852d85cd99671feaba883db1808bbb5e68` from root source manifest `4c50a638a8c1fbb85461ed4de152addc03903175` | Newer than retained wave4 runtime; do not carry that old full-app pass forward without corresponding evidence |
| Swift CPU and mocked deterministic lifecycle evidence | Separate classes; no rows relabeled as Metal | H/M rows compare against the CPU oracle; mock labels do not prove GPU work |
| Algebra / requested buffer arithmetic | Separate class | Dimensions, products and cache targets do not measure RSS or driver allocation |
| Physical-device / calibration / thermal evidence | Unperformed | Simulator and host execution establish no physical-device result |
| Local execution | Unavailable since wave5; unrun and unprobed by074 | No local shell, SDK, compiler, hash-object, CI poll or rerun performed |

The **03/20 consumer adoption dependency remains unresolved**: A/Metal is shown, B confirms permanent downgrade plus cancellation, and returning to A may bypass the engine through a UI-held frame. This is a current-status/adoption mismatch; it is not established engine-cache leakage. The owner proposal remains unapplied/uncompiled without owner acknowledgment or a UI pass.

Only root integrates. This candidate changes documentation and evidence records; production, oracle, ABI, scripts, tests, configuration and UI are untouched. Planned worker/result directories are uncreated. Later terminal receipts may append source-specific rows without overwriting these historical outcomes.
