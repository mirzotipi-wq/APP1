# Float32 distance-boundary audit and stable sphere intersection

## Scope and decision

This is actual **host execution of the shared `App/StudyKernel.h` Float32 kernel**, compared with Swift's independently retained Double renderer. It is not Metal execution, a device benchmark, a calibrated photograph comparison or a complete precision-domain proof.

The baseline was renderer source at `0fce248b4e61bace88002b40f6c56fddedb19c8a`, copied into an isolated source snapshot before later cancellation work. Relevant source hashes are retained below. Measurements used Debian 13 x86_64, Swift 6.4.3 and its bundled clang++ with C++17 / `-O2 -Wall -Wextra -Werror`; fixture generation used `swiftc -O`.

**Accepted correction:** use a stable closest-approach sphere intersection in the shared Float32 kernel. The Double geometry and oracle were not changed. The six established parity fixtures pass, including the existing 84/84 invalid-pixel check. Eight additional ordinary far-camera/translation controls now match the Double RGB image byte for byte. A new optional strict host-harness criterion makes the old kernel fail those controls and the corrected kernel pass.

**Separate unresolved boundary at this observation:** quantizing source positions and receiver geometry to Float32 can still change a pixel's classification arbitrarily close to the 5 cm exclusion cutoff. The failures are retained below. The subsequent [eligibility packet](float32-eligibility.md) implements conservative CPU routing and verifies all 14 held-out cutoff cases route away from Float32. This raw-kernel report retains its failures and does not claim the raw kernel itself became exact.

## Correct precision domain

At the audited revision, `MetalStudyRenderer.supports` checks **camera and light distance from the subject at most 20 m**, not absolute world coordinates. `StudyComputeInput` subtracts the subject in Double before packing Float32. Large positive and negative world translations were therefore included as controls, not treated as unsupported merely because an absolute coordinate exceeds 20 m.

The 33 held-out fixtures use 192×128 images:

- Six area-light scenes at camera distances 19, 19.999999 and 20 m, with 85 and 200 mm lenses.
- Nine exact or perturbed silhouette-tangent scenes at 1, 19.999999 and 20 m. The focal length is derived from the closed-form tangent angle so a pixel lies on the prescribed radius-0.22 m silhouette.
- Fourteen near-cutoff point-light scenes at camera distances 1 and 20 m. The source is positioned along the normal of the Double receiver at pixel (95,63), at `0.05 + epsilon` metres for epsilon −1e−4, −1e−6, −1e−8, 0, +1e−8, +1e−6 and +1e−4. The light has 100 cd and 5600 K.
- Two point-source scenes with the light at 19.999999 and 20 m from the subject.
- Two translations of the 20 m / 200 mm area scene by (77,70,75) and (−77,−70,−75) metres, within the scene's valid absolute coordinate bounds.

`precision-boundary.swift` creates deterministic light IDs, actual packed compute buffers, complete Double RGBA reference images, exact scene JSON and a metadata manifest. No fixture has an invalid scene or an original camera/light relative distance above 20 m.

## Why the sphere formula changed

The old discriminant subtracts `b*b - c`, where both terms are approximately 400 for a 20 m camera, to recover a quantity at most `0.22²`. Float32 cancellation displaced the reconstructed surface enough to create false self-shadowing. The existing aggregate parity threshold allowed these errors because the distant sphere occupies a small fraction of the whole frame: one ordinary fixture had maximum channel error 187 and 0.439453% of channels differed by more than four levels, still below the unchanged 0.5% outlier limit.

For ray `o + t d`, the correction computes the closest parameter `tc = −dot(o,d)/dot(d,d)`, closest point `q = o + tc*d`, and roots `tc ± sqrt((r² − dot(q,q))/dot(d,d))`. Keeping `dot(d,d)` matters because a Float32 normalized direction is not exactly unit length. This avoids subtraction of the two large squared distances while retaining the caller's minimum-distance semantics.

The six ordinary area controls and both translations went from maximum channel errors 67–187 to **zero**; their invalid counts also remain equal. Both distant point-light controls were already exact and remain exact. Tangent fixtures retain small boundary-pixel differences within the original parity criteria; exact silhouette equality across floating-point types is not asserted.

## Existing and strict regression results

