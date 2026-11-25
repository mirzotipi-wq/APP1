# Development completion checkpoint — 2026-11-24

## Current source ten and pending source eleven

Published/tested code **`fb643b156acae5831b60d1acaea26cc79adcfb47`**, tree **`978a36a789340bdb3947cd03f1ea7b4d3ee5404a`**, branch `development/completion-final-20261124`. [Run 45527563115](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115) has successful core/native, studio and room receipts. **All 16 methods with terminal UI receipts passed**; the library terminal result is still pending, with unknown case counts. Exactly **100 assignments** and **six net new test methods** remain recorded.

Source ten was published **2026-11-25 01:41:14 UTC** in seven files; the reviewed remote tree matched the staged index and root confirmed a clean synchronization. Its normal run was created **01:41:16Z**. Current observations do not establish a terminal whole-workflow result.

### Verified source-ten outcomes

| Job | Actual receipt |
|---|---|
| Core `138914574890` | **261 Debug (8.880 s), 261 Release (4.229 s), 28 Python (0.276 s)**; zero failures/skips. Completed **01:43:46Z**; finalized log **204,889 UTF-8 bytes**. State/shards/host parity/precision passed. |
| Native `138915571868` | **84/84**, zero failures/skips; **21.785 s tests / 23.011 s overall**. **810,356-byte** log retrieved **01:58:40Z**. |
| Studio `138915571838` | **11/11**, zero failures/skips; **769.571 s tests / 769.587 s overall**. Job completed **02:14:03Z**, API confirmed **02:17:36Z**. Log **519,194 UTF-8 bytes**; exact initial retrieval time was not separately captured. |
| Room `138915571876` | **5/5**, zero failures/skips; **842.208 s tests / 842.233 s overall**. Job completed **02:14:18Z**. Specialist 100 verified **471,451 characters** of raw log; no UTF-8 byte count is asserted. |
| Library `138915571926` | UI execution started **02:17:20Z**; in progress at **02:22:01.924Z**. Started/completed case counts and terminal outcome are **unknown**. |

Native All-tests finished **01:55:39.216Z**; `TEST SUCCEEDED` **01:56:46.7994850Z**. Debug/Release `BUILD SUCCEEDED` markers are **01:47:08.0554740Z / 01:49:11.8044330Z**. Earlier **01:47:09Z / 01:49:12Z** were API step-completion timestamps; uploads completed **01:47:11Z / 01:49:14Z**. MetalMatchesCPU passed **3.278 s**.

**Scoped photometry passes** from current complete core execution under unchanged declared fixtures and protected bounds: SI meters/candela/lux, ideal uniform one-sided Lambertian rectangle, point distance at least **0.05 m**, rectangle separation at least **max(0.05 m, longest side / 4)**. The analytic parallel and independent off-axis Simpson reference remain distinct from Study grid convergence. This is declared-fixture acceptance, not a global, photographic/equipment/GPU/device calibration claim.

### Studio and room execution

All studio/export methods passed: ExportPreview **108.091 s**, FullLibraryEditableCopy **126.996 s**, Camera **66.540 s**, Corrupt **19.501 s**, Meter **66.464 s**, Optics **72.602 s**, Recipe **57.368 s**, Settings/3D/Fit/AR/Arrangement **94.305 s**, Guide **68.453 s**, Sphere **24.315 s**, MannequinSwitch **64.934 s**. The two export methods total **235.088 s**, the nine studio methods **534.483 s**. UI ran **01:59:04–02:13:08Z**; trace collection and both evidence uploads succeeded.

The full original optics workflow passed with **initial 0.6 m** and real **normalized 0.5** gesture. The source-ten change adds **one new bounded 10-second synchronization wait**; all 112 original assertion lines and nine methods remain, plus one completion assertion, with original timeout values/workflow deadlines unchanged.

| Optics event | Actual UTC observation |
|---|---|
| Gesture | **02:07:12.259** |
| Native end | **02:07:14.418956**, committed **0.8 m**, tracking false |
| Completion predicate starts | **02:07:16.442**, after tracking ended |
| Undo / Redo | **02:07:24.121 / 02:07:27.756**, original/edited values restored |
| Save / Saved locally | **02:07:30.361 / 02:07:33.850** |
| Terminate / Relaunch | **02:07:34.354 / 02:07:35.505** |
| Relaunched native configuration | **02:07:40.976417**, PID 45485, emitterWidth **0.8** |
| Saved locally / final width read / pass | **02:07:43.886 / 02:07:55.592 / 02:07:56.340** |

Pre-Undo attachment **F59861BA-A882-4845-9D28-ECE90E4BDBD4.txt** records initial **0.6 m**, edited **0.8 m**, Undo enabled and Redo disabled. Trace collection and test both exited **0** over **01:59:05–02:13:09 UTC**; the only stderr was the nonfatal `getpwuid_r` uid 501 message. This verifies the source-ten synchronization correction. Source-seven/eight unchanged-width causes remain unproved.

