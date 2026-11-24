# Development completion checkpoint — 2026-11-24

## Source-six final results and source-seven publication packet

Published/tested source remains **`22e51d7f85b709840128c11b0501be86a4c99c03`**, tree **`ba3c1a5cc68a3596d2050976419b26ef76ce7bac`**. Root read [run 45490703826](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826) at **22:22:48 UTC**: **completed/cancelled**, attempt **1**, `updated_at` **22:20:36Z**. The run conclusion differs from its job results: core, native and studio succeeded; room failed; library was cancelled before tests. The cancellation cause remains unknown. **100 assignments** remain recorded.

**M01 was initially accepted at c74c3b7 and is revalidated at 22e51d7 by current native and direct studio smoke. M02 remains active with scoped photometry pass; rendering/performance remain unresolved. M03–M07 remain pending.** Source seven is an unpublished candidate with no runtime acceptance. No targeted source-six rerun was requested; its normal new-source CI will provide fresh library verification.

### Exact source-six native and studio evidence

Core passed **261 Debug / 261 Release / 28 Python**, plus the recorded syntax, shard, parity and precision checks. Native job **138789718752** completed success. Root read its finalized **828,403-byte** log at **21:52 UTC**. Debug `BUILD SUCCEEDED` occurred **21:33:02.976868Z**, Release **21:36:58.538634Z**. **84/84 native methods passed**, zero failures, **24.398 s test / 24.962 s overall**; embedded All tests finished **21:49:48.957**, `TEST SUCCEEDED` **21:51:15.371452Z**. All three SpatialPreview methods and actual Metal/CPU match (**4.318 s**), parity and cancellation methods passed. No native test-skip lines occurred; “Skipped export” messages concern absent attachments.

Studio job **138789718925** completed **success: 11/11**, zero failures, **740.970 s test / 740.987 s overall**. Suite finish was **21:58:44.919**, `TEST EXECUTE SUCCEEDED` **21:58:47.776318Z**; root read the finalized **533,856-byte** log at **21:59:41 UTC**. Both Export methods passed (**86.349 / 138.056 s**). Studio methods passed: Camera **71.613**, Corrupt **20.820**, Meter **79.815**, Optics **76.472**, Recipe **62.278**, SettingsFeet3DFitAndSimulatorARManualFallback **79.343**, Guide **64.811**, Sphere **23.635**, Mannequin **37.778 seconds**. This directly verifies **actual 3D entry, Fit, Feet and unsupported-AR manual fallback**, original optics acceptance and foundation smoke at this exact source. It does not verify the later Arrangement extension.

### Actual 3D visual review

Root and specialist 90 independently reviewed genuine PNG **`8554DB46-28D8-4A25-9B76-2A4393475479.png`** from the studio compact artifact. The central subject, three light heads/stands, camera and floor are inside the viewport with no obvious crop. Both captions are readable and untruncated; selected 3D, three-light count, Fit and Feet status are complete, and the toolbar is unobstructed. Substantial empty space above and low-contrast stands/camera remain, though discernible. This is an **actual still-image review**, not gesture, performance, calibration or physical-device RealityKit acceptance.

### Terminal room and full UI inventory

Room job **138789718719 failed**. Root read the finalized **473,175-byte** log at **22:21 UTC**. All five methods completed: **four passed, one failed**, **1170.333 s test / 1170.463 s overall**. Selected tests finished **22:17:30.428**; `TEST EXECUTE FAILED` was **22:19:12.850430Z**, exit **65**. ManualRoom passed **122.997 s**; Resize failed **266.799 s**; PrecisionCamera **248.644 s**, Intensity **260.192 s** and Modifier **271.700 s** passed. Result export succeeded.

The Resize failure was the **second status expectation immediately after closing notes**, at `ManualRoomPlacementUITests.swift:58`. Root and specialist 90 independently inspected the trace and actual PNG **`1BC9EA46-A17C-45D2-A53A-CCE144B4F72D.png`**. The `exists` check consumed approximately **14.22 seconds of the unchanged 15-second deadline**, without a logged label Find. Actual captured state showed correct committed **6 m** notes and preserved subject **3**. Later diagnostics found one `Other` with the correct **All 5…** label and finite frame. **The failed assertion remains a failure.** These observations do not prove whether simulator/framework behavior or app snapshot delay caused the wait.

| Source-six UI shard | Executed/completed | Passed | Failed | Unexecuted | Job conclusion |
|---|---:|---:|---:|---:|---|
| Studio/export | 11 | 11 | 0 | 0 | Success |
| Room/precision | 5 | 4 | 1 | 0 | Failure |
| Library/reference | 0 | 0 | 0 | 11 | Cancelled before tests |
| **Total** | **16** | **15** | **1** | **11** | No interrupted methods |