- Existing six 96×64 fixtures: **6/6 passed** before and after. Corrected maximum channel error is one; hard, dark and near-field fixtures are exact. Near-field invalid count remains **84/84**.
- Eight additional far-camera/translation controls with `--maximum-channel-error 1`: **old kernel 0/8 passed, corrected kernel 8/8 passed**. All corrected controls actually have zero channel error.
- Optional flag checks: values −1, 256, `nan`, `1x`, and a missing fixture are rejected with exit code 2. Default aggregate thresholds and existing invocation syntax are unchanged.
- Complete 33-fixture diagnostic run under the original aggregate criteria: **baseline 29/33 passed; corrected 28/33 passed**. The difference consists of cutoff-mask cases, not an omitted or weakened test. These cases require the separate CPU-routing decision.

## Full held-out results

Invalid counts are written `Float32/Double`. Maximum error is an 8-bit RGB channel difference. The pass/fail columns use the original mean ≤1, outlier fraction ≤0.005 and equal invalid-count criteria, not the optional stricter criterion.

| Fixture | Old maximum | Corrected maximum | Invalid counts, old → corrected | Original parity, old → corrected |
| --- | ---: | ---: | --- | --- |
| `area-camera-19.0-lens-200` | 187 | 0 | 49/49 → 49/49 | PASS → PASS |
| `area-camera-19.0-lens-85` | 180 | 0 | 9/9 → 9/9 | PASS → PASS |
| `area-camera-19.999999-lens-200` | 87 | 0 | 19/19 → 19/19 | PASS → PASS |
| `area-camera-19.999999-lens-85` | 140 | 0 | 13/13 → 13/13 | PASS → PASS |
| `area-camera-20.0-lens-200` | 127 | 0 | 19/19 → 19/19 | PASS → PASS |
| `area-camera-20.0-lens-85` | 67 | 0 | 13/13 → 13/13 | PASS → PASS |
| `light-distance-19.999999` | 0 | 0 | 0/0 → 0/0 | PASS → PASS |
| `light-distance-20.0` | 0 | 0 | 0/0 → 0/0 | PASS → PASS |
| `near-mask-camera-1.0-epsilon--0.0001` | 1 | 1 | 45/45 → 45/45 | PASS → PASS |
| `near-mask-camera-1.0-epsilon--1e-06` | 1 | 1 | 1/1 → 1/1 | PASS → PASS |
| `near-mask-camera-1.0-epsilon--1e-08` | 253 | 253 | 0/1 → 0/1 | FAIL → FAIL |
| `near-mask-camera-1.0-epsilon-0.0` | 253 | 253 | 0/1 → 0/1 | FAIL → FAIL |
| `near-mask-camera-1.0-epsilon-0.0001` | 1 | 0 | 0/0 → 0/0 | PASS → PASS |
| `near-mask-camera-1.0-epsilon-1e-06` | 0 | 0 | 0/0 → 0/0 | PASS → PASS |
| `near-mask-camera-1.0-epsilon-1e-08` | 0 | 1 | 0/0 → 0/0 | PASS → PASS |
| `near-mask-camera-20.0-epsilon--0.0001` | 205 | 0 | 1/1 → 1/1 | PASS → PASS |
| `near-mask-camera-20.0-epsilon--1e-06` | 205 | 252 | 1/1 → 0/1 | PASS → FAIL |
| `near-mask-camera-20.0-epsilon--1e-08` | 205 | 252 | 1/1 → 0/1 | PASS → FAIL |
| `near-mask-camera-20.0-epsilon-0.0` | 205 | 252 | 1/1 → 0/1 | PASS → FAIL |
| `near-mask-camera-20.0-epsilon-0.0001` | 205 | 0 | 0/0 → 0/0 | PASS → PASS |
| `near-mask-camera-20.0-epsilon-1e-06` | 252 | 0 | 1/0 → 0/0 | FAIL → PASS |
| `near-mask-camera-20.0-epsilon-1e-08` | 252 | 0 | 1/0 → 0/0 | FAIL → PASS |
| `tangent-1.0-scale-0.9999999` | 24 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-1.0-scale-1.0` | 24 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-1.0-scale-1.0000001` | 0 | 0 | 0/0 → 0/0 | PASS → PASS |
| `tangent-19.999999-scale-0.9999999` | 24 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-19.999999-scale-1.0` | 0 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-19.999999-scale-1.0000001` | 0 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-20.0-scale-0.9999999` | 24 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-20.0-scale-1.0` | 0 | 24 | 0/0 → 0/0 | PASS → PASS |
| `tangent-20.0-scale-1.0000001` | 0 | 24 | 0/0 → 0/0 | PASS → PASS |
| `world-translation--77` | 127 | 0 | 19/19 → 19/19 | PASS → PASS |
| `world-translation-77` | 127 | 0 | 19/19 → 19/19 | PASS → PASS |