All room methods passed: ManualRoom **71.713 s**, Resize/signed coordinates **329.209 s**, PrecisionCamera **107.973 s**, PrecisionIntensity **145.514 s**, PrecisionModifier **187.799 s**. The UI step succeeded over **01:57:55–02:13:12Z**; full/compact uploads succeeded.

### Current source-ten artifacts

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| [Core 14982822625](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14982822625) | 61,477 | `47a186c8e4d8c32822ef7816c417ec9d6ec78c3c194d6c4415bb089652054128` |
| [Debug app 14983282950](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14983282950) | 3,479,747 | `cf52953301ea2f2ef5641bb531f960e924cee54d9990ebce77444ec91505b34e` |
| [Release app 14983602637](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14983602637) | 3,981,150 | `c5e5604577fb673be9d9fdbe30df5bd61accad461b376e7e98bb91bcddaa8040` |
| [Native full 14983234842](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14983234842) | 69,683,148 | `5cd5d6bcb44218c59c70748ed3a5b08c847a7fcb5238afded0579895541de873` |
| [Native compact 14983234848](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14983234848) | 332,383 | `816bbd2ed37cbe206dbeb4615ef684d16a1bb51a43164936da766bcb746e0849` |
| [Studio full 14984143003](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14984143003) | 9,841,517 | `98aafaa2666853b6898c8afb51d3fae322d3ffdfa58193b3be903a1e103154fe` |
| [Studio compact 14984272715](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14984272715) | 3,500,417 | `759323ae316d19374073ba2e74f804047252449aca1248de611597784a74bb18` |
| [Room full 14984552901](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14984552901) | 6,227,899 | `80163d739b78676afabbc65c0a4d5f1a88dd1661fc5d5ae4096ede060ae6f901` |
| [Room compact 14984452921](https://github.com/mirzotipi-wq/APP1/actions/runs/45527563115/artifacts/14984452921) | 1,679,359 | `8c302dbf5a950e6e32af534e8b0cca706c8b8297c56e4bc511c059e4f799becc` |

Only the studio compact ZIP's actual bytes/hash were independently verified in memory by specialist 90. All other listed digests are **API metadata**; room API digests also match upload-log metadata, without downloaded-byte verification. No library artifact/result is claimed.

### Acceptance and source-eleven candidate

**M01 remains complete and is revalidated at fb643b1** by exact core/build and Recipe **57.368 s** / Corrupt **19.501 s**; native 84/84 and the full optics persistence workflow also pass. **M02 remains active with rendering/performance outstanding; M03–M07 pending.** One successful optics execution does not close the protected **ten repeatable core workflow runs** editing criterion. Full regression/accessibility/library acceptance remains unverified.

The source-eleven candidate changes **only `App/PhotoComparisonView.swift`**. Source-ten compilation reported the line-135 warning about reading main-actor `ComparisonPhotoSlot.image` inside a Sendable PhotosPicker label. The reviewed correction snapshots only Bool `isEmpty` on the inherited main actor before an explicit `return VStack`, preserving the literal label ternary and localization overload. No image is retained and lifecycle/state/bindings/identifiers remain unchanged. **No production failure was established.** Specialist 90 approved the source; root applied it at **02:10:34Z** and reports exact-patch/diff checks passed.

The app correction is **unpublished and unverified** and needs **normal full source-eleven CI**, including all **27 UI scenarios** anew. There are no new methods, skips, timeout or workflow changes. Root owns the app patch and README; this checkpoint updates six record files. No future SHA or pass is claimed.

Root and specialist 100 reviewed intentional supersession of unfinished source-ten library work after terminal studio/room proof. The **latest known library stage is running UI**, not merely building; actual case counts remain unknown. Root will take a fresh stage snapshot before publication, and specialist 100 will collect the final old-source log afterward. **No final cancellation, zero-execution count or library result is claimed now.** Older failure/cancellation receipts remain below.

## Retained source-nine terminal evidence

Published source **`38a3b52f23ba6777125f0503fcc2d3420fa037df`**, tree **`5f05a01ac8f3b16a8eaec8841f2b6f1df8a0e4ef`**, branch `development/completion-final-20261124`. [Run 45519751726](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726) is **completed/failure**, attempt **1**, updated **2026-11-25 01:25:26Z**; API retrieved **01:25:56Z**, final jobs confirmed **01:26:58Z**. Native **84/84** passed. All **27 UI methods completed: 24 passed, 3 failed, zero skips/interruption**. Exactly **100 assignments** remain recorded.

### Exact-source verification

| Job | Terminal receipt |
|---|---|
| Core `138888331558` | **261 Debug (10.323 s), 261 Release (6.170 s), 28 Python (0.387 s)**; zero failures/skips. **204,986-byte** log read **00:43:54 UTC**. Syntax/shard/host-kernel/precision passed. |
| Native `138889688697` | **84/84**, zero failures/skips; **33.154 s tests / 35.165 s overall**. **816,704-byte** log read **01:04:38 UTC**. |
| Studio `138889688745` | **10/11**, zero skips; **963.139 s tests / 963.169 s overall**. **502,153-byte** log read **01:14:24 UTC**. |
| Library `138889688958` | **9/11**, zero skips; **1137.965 s tests / 1138.000 s overall**. **451,679-byte** log read **01:24:45 UTC**. |
| Room `138889688766` | **5/5**, zero failures/skips; **909.794 s tests / 909.820 s overall**. **513,009-byte** log read **01:25:56 UTC**. |

**Scoped photometry passes:** maximum parallel fractional error **0.00023334691793906986 (0.0233347%)** and independent off-axis **0.00017649163172442342 (0.0176492%)** retain the declared SI/ideal uniform one-sided Lambertian fixture bounds. Point distance remains at least **0.05 m**; rectangle separation at least **max(0.05 m, longest side / 4)**. Four off-axis cases use the independent **160-subdivision Simpson** reference; the six parallel cases are analytic fixtures. Separate Study grid convergence **0.0032798081798638967** is not that reference. Protected thresholds remain unchanged; no global/calibrated/device claim.

Native All-tests finished **01:01:26.966Z**; `TEST SUCCEEDED` was **01:03:11.992401Z**. Actual `BUILD SUCCEEDED` markers are **00:48:03.694174Z** (Debug) and **00:51:07.384866Z** (Release); earlier **00:48:04Z / 00:51:08Z** were API step completions. Actual MetalMatchesCPU passed **5.032 s**. This current pass does not change the unexplained source-eight zero-execution failure.

### Actual UI outcomes

**Studio/export:** ExportPreview **70.278 s**, FullLibraryEditableCopy **148.378 s**, Camera **94.269 s**, Corrupt **27.397 s**, Meter **132.570 s**, Recipe **87.357 s**, Settings/3D/AR/Arrangement **145.861 s**, Guide **87.612 s**, Sphere **32.480 s** and Mannequin **46.997 s** passed. Optics failed **89.940 s** at **line 178**, comparing Redo **1.1500000000000001 m** with transient captured editedWidth **1.2000000000000002 m**. **First change and Undo passed; save/relaunch were not reached.** Embedded suite finish was **01:11:13.062Z**; `TEST FAILED` **01:12:39.012133Z**, exit **65** at **01:12:50.110001Z**.

**Library/reference:** all seven project-library methods passed: ArchivedDelete **265.841 s**, CreateDuplicateRenameSwitchAndRelaunch **174.466 s**, FullLibraryRecovery **74.290 s**, LargeValidLibrary **65.444 s**, StaleSavePreserve **88.403 s**, StaleSaveReload **44.867 s**, UnsavedSetup **51.163 s**. ReferenceGuidedRig **155.383 s** and ReferenceComparison **31.973 s** also passed. Only the exact-intensity **138.945 s** and initial-plan **47.188 s** audits failed, both **AX Code=-56** at `AccessibilityAuditUITests.swift:75`; no filter, skip or retry was applied. Suite finish **01:18:39.862Z**; `TEST FAILED` **01:20:17.952844Z**, exit **65** at **01:20:40.753015Z**.

The q/Q introduction branch was **actually exercised**: Continue tapped at **t110.49**, key-readiness predicate at **t114.57**, Key exists/hittable queries at **t119.29 / t119.45**, Type Keep at **t120.38**, exact Keep predicate at **t125.16**, followed by passing confirmation, deletion and relaunch. This verifies the branch at source nine; the source-eight delayed-name cause remains unknown.

**Room:** ManualRoom **73.050 s**, Resize/signed coordinates **242.147 s**, PrecisionCamera **79.866 s**, PrecisionIntensity **116.502 s**, PrecisionModifier **398.229 s** passed. Suite finish **01:20:49.751Z**; `TEST SUCCEEDED` **01:21:03.226782Z**.

### Trace diagnosis and its scope

Diagnostic collection succeeded with **exit 0**, preserving original test **exit 65**, over **00:54:24–01:12:51 UTC**. Trace/status/stderr sizes are **4,142 / 169 / 44 bytes**. The stderr `getpwuid_r did not find a match for uid 501` was nonfatal. Root and specialists 90/100 reviewed these events:

| Event | UTC / observed state |
|---|---|
| Begin | **01:04:04.041688**, model **0.6**, tracking true |
| Intermediate value | **01:04:04.748298**, model **1.85**, tracking true |
| Transient value | **01:04:05.171833 / 01:04:05.745068**, model **1.2**, tracking true |
| editedWidth query | Starts at test **t62.37**; log receipt **01:04:05.515740** |
| Final value | **01:04:07.140624**, model **1.15**, tracking true |
| End | **01:04:07.544814**, model **1.15**, tracking false |
| Ignored late value | **01:04:07.552781**, model remains **1.15**, tracking false |
| Undo existence query | Log receipt **01:04:07.684711** |

Before-Undo attachment **6240C8C2-58CF-4942-B324-48BD5725AE88.txt** corroborates stored Edited width **1.2**, live Slider **1.15** and Undo enabled. Undo correctly restores **0.6**; Redo correctly restores final **1.15**. This proves **premature expected-value capture in the source-nine test**, not a production history defect. It does **not** establish the cause of the earlier source-seven/eight first-change failures.

### Current artifacts

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| [Core 14979901542](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14979901542) | 61,700 | `534f226aba549d4c1d4d0fd6d9a15fc8f465c4612fbf04b9d6351bb15ac5cfe9` |
| [Debug app 14979658403](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14979658403) | 3,479,755 | `bae966619c09b7d27617e646d9a9709984bd66302139cb591bbca80ba083275b` |
| [Release app 14979664186](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14979664186) | 3,980,941 | `04675264489a76bc0d36fe3ed663008d8b7ae85d19e03fba7055c1ac40dabf91` |
| [Native full 14981261179](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14981261179) | 72,516,854 | `e1fbbf7a162eebba1d1681222c3384cbb13558b2b16398c060c6a770da2dc418` |
| [Native compact 14980363942](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14980363942) | 332,371 | `2aa683b3158c0c9afbed28e4d684538562614b2ec8f7cd10bf1e6bfc25311d27` |
| [Studio full 14980619102](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14980619102) | 132,621,632 | `bc6c4eb2a6bbd375a79275e9df5b9061d25c23d549a856490c4d244d97578944` |
| [Studio compact 14981143265](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14981143265) | 3,274,408 | `61471d1b34afde3d17c43428a56b03f234e57a1ec6c656af6fbc02ccb826dcb7` |
| [Library full 14981574140](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14981574140) | 129,161,796 | `fb98f48844b52c6f50c2ba474be5d781a86878034445032972a04280cf015099` |
| [Library compact 14982525386](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14982525386) | 1,588,341 | `15a6901f021909ee64205fc948d9bac3fa1a3f2fe521b5f2483fada8da08f944` |
| [Room full 14981254535](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14981254535) | 6,361,213 | `a03f190af2a4c9b130beb1c912530c6a5547811d03154c30cb59023bd50da427` |
| [Room compact 14981753851](https://github.com/mirzotipi-wq/APP1/actions/runs/45519751726/artifacts/14981753851) | 1,757,803 | `f7e859e1d7bfaa9693170ad9c84c2278516535947dcf50c2e2e01096110f9cc9` |

Only the source-nine studio compact bytes/digest were verified by root. All other listed digests, including native/library/room artifacts, are **API metadata**.

### Acceptance and applied source-ten candidate

**M01 remains complete and is revalidated at 38a3b52** by same-source core/build and **Recipe 87.357 s / Corrupt 27.397 s**; native 84/84, all project-library methods and room 5/5 also pass. **M02 remains active with rendering/performance outstanding; M03–M07 pending.** Full UI/regression still fails at **24/27**.

The source-ten candidate is **applied locally and independently reviewed, but unpublished**. It changes **only `UITests/StudioSmokeTests.swift`**, adding **one bounded 10-second synchronization wait**: require actual nonnil changed width, then Undo exists/enabled, then capture editedWidth. All **112 original XCTAssert lines** are retained, plus **one new completion assertion**; the same **nine StudioSmoke methods** remain. Original normalized 0.5 gesture, 0.6 m checks, Undo/Redo/save/relaunch, existing timeout values and workflow deadlines are unchanged. This explicitly adds one wait; there are **no app/workflow/helper changes, new methods, sleeps or retries**.

Specialist 90 supplied the patch; specialist 100 independently approved the exact block and full restored local diff. Root applied the approved patch and README and reports exact-replacement/source checks and diff check passed. Candidate native/UI validation awaits **normal CI after publication**; no future SHA or pass is claimed. The seven-file packet consists of the UI test, root's README and these five records. Source-nine is terminal, so no jobs will be canceled. No source-eight native retry was requested.

The executor was unavailable approximately **01:19–01:29 UTC**. Outage work was read-only remote preparation: **no local edits/checks or GitHub tree/commit/ref/PR**. Restoration retained the repo at 38a3b52 and all five pending records; work resumed locally. Root owns final preflight/publication. Historical source-eight and older receipts below remain preserved.

## Retained source-eight terminal evidence

Published source **`29c8efe87fafd03a9b9b544bcf783cfbef85bc37`**, tree **`a71bc83fc79fa5985f7cea8e8193a541be3170af`**, branch `development/completion-final-20261124`. [Run 45511267264](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264) is **completed/failure**, attempt **1**, `updated_at` **2026-11-25 00:18:23Z**. All **27 UI methods completed: 23 passed, 4 failed, zero skips**. Exactly **100 assignments** remain recorded.

Root published the ten-file source-eight packet at **2026-11-24 23:35:28 UTC**; its run was created **23:35:30 UTC**. Publication and method outcomes remain tied to this exact source.

### Terminal verification

| Job | Result and evidence |
|---|---|
| Core `138859268049` | **Pass:** 261 Debug (**8.006 s**), 261 Release (**4.639 s**), 28 Python (**0.285 s**), no failures/skips. **204,724-byte** log read Nov 24 **23:39:10 UTC**; syntax, shard, host-kernel and precision steps passed. |
| Native `138860475686` | Both unsigned builds **pass**; native job **failed before any test started**. Current native methods **unverified**. **758,778-byte** log read Nov 25 **00:05:49 UTC**. |
| Studio `138860475740` | **10/11 passed**, **866.110 s tests / 866.132 s overall**. **473,831-byte** log read Nov 25 **00:20:02 UTC**. |
| Room `138860475901` | **5/5 passed**, zero failures/skips, **559.997 s tests / 560.009 s overall**. **478,765-byte** log read Nov 25 **00:01:34 UTC**. |
| Library `138860475743` | **8/11 passed**, **1130.746 s tests / 1130.776 s overall**. **431,376-byte** log read Nov 25 **00:15:24 UTC**. |

**Scoped photometry passes at 29c8efe:** actual point/cosine, six analytic parallel rectangle cases and four independent off-axis cases executed. Maximum fractions remain **0.00023334691793906986 (0.0233347%)** and **0.00017649163172442342 (0.0176492%)**; the latter uses the independent **160-subdivision Simpson reference**. Separate Study grid convergence **0.0032798081798638967** is not that reference. Declared bounds remain SI meters/candela/lux, ideal uniform one-sided Lambertian rectangle, point distance at least **0.05 m**, and rectangle separation at least **max(0.05 m, longest side / 4)**. Protected thresholds are unchanged. This is a fixture result, not global, photographic/equipment/GPU/device calibration.

### Native attempt one: zero execution

Unsigned Debug `BUILD SUCCEEDED` was **Nov 24 23:43:13.285302Z**; Release **23:45:39.719250Z**. Boot finished **23:49:01.705858Z**, and xcodebuild invocation was logged **23:49:39.507147Z**. Both native and UI test targets compiled. The last actual `Resolve Package Graph` message is **23:52:26.202360Z**; **23:52:26.302602Z** is its following blank line. No later output preceded the **18-minute** timeout at **Nov 25 00:03:56.328588Z**. Specialist 100 independently confirmed zero test/suite markers and successful linking/final Touch. No compiler diagnostic or application assertion failure was observed; the silence has **no established cause**.

There were **zero native Test Case starts/passes**, no finalized xcresult and no compact artifact. Export failed because the finalized bundle was absent. **native_build stays pass; native methods stay unverified.** Historical f1769c9 **84/84** is preserved separately. No native retry was requested; planned source-nine CI supersedes the proposed unchanged-job retry.

### Actual UI outcomes

**Studio:** Exports **77.868 / 148.680 s**, Camera **77.799**, Corrupt **27.082**, Meter **89.532**, Recipe **81.256**, Settings/3D/Fit/AR/Arrangement **128.658**, Guide **97.827**, Sphere **31.571** and Mannequin **57.817 s** passed. Optics failed **48.021 s** at unchanged **line 162**: **0.6 m** remained after normalized **0.5** synthesis. **Undo/Redo/save/relaunch were not reached.** Sampled unobscured frames and synthesized event coordinates do not prove callback delivery or cause. Suite finished **Nov 25 00:16:00.991173Z**; `TEST FAILED` **00:17:18.112044Z**, exit **65** at **00:17:28.968563Z**.

Root viewed actual Arrangement image **76099C05-1253-4E8B-8473-08FADA8C7326.png**, **214,397 bytes**, capture epoch **1795565565.004**. Height is now single-line **4.92126 ft**; Horizontal/Depth read **0.00 ft**. Labels, readouts, rotation and mirror controls are readable; the prior long feet wrapping is absent. This supports the specific visible readout correction. Root also viewed 3D image **FB8F99CA-715A-4DF0-AEC6-9E6CE6648B11.png**, **402,814 bytes**: subject, three light markers, camera and floor are visible; Fit/Feet labels are readable. Low-contrast stands/camera and substantial empty scene space remain. Neither still image establishes physical rendering/calibration or performance.

**Room:** ManualRoom **50.899 s**, Resize/signed coordinates **229.503 s**, PrecisionCamera **64.997 s**, PrecisionIntensity **80.336 s**, PrecisionModifier **134.262 s** all passed. Selected tests finished **Nov 24 23:59:34.414151Z**; `TEST EXECUTE SUCCEEDED` **23:59:36.966632Z**.

**Library/reference:** CreateDuplicateRename **197.257 s**, FullRecovery **129.775 s**, Large **103.803 s**, StalePreserve **116.980 s**, StaleReload **51.886 s**, Unsaved **80.721 s**, ReferenceGuided **152.342 s** and ReferenceComparison **42.079 s** passed. Exact-intensity **95.790 s** and initial-plan **43.764 s** accessibility audits failed with **AX Code=-56**. ArchivedDelete failed **116.348 s** at **line 146**, the exact entered-name expectation. The intro helper found no intro, so the new **q/Q branch was not exercised**; original deletion/relaunch were not reached. Specialist 100 mapped frames **84/88 s** to **t84.025/t88.025** within the exact-name expectation, not the earlier initial wait: both show empty Name, disabled Save and AutoFill. Frame **100 s** also shows empty Name; final frame **115 s** shows Keep. Cause is unproved, including any purely stale AX-cache attribution. Suite finished **Nov 25 00:11:12.424420Z**; `TEST FAILED` **00:13:07.587815Z**, exit **65** at **00:13:21.764579Z**.

### Source-eight artifacts

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| [Core 14976385500](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14976385500) | 61,483 | `1c9f175c77716cb64a0e4bc0a83dff25db72c46d6e8dddcb4ed6bfdcd5aaab81` |
| [Debug app 14976985367](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14976985367) | 3,472,262 | `1cce124a320cc67862dfdebbc6d9f660952fed7d1b6567844ad475ad98c70804` |
| [Release app 14976267181](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14976267181) | 3,980,875 | `75e266d0fa5568b15d5907cd359a6113a2bef8a8e580422aa9442d5dffed8cc0` |
| [Native build/log 14977705622](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14977705622) | 60,953 | `917f498cd11b8a485dafef2bd598b73f8167e5072a5a7fe5a676e07f3c1d4384` |
| [Studio full 14977722969](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14977722969) | 120,945,710 | `85e5cb918c854d03bb63fea2fb5172672ab33ef1b5f260966a10f1b455738547` |
| [Studio compact 14977793053](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14977793053) | 3,194,557 | `2c4ba947b5be9139a4dc38c22610397d6efe726495b96b08df50d37994abdbed` |
| [Room full 14976024998](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14976024998) | 6,334,267 | `267e64430298672f430a7ea510401c28475df5f07a09f8dee1208f3667d248f1` |
| [Room compact 14977481562](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14977481562) | 1,788,817 | `e01709bb80f8e0f794c3caea85384d684439b223c0d2bfe8832c54ffb0e4a9ce` |
| [Library full 14978670567](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14978670567) | 136,388,057 | `a32b74dc308da2e4c074d29198048896fb279b155836bdaf3885614db700eca5` |
| [Library compact 14978855264](https://github.com/mirzotipi-wq/APP1/actions/runs/45511267264/artifacts/14978855264) | 1,587,457 | `c435e4f06397091f22d3b987a94a9049a03ae8324a2bbaec06e109cbe9f0e830` |

Studio and library compact ZIP bytes/digests were verified by root. All other listed source-eight sizes/digests remain **API metadata**. Debug/Release artifacts were created Nov 24 **23:43:17Z / 23:45:43Z**.

### Acceptance and pending source nine

**M01 remains complete and is revalidated at 29c8efe** by actual current **Recipe 81.256 s + Corrupt 27.082 s**, exact core/build proof and corroborating explicit creation/room passes. This does not promote the native methods or four failed UI scenarios. Initial c74 acceptance and 22e/f176 revalidations remain preserved. **M02 remains active with rendering/performance outstanding; M03–M07 pending.** No calibrated/device/performance or release acceptance follows from the specific Arrangement image.

Two consecutive optics failures prompted **one minimal diagnostic change**, now **implemented and frozen, independently approved by specialist 100 and reviewed by root**, in exactly `App/StudioSlider.swift` and `.github/workflows/ios-prototype.yml`. DEBUG-only `OSLog Logger.notice` emits public controlled trace, one configured message per slider, retaining the original `-ui-testing`/environment gates and **64-event cap**. Studio-only UTC start and EXIT-trap end preserve the original test pipeline status. A separate always-run collection step has a **two-minute diagnostic-only budget**, observable status/stderr and continue-on-error; full/compact artifacts include `trace*`. **Gesture, binding, history, assertions, selectors and deadlines are unchanged; core/native workflow jobs are unchanged.**

Specialist 90 parsed the full YAML, ran `bash -n` on both changed blocks and confirmed the non-DEBUG source projection is identical. Root diff/state/shard checks passed. Source nine remains **unpublished, with no SHA or native/log-capture result**. The eight-file publication will include the two source/workflow files, these five records and root's README. Normal new-source CI supersedes the proposed source-eight native retry; **none was requested**. Earlier results below remain chronological snapshots.

### Verified source-seven baseline

Verified source-seven baseline is **`f1769c9566e9f8ccb4381a213a1cfac40a6ddf48`**, tree **`c20a50931de173d69c40dcbf9958b39b65fbc850`**, on `development/completion-final-20261124`. Root published the reviewed nine-file packet at **22:34:05 UTC** after required structural checks; the local tree synchronized clean at **22:34:36 UTC**. [Run 45502136448](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448), created **22:34:07 UTC**, is **completed/failure**, attempt **1**, `updated_at` **23:20:09Z**, API confirmed before root's **23:25:49 UTC** clock check; precise retrieval time was not recorded. Exactly **100 assignments** remain recorded. No source-six or source-seven retry was requested.

### Verified source-seven jobs

| Job | Final result |
|---|---|
| Core `138827877095` | **Success:** 261 Debug (**8.439 s**), 261 Release (**4.432 s**), 28 Python (**0.271 s**); no skips. Finalized **204,638-byte** log read **22:38:03 UTC**. |
| Native `138829327680` | **Success:** both unsigned builds and **84/84 methods**, zero failures/skips; **23.356 s test / 24.064 s overall**. **812,051-byte** log read **22:54:33 UTC**. |
| Studio `138829327675` | **Failure: 10/11 passed**, **824.372 s test / 824.389 s overall**. **512,570-byte** log read **23:09:26 UTC**. |
| Room `138829327696` | **Success: 5/5 passed**, zero failures/skips, **1177.211 s test / 1177.243 s overall**. **506,019-byte** log read approximately **23:24 UTC**. |
| Library `138829327751` | **Failure: 8/11 passed**, **998.401 s test / 998.438 s overall**. **625,577-byte** log read approximately **23:24 UTC**. |

All **27 UI methods completed: 23 passed and 4 failed**, with no interruption or cancellation. This is not a complete regression pass.

Native Debug `BUILD SUCCEEDED` occurred **22:41:34.712037Z**, Release **22:44:01.681094Z**; All tests finished **22:52:07.078**, `TEST SUCCEEDED` **22:53:13.168469Z**. Exactly 84 passed-method lines and zero test-skip lines were counted. All three SpatialPreview methods and actual Metal/CPU match (**3.820 s**) passed. **core_tests and native_build pass at this exact source.**

**Scoped photometry passes:** actual point/cosine and rectangle reference cases executed again. Six parallel cases retain maximum fractional error **0.00023334691793906986 (0.0233347%)**; four off-axis cases retain **0.00017649163172442342 (0.0176492%)** against the independent **160-subdivision Simpson reference**. Separate Study grid convergence **0.0032798081798638967** is not that reference. Declared limits remain SI meters/candela/lux, ideal uniform one-sided Lambertian rectangle, point distance at least **0.05 m**, rectangle separation at least **max(0.05 m, longest side / 4)**, and unchanged protected tolerances. This is a fixture result, not a global bound or photographic/equipment/GPU/device calibration.

### Actual UI outcomes and remaining failures

**Studio/export:** both Export methods passed (**65.873 / 117.457 s**). Recipe **77.016**, Corrupt **22.426**, SettingsFeet3DFitAndSimulatorARManualFallback **123.220**, Camera **63.952**, Meter **104.080**, Guide **86.542**, Sphere **40.368** and Mannequin **74.783 seconds** passed. The Settings method includes the new actual Arrangement editor reachability checks. The original optics assertion at **line 162 failed with unchanged 0.6 m after synthesized normalized 0.5**. **Undo/Redo/save/relaunch were not reached**; they are neither passing nor failing current observations. Selected tests finished **23:05:39.625**; `TEST FAILED` was **23:07:11.475782**, with exit **65** at **23:07:25.351563**. Sampled recording frames show an unobscured slider. The synthesized event specifies a thumb-to-midpoint path from x **82.8513 to 201**, y **651.6667**; the sampled frames do not establish every intermediate movement or callback delivery. No root cause is established; source eight leaves the original slider and its test unchanged.

**Room:** Manual **85.934**, Resize **444.826**, Camera **154.824**, Intensity **182.598** and Modifier **309.030 seconds** all passed. The typed-Other/label correction and preserved later checks now have actual source-seven execution evidence. Tests finished **23:17:11.905105**; `TEST SUCCEEDED` was **23:17:17.831610**.

**Library/reference:** CreateDuplicateRename **187.580**, FullRecovery **98.109**, Large **90.256**, StalePreserve **96.217**, StaleReload **53.274** and Unsaved **61.198 seconds** passed. Both Reference methods passed: Guided **170.723 s**, Comparison **48.702 s**. Two accessibility audits failed with **AX Code=-56** in **90.420 / 39.231 s**. ArchivedDelete failed **62.691 s** at **line 127**, on the keyboard-intro-closed plus typing-keys expectation; actual AX selected **Padding-Left (0 × 0)** as the first key while **q measured 39.3 × 54**. Root viewed the 60-second recording with the intro closed and normal keyboard/q visible. The reviewed q/Q helper correction awaits source-eight execution. `TEST FAILED` was **23:18:39.768646**, exit **65** at **23:18:58.590838**. These failures remain despite successful room, Reference and Arrangement flows.

### Source-seven artifacts

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| [Native full 14972206984](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14972206984) | 65,621,280 | `6731063919ae183bfa57050f65d62c62d0d3acb93e39f2f9d48a1d6dc4a9f3d5` |
| [Native compact 14972446920](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14972446920) | 332,367 | `fa44a61c01910d52338e965e47a46aa89b17e513a7cc4dbf75312494f1ba9459` |
| [Debug app 14971966548](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14971966548) | 3,457,894 | `db2f688ed2a6eeccf71315e61703a76af4cf11635617484b2209a7b1f4a01796` |
| [Release app 14971797175](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14971797175) | 3,986,588 | `d5734b41b66215c17f787ae1de8af8dad1aaecdbb40e3f9fb41c6153590bc6ab` |
| [Core log artifact 14971164083](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14971164083) | 61,443 | `f614252e8ad8207396c1848e05377f8739ac83c73dd6c4d67e470d9fc93a6cd6` |
| [Studio full 14973654136](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14973654136) | 125,811,204 | `6943c35c3ba96535b044adcc8c4dbd00e61a7f97b535be9f61841f81bc1cae41` |
| [Studio compact 14973594667](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14973594667) | 3,165,122 | `4256768580783916970ffe3e030b08cc72dc8fe75ad38b87ac7eb6022d2d25d0` |
| [Room full 14975041821](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14975041821) | 6,047,890 | `79703bf6fd4ebbbe46f0258df23b110632d5aec2464523a2c40f72415a0d953d` |
| [Room compact 14972869387](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14972869387) | 1,568,107 | `5ebf484344a6f5aee6e156d3c5d46871a65cd0c0ee30258bb96ab3268c7088a7` |
| [Library full 14974307789](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14974307789) | 127,844,066 | `fb99e646821b3a2745f2d664abc830139369564c60fa32829250e0085f5786d1` |
| [Library compact 14973783846](https://github.com/mirzotipi-wq/APP1/actions/runs/45502136448/artifacts/14973783846) | 1,490,535 | `8289bf27f53feb2f9b160fb6e071e668a6be79a3729fd1d8f404cdd8d8e46365` |

The studio and library compact ZIP sizes/digests were verified against actual bytes. Room full/compact and library full sizes/hashes remain **API metadata only; their bytes have not yet been independently verified**. No new source-seven screenshot-quality review is inferred from the method passes.

### Acceptance scope

**M01 remains complete and is revalidated at f1769c9** by exact current core/build/native evidence and **Recipe 77.016 s + Corrupt 22.426 s**, corroborated by explicit creation/rename/relaunch and all five room passes. Initial c74c3b7 acceptance and 22e51d7 revalidation remain preserved. Arrangement, the room query correction and both Reference methods now have direct execution evidence; the four failures remain separate failed gates.

**M02 is active with scoped photometry pass and rendering/performance outstanding; M03–M07 remain pending.** Full editing, accessibility and regression acceptance remains failed or incomplete. At this earlier snapshot, source eight was awaiting its own runtime receipts; no source-six or source-seven retry was requested. Earlier source-six cancellation, its failed Resize assertion and unexecuted library cases, and every older failure remain below as historical snapshots. No physical-device/calibrated/performance or owner release approval follows.

### Retained source-eight publication review

The published packet changes **four source files**: three app files for an Arrangement-only compact visible distance readout, plus `UITests/StudioContentReachability.swift` for q/Q keyboard readiness. The actual Arrangement image showed **4.921259842519685 ft** wrapping. `visualReadout` defaults to `nil` and `compactReadout` to `false`; only Arrangement opts into the existing localized compact formatter for visible Text. Exact Double binding, range, editor, accessibility value/identifier, SI data and the **44-point** target remain unchanged. The q/Q helper preserves the **10-second** deadline and intro-closed/key-exists/hittable assertions.

Specialist 90 completed the app changes; specialist 100 independently reviewed them and root approved them. Specialist 100 completed the keyboard correction, also reviewed by root. Root reports the state check, M02 next-gate selection, **7 classes / 3 shards** accounting and diff check passed. These were source/structural receipts at publication; source-eight terminal outcomes are recorded in the current section above. Original optics code/test and AX audits remain unchanged, and all four source-seven failures remain recorded. The published ten-file packet includes these four source files, the five formal records and root's README (675,070 characters).

## Retained source-six terminal evidence and prepublication review

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