The original library cancellation, its zero executed tests and its boot/toolchain-only artifact remain retained below. No application assertion ran in that job. Normal source-seven CI replaces the abandoned targeted retry plan; **no source-six rerun request was made**.

| Actual source-six artifact | Bytes | SHA-256 |
|---|---:|---|
| [Native compact 14968023187](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14968023187) | 332,368 | `bb66c0a51653f04ab85703b8660d5b1014cf8248b6ae2cb37372f1e5c07269b7` |
| [Native full 14967558752](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14967558752) | 77,762,112 | `b9ceb8099a9869a551a079c68f47989f804eec748da2449a57fb8c84455a73a5` |
| [Studio compact 14969325330](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14969325330) | 3,398,333 | `b4054f2a8bbc4e5c6147da2aa6be85f3e127355efd62017eb9cbc3e8f3eed2c2` |
| [Studio full 14969300526](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14969300526) | 9,521,124 | `983703f7d3b22f1dea7c3f31716cf7ed1dbcbe7a218199876879b91c2869e8c7` |
| [Room compact 14969727633](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14969727633) | 1,460,529 | `08fc8425f695c26bf301eb4d32c92fad940616a121de3693a5e1e1aba7f84f6c` |
| [Room full 14968868751](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14968868751) | 111,748,381 | `509fbe1c62a4fd39b9c1cd8b544c753ebb5d3198730c04b17a04dcf829eff24b` |

Root verified the actual studio and room compact ZIP digests. Earlier app/library artifacts and failed evidence remain retained.

### Source-seven candidate: three source files reviewed, not executed

**Arrangement:** specialist 100 implemented and root independently reviewed `App/StudioView.swift` and the extension in `UITests/StudioSmokeTests.swift`. Arrangement uses **`.sheet(item: $arrangementContext)`**, removes the separate Bool/assignments, and preserves owner/scene/generation checks and nil cleanup. The risk is a **source-confirmed repeat of the Bool+optional deferred-content blank-sheet pattern**; no Arrangement failure was reproduced.

The existing **SettingsFeet3DFitAndSimulatorARManualFallback** method gains **20 lines**: Tools → Arrange setup → actual `setupXExact` enabled/hittable via the existing helper → keepAlways **Studio-arrangement-feet** screenshot → Cancel → same 3D selection. Root confirmed the actual menu and identifier composition. Specialist 90 audited all **18 App sheet declarations and related APIs**, finding no remaining duplicate deferred-content construction after the candidate. Room/AR/manual fallback unwrap context in the enclosing body and bind presenter identity; PhotoComparison always constructs a real destination, including an empty import UI for nil reference. This is source evidence only.

**Room status query:** specialist 90 diagnosed the actual source-six artifacts, and root independently viewed the PNG/trace and approved the actual `UITests/ManualRoomPlacementUITests.swift` diff. Only Resize's status query becomes **`app.otherElements["roomPlacementStatus"]`**, and its predicate becomes **`label CONTAINS` the same text**, with a brief evidence comment. The **15-second deadline**, first workflow, every dimension/status string, diagnostics and later signed-coordinate/save/relaunch checks remain unchanged. This is a **query correction candidate**, not proof of the delay cause or a runtime pass.

There is **no new test method, removed assertion, changed deadline or retry**. Candidate source seven is **unpublished**, with no SHA or runtime result claimed. Root will run required structural checks and publish **nine files**: these three source files, its separately maintained README and the five formal records. Normal new-source CI must verify Arrangement, room status and fresh library behavior. Exact source-six evidence does not certify the candidate; all protected gates and historical failures remain intact.

The lower sections are retained chronological snapshots. Pending results and earlier plans describe their stated observation times.

## Source-six unsigned builds and library cancellation — observation 21:44:42 UTC

At exact source **`22e51d7f85b709840128c11b0501be86a4c99c03`**, tree **`ba3c1a5cc68a3596d2050976419b26ef76ce7bac`**, native job **138789718752** has **successful unsigned Debug and Release build steps**. **native_build passes at this SHA. Native methods are still running**, so no completed method total or pass is claimed.

Library job **138789718986 completed/cancelled**. Root read its finalized **92,131-byte** log: the UI build began **21:34:44.829343Z** and was cancelled at **21:34:55.865328Z** with “The operation was canceled.” There is **no compiler output, no application assertion and zero UI tests executed**. The selected test run was skipped; result export failed and there is **no finalized xcresult**. The cancellation cause is **unknown**. Its artifact contains only toolchain information and a successful **5m28s simulator boot/preflight**, with **no native-ui-build log**.