At 1 m, the corrected kernel reports zero invalid pixels where Double reports one for epsilon −1e−8 and 0. At 20 m, it reports zero where Double reports one for epsilon −1e−6, −1e−8 and 0. A different rounding path can change which side disagrees; changing the 5 cm physical/numerical model cutoff or relaxing parity would conceal the loss of input information. The probe retains all 14 cutoff cases so future eligibility work can verify that every ambiguous case routes to CPU.

## Reproduction

Run from the repository with Swift and clang++ available:

```sh
precision_dir="$(mktemp -d)"
swiftc -O Sources/LightingCore/*.swift scripts/precision-boundary.swift -o "$precision_dir/prepare"
"$precision_dir/prepare" "$precision_dir/fixtures"
clang++ -std=c++17 -O2 -Wall -Wextra -Werror scripts/verify-kernel-host.cpp -o "$precision_dir/verify"
"$precision_dir/verify" --maximum-channel-error 1 "$precision_dir"/fixtures/area-camera-*.bin "$precision_dir"/fixtures/world-translation-*.bin
"$precision_dir/verify" "$precision_dir"/fixtures/*.bin
```

The last command intentionally exposes the retained cutoff failures when raw Float32 is forced across all fixtures. It does not model a later CPU eligibility guard. The strict eight-control command must pass. Existing `prepare-kernel-fixtures.swift` plus the default host verifier preserves the six-fixture regression.

## Exact source and evidence hashes

- Baseline `App/StudyKernel.h`: `69a91e8b50e0d531fb6bf200ee89cfcbfbb07f880e447ff293fb81cf02ec4205`.
- Baseline `Sources/LightingCore/ReferenceStudy.swift`: `4a0333b472d71936a489785c3f9b632dbb3f4b747208a2f9485bd3b828e930c2`.
- Baseline `Sources/LightingCore/SurfacePhotometry.swift`: `eb3e68a3723eab4d1de37b868a6f5cb26fbb1201fca48ee6cb33895c488718ee`.
- Baseline `Sources/LightingCore/CameraFraming.swift`: `f3d78baddf790d0ee7e3025e6e6f2b4b9645bfa2ee38cf46b3b6cb0913ab92f3`.
- Baseline `Sources/LightingCore/Colorimetry.swift`: `60898dc1b407679eccf51f94b45080027a36b252ef0ba6c508de23ee717b961e`.
- Baseline `App/MetalStudyRenderer.swift`: `f53b9cdc951ed611007d627b681ee45a0d12779a9bfe2726d481b229d5bee82e`.
- Corrected/deliverable `App/StudyKernel.h`: `ec67e54f98698741c15fddf543967bdeb1596aa183b488e7414cde4b397e33f7`.
- Corrected/deliverable `scripts/precision-boundary.swift`: `dc62c1091974aaf5b481cff217fa9e05e1f491af4e0a174bd7c118b4bb598bd5`.
- Corrected/deliverable `scripts/verify-kernel-host.cpp`: `02a5f31856ad5ffbd8299da25a348b3e92ff9608f7ca6b39b2d5b9bec52d2e01`.
- Scratch evidence `kernel.log`: `1389eae6d87dea686563ec30c13f38c40a2c05560af31c148e8dfd1cac21723b`.
- Scratch evidence `kernel-candidate.log`: `c3d59d3bf902d33915ac8c2a98a2887d085f5fafb4551d60f3010c05d5c66d91`.
- Scratch evidence `runtime-baseline.log`: `719f3c018bcfac17f1128d2008614d5fc13680a342d3dca62029611fe7e47cde`.
- Scratch evidence `runtime-candidate.log`: `111e233f9dd61aa99a82ac791cbf8f02bb7bec7eca8e28c7cdd6740eb8373ae3`.
- Scratch evidence `strict-baseline.log`: `84657e7649725e41e40b02b84932e311801a29f15bce4de189ae304b0be07a93`.
- Scratch evidence `strict-corrected.log`: `48c7c37c8c9245dde5f3a6804ee2efd5eab76357184f917d7321da9d5bcda0db`.
- Scratch evidence `strict-summary.json`: `e0f2f85760df1c8c04731584fec81cc4e26ada5671276c1cf9846b4c7b15c002`.
- Scratch evidence `fixtures/manifest.json`: `cd15837fc0627daa7f7d2f786a17a1c20140b368fad8985b863d38852e6840a3`.

Complete scratch evidence is under `/workspace/scratch/73dcd6a65726/verification/float32-boundary/`; fixture scenes and buffers are reproducible from the committed script. The table preserves every diagnostic outcome in the repository. Native shader compilation, real Metal behavior and device performance remain unverified.