| Actual source-six artifact | Bytes | SHA-256 |
|---|---:|---|
| [Debug app 14966252505](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14966252505) | 3,459,507 | `6b238b5a1ea6dc0b4197690182c152919015e4b9637f244d001928ce8af579dd` |
| [Release app 14966842650](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14966842650) | 3,987,658 | `5abcf076091d55bf26032d9bd8ee9d3965e4dd9c880a7a9b4cd4b7c87bd2700f` |
| [Cancelled library logs 14966023088](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826/artifacts/14966023088) | 9,525 | `968c5111b9c87a29fd38ec4f4f5084b097790b536f3d88d64940093b77a090ed` |

Studio **138789718925** and room **138789718719** are still building at **21:44:42 UTC**. Root may make **at most one bounded targeted library retry after the full workflow becomes terminal**; no retry request/execution is recorded here. The original cancellation must remain even if a later retry succeeds.

Current **core_tests, native_build and declared-fixture photometry pass**; native method results, current persistence smoke, complete regression and UI repairs remain pending. **M01 remains accepted at c74c3b7; M02 remains active with rendering/performance unresolved; M03–M07 pending; assignments remain 100.** A cancelled setup step with no app assertion is not evidence of a failed application scenario or a passed repair. Earlier snapshots remain below.

## Published source six — core and photometry gate receipt

Current published code is **`22e51d7f85b709840128c11b0501be86a4c99c03`**, tree **`ba3c1a5cc68a3596d2050976419b26ef76ce7bac`**, on `development/completion-final-20261124`. All source-six implementation changes received independent specialist-100/root approval before publication. The actual assignment count remains **100**.

[Run 45490703826](https://github.com/mirzotipi-wq/APP1/actions/runs/45490703826), **core job 138787937446**, completed success: **261 Debug tests (11.559 s), 261 Release tests (5.683 s), 28 Python tests**. Syntax, shard accounting, host kernel parity and precision checks passed. Root read the finalized **204,860-byte** exact-source log. **core_tests passes at this SHA.**

### Photometry: pass at the declared fixtures and domain

Specialist 100 reviewed the protected gate and source; root confirmed that the current log actually executed the evidence methods. **photometry passes at `22e51d7`** without changing its acceptance thresholds.

| Executed evidence | Cases / result |
|---|---|
| `SceneTests.testInverseSquare`; `SurfacePhotometryTests.testPointCosineAndInverseSquare` | Point inverse-square and cosine fixtures passed with tolerances stricter than the protected 1% point requirement. |
| `testRectangleMatchesAnalyticParallelFixtures` | Six cases; maximum fractional error **0.00023334691793906986**, equivalent to **0.0233347%**. Parallel assertions are stricter than 1%. |
| `testRectangleMatchesIndependentOffAxisNumericalReference` | Four cases against an **independent 160-subdivision Simpson reference**; maximum fractional error **0.00017649163172442342**, equivalent to **0.0176492%**. Assertions meet the protected 5% area requirement. |
| Two grazing methods | Eight cases with **0.2% assertions**. |
| Boundary, invalid-input, transition and scaling methods | Passed within the current executed suite. |

The declared model uses **SI meters/candela/lux** and an **ideal uniform one-sided Lambertian rectangle**. Point distance is **at least 0.05 m**; rectangular-source separation is **at least max(0.05 m, longest side / 4)**. These are **declared-fixture results**, not a global error bound or photographic, equipment, GPU or device calibration. **Study 8×8-versus-32×32 convergence is separate and is not the independent numerical reference.**

### Current Apple evidence and milestone scope

Native `138789718752`, studio `138789718925`, library `138789718986` and room `138789718719` have started. **No terminal build/native/UI result has been supplied.** The source-reviewed Intel SceneKit compatibility, Reference presentation and keyboard readiness repairs, current smoke and full regression remain pending actual execution.

**M01 remains complete on the exact `c74c3b7` core/build/Recipe/Corrupt proof retained below.** That acceptance does not transfer native or smoke success to `22e51d7`. **M02 remains active; photometry now passes and rendering/performance remain unresolved. M03–M07 remain pending.** All historical failures, including source-five UI **22/27**, the actual Intel crash, blank Reference modal, stale keyboard readiness and two AX Code=-56 errors, remain preserved. No device/calibrated/release approval follows. This checkpoint records evidence only and performs no test, CI query or commit.

## Source-five terminal UI: M01 complete at the exact accepted source

**M01 is complete at `c74c3b77b2cca811b7b747a2d2cf4a5f2e0e37ee` (tree `72fce94bd52240e4d47af2365b39041b4371e82e`); M02 is active and M03–M07 remain pending.** Root explicitly authorized this transition after specialist 100's independent assessment and the actual same-source **RecipeEditSaveAndReopen pass (65.729 s)** plus **CorruptProjectBlocksSavingAcrossRelaunch pass (20.527 s)**. Explicit library creation/rename/relaunch corroborates the direct first-save/edit/relaunch/corrupt-storage evidence. Existing **261 Debug / 261 Release / 28 Python, both unsigned builds and 84 native passes** complete the M01 gate set. All **100 assignments** and prior failed evidence remain recorded. This acceptance is source-specific, not release approval or acceptance of the current source-six working changes.

| Source-five UI shard | Completed | Passed | Failed | Aggregate | Suite finished UTC |
|---|---:|---:|---:|---:|---|
| Studio/export `138757582390` | 11 | 10 | 1 | 717.581 s | 21:03:31.410 |
| Library/reference `138757582423` | 11 | 7 | 4 | 736.002 s | 21:03:00.540 |
| Room/precision `138757582503` | 5 | 5 | 0 | 938.700 s | 21:10:13.405 |
| **Total** | **27** | **22** | **5** | — | No interrupted methods |

**Studio/export:** both Export methods passed (**75.853 s, 118.820 s**). Eight of nine Studio methods passed: Camera **65.423**, Corrupt **20.527**, Meter **65.959**, Optics **71.678**, Recipe **65.729**, Guide **62.868**, Sphere **26.193**, Mannequin **72.514 seconds**. Optics retained the original actual **0.6 m gesture / Undo / Redo / save / relaunch** acceptance. Settings passed **Meters → Feet and reopening**, then the app died immediately opening 3D; **Fit and AR were not reached**. Root extracted the actual IPS: **SIGFPE / EXC_ARITHMETIC**, `CoreRE TextureManager::init → engine → MeshResource.generateBox → StudioGeometryResources.init:164 → RealityStudioSurface.Coordinator.init`, on the **Intel Macmini6,2 simulator**. This is a real observed simulator crash; no physical-device outcome is inferred. Finalized studio results are present.

**Library/reference:** six of seven ProjectLibrary methods passed, including explicit creation/rename/relaunch and stale recovery. ArchivedDelete failed a stale keyboard-tutorial message-exists wait; actual later video shows the tutorial gone and keyboard ready. Both accessibility methods failed with **AX Code=-56**. GuidedRig failed during reveal on a **blank Reference sheet**, confirmed by actual PNG and empty-modal AX; BasicReference passed. These failures remain open despite successful direct M01 smoke.

**Room/precision:** all five passed — Manual **109.876 s**, Resize **369.963 s**, Camera **94.674 s**, Intensity **115.243 s**, Modifier **248.945 s**. The typed notes query correction is now native-verified, including signed coordinates, save and relaunch.

| Source-five UI artifact | Bytes | SHA-256 |
|---|---:|---|
| [Studio full 14965475368](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14965475368) | 125,763,975 | `e53799d6c86684f3cd0c1b8812a8756e7786f7f57c580805f2f47489ecd415b8` |
| [Studio compact 14963878402](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14963878402) | 2,918,074 | `166a5af9a0092c16dbc470428624e2ac449547c18b2eaca16523a1c9099c833d` |
| [Library full 14963783389](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14963783389) | 122,836,965 | `4d296b2ad0669b13fef4481eb4a45338c58b5b8570741d3fa6367c6fb52d3fb2` |
| [Library compact 14963703429](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14963703429) | 1,230,167 | `2129135eb6cc4801134881ba02abee7f20c65f004c747e057f001cd602b0710b` |
| [Room full 14965241557](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14965241557) | 7,092,115 | `fedc3aa6f58943c1840fe9713e1818ed23434e99d238d5e2450958e2936f4a60` |
| [Room compact 14965760647](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14965760647) | 1,749,995 | `b3b3a9dd7bd4f6294390d2055eebf3033953be91f1fc449a09a3c800d29c64ef` |

Root fetched the overall run API at **21:17:09 UTC**: head **c74c3b77b2cca811b7b747a2d2cf4a5f2e0e37ee**, status **completed**, conclusion **failure**, `updated_at` **2026-11-24T21:11:39Z**. The field is recorded as the API update timestamp. **Source-six working fixes are unverified:** specialist 90's functional SceneKit compatibility path for the Intel 3D crash, and specialist 100's item-driven Reference sheet plus hittable-key/inactive-Continue readiness. Root independently viewed the blank Reference PNG and keyboard frames at 48 s/55 s and approved the two specialist-100 fixes. The functional SceneKit path is under independent specialist-100/root source review. All need their own native/UI CI. Preserve the accepted source-five M01 evidence while keeping rendering, accessibility, full editing/persistence and regression failures or missing evidence explicit. No future SHA, repair pass, calibrated/device/performance result or owner release approval is supplied.

## Published source five — exact core/native receipt at 20:55:45 UTC

Published source is **`c74c3b77b2cca811b7b747a2d2cf4a5f2e0e37ee`**, tree **`72fce94bd52240e4d47af2365b39041b4371e82e`**, on `development/completion-final-20261124`. Actual distinct assignments remain **100**. The integration lead read the complete exact-source logs for [run 45481676220](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220).

**Core job 138756184590 succeeded:** **261 Debug tests (8.417 s)**, **261 Release tests (4.537 s)**, zero failures, and **28 Python tests (0.276 s)** on Swift 6.4.2 Linux. Syntax, host kernel parity and precision checks passed. These elapsed times describe this run, not device performance.

**Native job 138757582398 succeeded:** Debug `BUILD SUCCEEDED` at **20:38:24.695492 UTC**, Release at **20:41:19.948278 UTC**; **84/84 methods, zero failures**, **30.152 s test / 33.691 s overall**. Embedded `All tests` finished **20:51:58.757 UTC** and `TEST SUCCEEDED` appeared **20:54:05.508463 UTC**. The lead retrieved the complete **824,222-byte** log at **20:55:45 UTC**. **Current core_tests and native_build pass at this exact SHA.**

| Source-five artifact | Bytes | Supplied SHA-256 |
|---|---:|---|
| [Native compact 14964800247](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14964800247) | 332,360 | `2ab7d60070f929bb857b6127f38947a2e0128e53c340fe83a8318a901f1e9a46` |
| [Native full 14964536398](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14964536398) | 67,131,080 | `04793f5a8b9fc933f14457ce9e8b068944e98affdb8f585055e175453210d715` |
| [Debug app 14963090474](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14963090474) | 3,449,252 | Not supplied in this observation |
| [Release app 14964100309](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14964100309) | 3,996,810 | Not supplied in this observation |
| [Core log 14961689083](https://github.com/mirzotipi-wq/APP1/actions/runs/45481676220/artifacts/14961689083) | 61,525 | Not supplied in this observation |

All three **UI boot preflights and UI builds succeeded**. Studio `138757582390`, library `138757582423` and room `138757582503` are still running. **No UI method count or result is available in this receipt.** Infrastructure/build success does not establish interaction acceptance.

Specialist 100 independently assessed **RecipeEditSaveAndReopen** and **CorruptProjectBlocksSavingAcrossRelaunch** as the direct M01 first-save/edit/relaunch/corrupt-storage smoke pair; explicit library creation provides corroboration. Evaluate actual passing results at this source against the existing M01 contract. Genuinely unrelated M03/M07 failures remain separate failed gates; a failure contradicting M01 requirements remains relevant. **Persistence smoke is unverified, M01 remains active and M02–M07 remain pending.** No milestone transition, complete UI regression, physical-device, calibrated or release acceptance is claimed. Earlier failures below are retained.

## Terminal source-four UI receipt — completed 20:14:48 UTC

The run API reports [source-four workflow 45471239991](https://github.com/mirzotipi-wq/APP1/actions/runs/45471239991) completed **failure at 20:14:48 UTC**; the lead retrieved these terminal results around **20:21–20:24 UTC**. Parent `293686f94900b123aeded15b238f21157f73f30d`, its tree, branch and **100 assignments** are unchanged. The source-specific **261 Debug / 261 Release / 28 Python, both builds and 84 native passes** remain valid. Source five is unpublished and unverified.

**Studio/export job 138721052210:** the actual **505,988-byte** job log records **11 completed methods, 7 passes, 4 failures, 1190.143 s**, with suite finish **20:10:37.256 UTC**. The first Export method failed line 127's initial readiness wait at **19:53:31.729 UTC**, before tapping Export or generating a document. Launch began 19:50:47; automation setup occurred at t66.47 s, idle wait at t78.42, missing event-loop idle notification at t138.50, and the exportLightingPlan exists/enabled predicate at t140.71 before repeated lookups timed out. **No document-content defect is established**; the same workflow passed source three. Full-library backup passed in **291.575 s**. The studio suite completed **6 passes / 3 failures in 725.602 s**: Camera, Corrupt, Meter, Recipe, StudySphere and Mannequin passed; exact Width label, empty Meters value and `43.99999999999997` Guide height failed before later functional checks. There is **no 3D/AR acceptance**. Result-bundle finalization and artifact upload succeeded.

**Room job 138721052348:** **5 methods started, 4 completed, 3 passed, 1 failed and 1 was interrupted**. Initial Manual passed **168.203 s**; Resize failed **281.671 s** on the same 10-second expected-6 m notes query although captured AX held correct **6 m / 7 m / 3 / 2** values. Precision Camera passed **177.107 s**, Intensity **253.423 s**. Modifier still made active queries at **t302.51 s** when the 32-minute step expired at **20:11:13.633 UTC**. The step began **19:38:59.749**, boot finished **19:46:15.349**, xcodebuild was invoked **19:47:38.352**, and the first test began **19:51:42.135**: approximately **12m42s startup** consumed the test-step budget. No overall suite result was produced; room export reported missing result-bundle Info.plist and yielded no PNG.

| Actual source-four artifact | Bytes | SHA-256 |
|---|---:|---|
| [Studio full 14960681991](https://github.com/mirzotipi-wq/APP1/actions/runs/45471239991/artifacts/14960681991) | 143,497,773 | `2be8fcbe6f0735570a100de82145e1213058154b8f3bb97fbe00054c764e06c9` |
| [Studio compact 14960786780](https://github.com/mirzotipi-wq/APP1/actions/runs/45471239991/artifacts/14960786780) | 2,248,019 | `44668388b75e4a0e9a8d8e7b525e5a376ce03996c38f0f2d67a4c7572fa5394e` |
| [Room logs 14961645218](https://github.com/mirzotipi-wq/APP1/actions/runs/45471239991/artifacts/14961645218) | 29,838 | `b9d2f26b1a3757ecd6f4256eeb7a8846acc41f7b84cc546561a4066e0c3578e2` |

**Pending source five:** specialist 90 completed the notes query; the lead independently inspected actual AX hierarchy and production Text. `openNotes` targets `app.staticTexts["roomNotesText"]` and uses `label CONTAINS` the requested exact text, removing only a redundant exists lookup. The **same 10-second wait**, exact committed **6.00 m** and rejected **2.00 m**, later signed coordinates, diagnostics, share, Undo, save and relaunch remain. Settings/StudioSmoke corrections are reviewed. Specialist 100's separate **10-minute simulator boot preflight** is present and root-reviewed: it precedes build-for-testing, performs one fresh availability check and retains a boot log/artifact. Boot is removed from the **32/40-minute UI execution** step; the **25-minute build**, **85/93-minute total job** limits and native-unit job remain unchanged. Building between boot and execution also provides the normal build interval before test launch. There are no new cases, retry loops, selectors or relaxed assertions. **Root structural validation passed**: PyYAML parse; `bash -n` for every UI run script; preflight ordering, boot removal, unchanged budgets/native job; `git diff --check`; state and shard checks. **None is source-five native execution or acceptance.** Keep **M01 active, M02–M07 pending**, preserve the earlier rejected rerun, and verify the actual next source with its own CI.

## Later checkpoint — source four received at 20:09:47 UTC

Current parent is **`293686f94900b123aeded15b238f21157f73f30d`**, tree **`abc3f7002714e97e9f33a42cda12eeecf213a510`**, on **`development/completion-final-20261124`**. The assignment count remains **100**. The dated earlier source-three observations below are preserved.

- **Source four:** [run 45471239991](https://github.com/mirzotipi-wq/APP1/actions/runs/45471239991), core `138719440807`, passed **261 Debug, 261 Release and 28 Python**. Native `138721052072` completed success: both unsigned builds and **84 tests, zero failures**. Embedded tests finished **19:59:25.493 UTC**; `TEST SUCCEEDED` was **20:04:40.311826 UTC**; the lead retrieved the result **20:09:47 UTC**. Room `138721052348` and studio `138721052210` remain running.
- **Library setup:** job `138721052557` failed before any app tests: xcodebuild could not find destination device `12FC…`. [Log artifact 14959187269](https://github.com/mirzotipi-wq/APP1/actions/runs/45471239991/artifacts/14959187269) is **25,921 bytes**; compact artifact `14960225473` is an empty **146-byte** archive. One rerun request at **19:59 UTC** received **HTTP 403** because the workflow was still running. **No rerun started.** The new source-five full CI will make a fresh simulator attempt; do not repeat the superseded source.
- **Later source-three UI:** `394e28e` room finished **3/5**; all Precision passed, while both Manual methods failed on a screenshot request or notes AX deadline. The actual captured notes correctly committed **6 m**, which does not turn the failed method into a pass. Library finished **6/11** with two AX **`Code=-56`** timeouts and Archived initial Projects, stale Other and Reference choose-button readiness failures. All methods ended **19:38:09 UTC**; the 32-minute step killed finalization at **19:39 UTC**.
- **Source-three studio:** job `138700428187` completed **11 methods: 8 passed, 3 failed**. Failures were actual **Width in meters** versus expected **Width**, empty Picker value versus **Meters**, and Guide height **43.99999999999997** versus 44. None reached its later functional assertions. Both Export methods and Corrupt/Recipe/Camera/Meter/Sphere/Mannequin passed. Actual compact/full artifacts are `14958868844` / `14958639220`.
- **Source five pending:** specialists 96/100 completed review of two files: `StudioSettingsView` supplies explicit Meters/Feet accessibility value from normalized units; `StudioSmokeTests` uses the actual Width in meters label and only four coordinate ULPs of geometry allowance at the unchanged 44-point Guide target. Original 0.6 m, Undo/Redo/save/relaunch acceptance remains. These fixes have **no CI pass yet**; the next SHA is not invented. Current gates remain unverified and **M01 remains active**, with M02–M07 pending.

## Retained earlier checkpoint

**Active development; M01 remains active and M02–M07 remain pending.** This is a dated source and evidence checkpoint, not a release declaration. Protected milestone dependencies, acceptance thresholds and owner approvals are unchanged.

## Source and session identity

- Branch: `development/completion-20261124`.
- Session base: `d816a95714c3a8b5cb31c16f0be73e3c4c1982c2`.
- Recorded HEAD: `394e28e163be345b9db135d8a10a3a1dfafe6617`; tree: `842a26c25ed28d8a2a40fa3b3d81e97adcb438c4`.
- This session has **100 distinct specialist assignments**, including the records specialist and the final integration reviewer, as confirmed by the integration lead. Reusing an agent adds no assignments. The older repository checkpoint's 61 specialists belong to a separate session and are not added to this count.
- The prior `95e9c24` checkpoint, its counts, logs, failed evidence and handoff remain historical. No historical pass certifies the working changes after `394e28e`.

| Integrated commit | Implemented work |
|---|---|
| `57393463263635e3758c66e237b0e7f369863577` | Direct overhead-plan editing, subject controls and light management. |
| `10ba0ef9868a053142e31dda5b5bcad81dd6b769` | Native placement, photo comparison, measured-room exports and studio controls. |
| `394e28e163be345b9db135d8a10a3a1dfafe6617` | Editing transaction guards, geometry and export corrections, photo lifecycle handling, native workflow coverage and accurate implementation documentation. |

The implementation includes interactive RealityKit 3D; ARKit/RealityKit placement with a manual fallback; metric/imperial controls; modifier roll and scene arrangement; target-lux adjustment; bounded on-device reference proposals and explicit acceptance; session-only comparison photographs; persisted room measurements and PDF/text export; and StoreKit purchase/restore/entitlement code. These are implementation statements, not acceptance of physical tracking, calibration, inference quality or purchases. The StoreKit product identifier remains unconfigured and owner-approved feature gates are absent. See [README](../../README.md) for the current feature description.

## Exact-source CI observations

The integration lead supplied the observations below. This records packet independently read source/history and reconciled the ledgers; it did not rerun tests, poll CI, download additional artifacts or perform native/device validation.

| Source and workflow | Actual known results | Outstanding observation |
|---|---|---|
| `394e28e`, [run 45465026704](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704), [core job 138698953169](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138698953169) | **261/261 Debug, 261/261 Release and 28 Python passed.** | This pass belongs to the exact committed SHA and tree above. It does not establish a pass for later working source. |
| `394e28e`, [native job 138700428174](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428174) | Both unsigned Debug and Release builds succeeded. | Native tests were still running at **19:19 UTC**. **84 is the expected method inventory, not a passed or executed count.** No terminal native result is claimed. |
| `394e28e`, UI jobs [library 138700428157](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428157), [room 138700428256](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428256), [studio 138700428187](https://github.com/mirzotipi-wq/APP1/actions/runs/45465026704/job/138700428187) | At **19:16 UTC**, library/reference and room/precision were running; studio/export was queued. | No finalized current UI counts or full regression/persistence acceptance are available in this checkpoint. |
| `10ba0ef`, [run 45456830724](https://github.com/mirzotipi-wq/APP1/actions/runs/45456830724) | **257/257 Debug, 257/257 Release, 28 Python, both unsigned builds and 83/83 native methods passed.** Room UI completed **4/5**; library/reference completed **7/11**. | The five failed UI methods remain failed evidence at that source. No terminal studio or whole-workflow conclusion is inferred from these partial results. |

## Demonstrated failures and pending corrections

**Later native observation:** the finalized test log records **84 tests, zero failures**, with `All tests` passed at **19:22:31.329 UTC** and `TEST SUCCEEDED` at **19:24:15.669 UTC**. The measured-room PDF method passed (1.770 s); all four native PDF methods passed. Compact artifact **14956731360** contains the actual four measured-room exports. The artifact reviewer rendered and inspected all 32 pages at 95 dpi; no visible text clipping, row overlap, missing fixture labels or Letter footer collision was found. The lead separately inspected Letter/imperial page 5. These later observations supplement the earlier pending snapshot above; they do not certify physical devices or the working source after `394e28e`.

- **Room saved-state expectation:** the sole `10ba0ef` room failure expected the old saved state after changing room measurements. Room measurements now persist with the project. `394e28e` updates the scenario to require dirty state, Undo back to saved state without changing the saved modifier width, Redo, and a committed save. Actual native acceptance of the updated scenario is pending.
- **Library/reference:** four methods failed at `10ba0ef`. Two AX `Code=-56` timeouts remain unresolved. The project Keep flow was blocked by the iOS keyboard tutorial, demonstrated by the actual video. A stale “Other” button became disabled after broad UI scrolling moved Backlight to `-100 m`; the reviewed artifacts strongly support that explanation, but it is not a native event trace.
- **Working changes after `394e28e`:** queued NeutralCard cancellation, navigation from screen edges that preserves all acceptance assertions, and a test-only handler for the exact keyboard tutorial are being integrated/reviewed. Their source CI is pending. Do not invent the next commit SHA or reuse `394e28e` results as proof of these changes.

The current working-tree gates are therefore unverified. The ledger retains exact-SHA core/build passes separately and preserves historical failed evidence. Integration must obtain results for its own source, including original edit/Undo/Redo/save/relaunch expectations and actual reachable controls.

## Minimal added coverage

The `10ba0ef` → `394e28e` source diff adds **four portable test methods**, **one native PDF method covering four paper/unit combinations**, and **one simulator UI workflow**. Existing room and reference scenarios receive assertion updates; these are not extra test methods.

| Coverage | Scope and status |
|---|---|
| Four `DevelopmentGeometryTests` methods | Schema-five room/roll round trip and legacy schema four; quarter-turn AR geometry with authored heights and one-to-one distances; rolled downward-face transforms; floor/ceiling contact, crossing and unknown ceiling. Included in the exact-source 261-pass core totals. |
| `testMeasuredRoomPDFRetainsEveryRowInBothPaperSizesAndUnits` | One method, four combinations of paper and units; checks all room rows, pagination, modifier roll and extracted text. Passed within the 84 native methods at `394e28e`; genuine exports were subsequently rendered and visually reviewed. |
| `testSettingsFeet3DFitAndSimulatorARManualFallback` | One UI workflow covering unit preference, 3D fit and simulator fallback into manual measurements. Authored coverage only until its actual UI result is available. |
| Existing assertions | Room persistence/Undo/Redo/save and nested photo-comparison return preserve the original workflow checks. Native results pending. |

## Remaining gates and next packet

No configured commerce SKU, signed build, physical AR/Metal/performance evidence, calibrated rendering or held-out inference acceptance, customer validation, or owner release approval is supplied by this checkpoint. Older simulator Metal evidence remains historical and does not establish physical-device behavior. Feature presence and passing portable tests do not close those gates.

The cancellation, navigation and tutorial corrections have now received independent source review. The next integration also runs the three existing UI shards concurrently: the prior run left studio/export queued behind the other two. Selectors, assertions and per-step deadlines are unchanged.

Next: record the actual integrated source and tree; inspect finalized `394e28e` UI outcomes without rewriting the earlier observation; then verify the new source with its applicable core, unsigned build, native and UI checks. Preserve failures and original acceptance requirements. Update current counts and provenance only from actual results. M01 cannot close until all of its gates pass at an applicable source.


Source-six source review completed: specialist 90 implemented the Intel-simulator SceneKit compatibility path; specialist 100 and the integration lead independently approved renderer routing, existing camera/Fit behavior, current-scene selection mapping and cleanup. The selection recognizer waits only for camera pan/pinch/rotation and multi-tap gestures. The lead also reviewed the actual blank Reference screenshot and keyboard frames before approving the item-driven Reference sheet and keyboard-readiness correction. Native execution of these working changes remains pending.
