# Precision fixture reproducibility

> **Final evidence:** unchanged source `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014` passed native retry2/job140103955982: **178 unique method passes, all 29 cache methods, actual simulator Metal 6/8 and 19 CPU payload observations**. The native command, inline Metal guard, required accounting and finalized XCTest export all passed. The failed first attempt remains retained. The whole workflow still reports failure because of retained UI outcomes. Owner03's corrected observer compiled; its job reports failure with unavailable terminal logs, so its actual method/runtime result remains unknown. Combined owner integration remains open. Earlier queue and compile-pending statements below are historical snapshots, superseded by this final record. [Native retry receipt](evidence/ci/wave07-native-140103955982.json), [owner03 terminal observation](evidence/owners/03-corrected-terminal-observation.json), [HANDOFF](HANDOFF.md).

This catalog freezes constructors and evidence at input `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`. It adds no tests, harness, tolerances or runtime result. [precision-fixtures.json](precision-fixtures.json) contains exact expressions, Git blob identities, selected source blocks, recorded commands and evidence IDs. [PARITY_TABLES.md](PARITY_TABLES.md) owns the detailed per-case numerical tables.

## Evidence and execution boundary

| Evidence | Revision and receipt | What it establishes |
|---|---|---|
| Source 6 core | `240000fd3f8cb75273eb279be9dcc7f204a5b29f`; run 45848953002, job 140009926092; raw blob `b99b8d092e34a136b6e00e14e4b8e83b1ecd98e8` | 379 Debug and 379 Release passed; shipped Swift CPU fixtures compared with host C++ shared Float32 for canonical6 and selected strict8. |
| Source 6 native | Same revision/run, job 140012314020; raw blob `48500c2b0d1ef8ed6ac2bae8e0a12e4f7e07614d`; metadata `006f0a8f6546adb58e09b9a3942f3d624a842ac3` | Terminal success supplied by root before freeze: 174 unique native methods, 0 failures/skips; both builds, accounting and finalized export succeeded. Actual simulator Metal6/8 passed. All 25 source 6 cache methods passed in their separate evidence classes. |
| Historical native | `88279ba0ee0262ea6c880580c8a85b56342abbff`; run 45837392344, job 139973865345; raw blob `a87b4e2c42f5bd753c8312c95f22b6bd302bb78c` | 160 native methods passed without skips, including actual simulator Metal6/8 and specific engine routing tests. Retained history, not substituted for source 6. |
| Input/source 7 cache additions | `NativeTests/StudyRenderCacheTests.swift`, blob `dd068965cf56312ea0feb90578ca9461ba6b1054` | Four appended methods increase 25 to 29; source 7 execution is pending with no compile/runtime result for these additions supplied at freeze. This file is separate from the renderer and strict precision tests. |
| Physical device | No receipt | Unperformed; no device performance, calibration, RSS or driver-memory claim. |

Source 6 core artifact `core-test-log` has actual ID 15132856675, read from its retained upload log. Source 6 native full/compact IDs are15135391983/15136500149. Historical native full/compact IDs are15130376495/15130446442. Digests where supplied are preserved in the JSON. These are existing evidence references, not newly generated artifacts.

The strict and canonical native test files at the historical revision are byte-identical to their input counterparts. The source 6 routing tests and host preparer/comparator also match input. Worker073's source comparison and the root's 13-source manifest extend that provenance. Unchanged source permits explicit carry-forward; it does not create execution of source 7 additions. Mocked lifecycle images, C++ Double transcription, actual simulator Metal, shipped Swift CPU and source-level calculations remain separate evidence classes.

The initial checkpoint recorded source 6 native as pending. Root then supplied terminal receipts; this freeze incorporates them without erasing that earlier observation. Source 6 native canonical results have largest channel error1 and zero outlier fractions; strict8 has zero mean, maximum and outlier errors. Exact masks are established by their assertions. The full numerical table remains in PARITY_TABLES.md.

## Canonical six and strict eight

Canonical order is **hard, soft, warm-rotated, dark, near-field, translated**. All derive from `LightingScene.portrait()` through the exact expressions in `StudyValidationFixtures.all()`. The catalog preserves portrait defaults and every mutation. Host and native parity use 96×64; startup validation uses 48×32. The default-width eligibility regression asserts 192×128. Do not generalize that assertion to every pixel grid.

The native canonical test calls `renderValidationFixture`, including the deliberate near-field unsupported-pixel case. Production engine routing for near-field is separately asserted as CPU at width48, with later ordinary Metal still available. A canonical parity pass at width96 is not a claim of normal Metal routing. Canonical native output prints count equality; `metrics.passes` also asserts exact mask equality. It does not print numeric unsupported or mask-mismatch counts.

Strict8 consists of six area-camera combinations: distances **19.0,19.999999,20.0 m** crossed with focal lengths **85.0,200.0 mm**, at 192×128. Both world translations start from `fixtures[5].1` (20.0 m,200.0 mm). Their offsets are `(77,70,75)` and `(-77,-70,-75)`, moving subject, camera, every light position and each present aim target. Their names are `world-translation-77` and `world-translation--77`.

The selected script/native constructor blocks, UUID normalization and guards match exactly. Each input is validated, then lights receive `UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", index + 1))!`. The guard checks camera and **all** light distances from the subject at <=20 m. The packer subtracts the subject in Double before Float conversion; absolute world coordinates are not the limit.

The generator emits **33** fixture files. The CI comparator selects only the six `area-camera-*.bin` and two `world-translation-*.bin` files. Generation supplies no pass for the 25 unselected tangent, near-mask or light-distance probes.

Strict native dispatch uses `renderValidationFixture`. It bypasses production eligibility, retains relative-distance and packed-input validation, and submits actual Metal compute. It cannot satisfy the test by returning a CPU fallback image. **Production routing is not asserted by the strict matrix.** Both suites require mean RGB-channel error<=1, fraction of RGB channels with error>4<=0.005 and exact unsupported-mask equality; strict8 additionally requires maximum channel error<=1. Neither suite requires zero unsupported pixels. A skipped no-device method is unverified.

## Boundary fixtures and routing

| Fixture | Exact construction and grid | Established outcome |
|---|---|---|
| Silhouette | Subject `(0,1.5,0)`, camera `(0,1.5,3)`, no lights, focal `161.27198111190464`;24×16 | Ineligible at 24; engine CPU image equals Swift reference in historical and source 6 native tests. Widths27,48,96,192 are separate eligible controls. Later portrait/width48 validates Metal on the same engine. |
| Sphere/depth equality | Camera `Position(x:0,y:subject.y,z:geometry.radius + CameraFraming.minimumDepthMeters)`;24×16 | Ineligible; both `StudyComputeInput` and Swift CPU throw `invalidCamera`. No successful fallback frame. |
| Panel clearance equality | Camera `Position(x:0,y:geometry.panelY + 0.01,z:3)`;24×16 | Same invalid-input outcome. Keep the exact expression, rather than replacing it with a rounded decimal. |
| Nonaxial vertical | Subject `(0,0,0)`, camera `(2.5133431923616664e-13,0.27926035470685184,0)`, no lights,14 mm | Ineligible at 192; compute input192 remains valid. Swift CPU at 24 has 0 unsupported pixels. Setting camera.x=0 is an eligible192 control. This test measures no Float32 error. |
| Disabled far light | Portrait scene, one point source at `(21,1.5,0)`, candela 0,5600 K | Eligible at 24,27,192; packed samples/areas empty; CPU24 image equals no-light control. Setting candela 100 rejects eligibility at those widths. No actual Metal frame for this exact fixture is asserted. |

The disabled-light case exposes a difference between APIs. Production eligibility exempts a zero-candela light from the distance check; the validation-only API checks every light. Its 21 m distance would therefore throw `precisionDomain` in the validation path. This last statement is a documented guard calculation, not a measured dispatch.

Normal Metal rendering constructs/validates input before reporting an optional precision-domain fallback. Exact camera-clearance failures stay invalid-camera errors. The native error-ordering test uses different invalid poses `(0,1.2,3)` and `(0,1.5,0.25)`; it is not execution of the exact equality fixtures.

## Retained silhouette failure

Baseline `f150f98e35dd735927075aac4d2f8b02295c6a67` retained a 24×16 no-light host probe. It compares the shared C++ Float32 kernel with an **independent C++ Double geometry transcription**. The shipped Swift renderer was not run by that receipt, and no Metal dispatch is claimed.

The probe recorded two differing pixels, mean 0.1076388888888889, maximum 24 and fraction>4 of0.005208333333333333, exceeding0.005. The process exits 0 when it successfully reproduces that failure. Its `invalid=0` increments only for `candidate.w ==0`; the receipt does not report a comparison of two masks. The retained command uses **-O2**. No separate O0 execution is established.

Later shipped Swift assertions establish black, valid pixels at `(9,0)` and `(14,0)` and 0 unsupported pixels for the CPU image. They do not establish whole-frame Swift-versus-Float or Swift-versus-Metal error metrics. The original source/raw/metadata and corrective receipt hashes remain in the catalog.

## Recorded reproduction commands

These are commands preserved in source 6 Linux/native logs; worker079 did not run them. Reproduce with the named source revision and a suitable toolchain, and retain original outputs. Ephemeral runner and simulator paths below describe that execution, not a reusable local environment.

### Source 6 core and host comparison

~~~sh
set -euo pipefail
swift test --jobs 2 2>&1 | tee core-tests.log
swift test --configuration release --jobs 2 2>&1 | tee core-release-tests.log
swiftc -O Sources/LightingCore/*.swift scripts/prepare-kernel-fixtures.swift -o "$RUNNER_TEMP/prepare-kernel-fixtures"
"$RUNNER_TEMP/prepare-kernel-fixtures" "$RUNNER_TEMP/kernel-fixtures"
clang++ -std=c++17 -O2 -Wall -Wextra -Werror scripts/verify-kernel-host.cpp -o "$RUNNER_TEMP/verify-kernel-host"
"$RUNNER_TEMP/verify-kernel-host" "$RUNNER_TEMP"/kernel-fixtures/*.bin | tee study-kernel.log
swiftc -O Sources/LightingCore/*.swift scripts/precision-boundary.swift -o "$RUNNER_TEMP/prepare-precision-boundary"
"$RUNNER_TEMP/prepare-precision-boundary" "$RUNNER_TEMP/precision-boundary"
"$RUNNER_TEMP/verify-kernel-host" --maximum-channel-error 1 \
  "$RUNNER_TEMP"/precision-boundary/area-camera-*.bin \
  "$RUNNER_TEMP"/precision-boundary/world-translation-*.bin | tee study-precision.log
~~~

Linux reported Swift 6.4.3. The shared-kernel command is clang++ with -O2; no compiler version is inferred from the separate baseline g++ probe.

### Source 6 actual simulator Metal

~~~sh
/Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug -destination id=12FCFD0F-7FCF-463F-A605-132A7E18B5D5 -derivedDataPath /Users/runner/work/_temp/keyfill-build CODE_SIGNING_ALLOWED=NO "-only-testing:KeyAndFillTests" build-for-testing
/Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug -destination id=12FCFD0F-7FCF-463F-A605-132A7E18B5D5 -derivedDataPath /Users/runner/work/_temp/keyfill-build -parallel-testing-enabled NO -resultBundlePath NativeTests.xcresult CODE_SIGNING_ALLOWED=NO "-only-testing:KeyAndFillTests" test-without-building
~~~

The retained environment reports Xcode 26.6 and Apple Swift 6.3.3. Source preparation used XcodeGen. Both native fixture methods throw `XCTSkip` when no Metal device is available. Preserve failure, skip, unrun and successful terminal accounting separately. The catalog also preserves historical native commands at their own revision.

### Historical silhouette reproduction

~~~sh
g++ -std=c++17 -O2 -ffp-contract=off -Wall -Wextra -Werror docs/parallel/04/evidence/silhouette-probe.cpp -o /workspace/scratch/2987b1ee980d/build04/silhouette-probe && /workspace/scratch/2987b1ee980d/build04/silhouette-probe
~~~

This command is preserved with its baseline Linux/compiler receipt; rerunning it on a different revision would be a new experiment.

## Freeze and remaining dependency

Root reports that the exact input is published as the branch head without source changes after the snapshot. Only root monitors source 7 CI.

Worker079 used only pinned GitHub reads, in-memory source inspection and UTF-8 candidate blob creation. No local command, build, SDK probe, CI poll, rerun, test/harness change, UI change, oracle change, ABI change or Git ref mutation occurred. Planned local worker/results paths remain uncreated. [inputs.json](evidence/w079/inputs.json), [receipts.json](evidence/w079/receipts.json) and [working-context.md](evidence/w079/working-context.md) retain the narrow audit trail.

Owner03/20 consumer adoption remains open: A/Metal shown, B confirms permanent downgrade plus cancellation, then returnA may reuse a UI-held frame without consulting the engine. This is an unresolved consumer status/adoption issue; the catalog does not claim a UI pass or demonstrate engine-cache leakage.

## Later owner refresh — wave 9

The read-only owner refresh at **2026-11-26 16:35:58 UTC** found lane 03 at `92dc7a69c0032141ee49de0b96940fccab83a33e`. Its preview now requires request and publication-ticket identity and reconsults the engine on every activation. `NativeTests/StudyPreviewAdoptionTests.swift` contains `testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade` (blob `c514f15cf000538f56d7653b7b30d85d451442ad`). The hosted source uses a controlled synthetic producer. Its retained [input receipt](https://github.com/mirzotipi-wq/APP1/blob/92dc7a69c0032141ee49de0b96940fccab83a33e/docs/parallel/03/evidence/preview-adoption-inputs.json) explicitly leaves Apple typechecking, hosted execution and the hook-only before/fail run unperformed. No owner acknowledgment or new UI runtime pass is claimed.

Lane 04's tested preview still has the earlier shortcut; the owner 03 remedy is not integrated here. The earlier owner-status paragraphs describe the wave 8 freeze and the historical w057 proposal. The current remaining work is **integration and execution**, rather than absence of a remedy in owner 03 source. The hosted assertions observe accessibility/current-status/backend/warning state; pipeline tests separately observe converted bytes and the source assigns a single paired Frame. Independent inspection of displayed CGImage bytes is a bounded coverage limit, not a newly demonstrated defect or additional mandatory gate.

Owner 03's CPU oracle also changed tiny-output integration/packing construction (blob `82e54a53f3d32d745aee1edfa297086504fb81ec`). It retains the six-parameter/three-sample/three-area float4 layout and original sample-intensity meaning. These tables execute lane 04's older oracle, so they do not establish parity of the combined revision. Lane 20 must retain lane 04's engine, width-aware eligibility and guarded shared header while integrating owner 03's oracle/consumer/test, then repeat the relevant CPU, host, native parity and adoption checks. The immutable owner comparison is blob `55bb057aecbca8210673c3f2ae85b8323bff86fb`; retained owner evidence is blob `405b9246dfc00cee189229424ed9d9fbb7bf4e7b`.

## Post-campaign current-source execution and failed finalization

Source7 `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`, native job140034909086 in run45854806270 attempt1, compiled the Debug app/native bundle and Release app and executed178 methods, including 29 cache methods and all4 additions. Every method has one start/one pass;0 failures/skips/duplicates/omissions. Actual Metal canonical6/strict8 assertions and19 actual CPU payload rows are retained. The command reached the18-minute workflow limit after tests passed; the result bundle lacked finalization and export failed. The standalone accounting step passed. The inline Metal guard after xcodebuild was not reached; a source echo is not an executed guard. Warm-up also exited1. [Raw log](evidence/ci/wave07-native-140034909086.log), [metadata](evidence/ci/wave07-native-140034909086.json), [complete manifest](CI_MANIFEST.json).

Exact recorded test invocation for that simulator execution:

~~~sh
/Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug -destination id=12FCFD0F-7FCF-463F-A605-132A7E18B5D5 -derivedDataPath /Users/runner/work/_temp/keyfill-build -parallel-testing-enabled NO -resultBundlePath NativeTests.xcresult CODE_SIGNING_ALLOWED=NO "-only-testing:KeyAndFillTests" test-without-building
~~~

The18-minute limit belongs to unchanged workflow blob `55e68ee810a4dbe72cd8bd5c4aba295958f80d7c`, outside that command line. The recorded simulator UUID and runner paths describe this execution; they are not portable device identifiers. Job outcome is **failure**, not a normal test-command completion. Source6's successful command/export remains separately pinned. Release native execution, physical-device behavior and memory/latency instrumentation remain unperformed.

One native-only retry was accepted on the same source: attempt2 job140103955982, queued at18:29:38 UTC. No source, test inventory, threshold, timeout or harness change accompanied it. [Request](evidence/ci/wave07-native-retry-request.json), [initial retry state](evidence/ci/wave07-native-attempt2-initial.json). The API's copied core/UI attempt envelopes are not new executions.

Owner03's final retained head is `6f93f95c817d2bd230ae93554dea25a174a437f8`. Preview/oracle are unchanged from the prior refresh. Its original hosted AX observer compiled/executed at source342 and failed before scene switching; its corrected pixel observer `f65004c8b7ca86248a163c80b9d7a3c02dabf20e` remains Apple-unverified and removes AX badge/warning assertions. Hook-only before/fail and combined03/20 gates remain open. These changes alter no fixture constructor or lane04 source hash in this catalog. [Owner refresh](evidence/w097/final-owner-refresh-receipts.json).


## Final source and successful native retry

The single unchanged retry of source69eb9c5 completed successfully as run45854806270/attempt2/job140103955982. It compiled Debug app/native tests and the Release app, executed 178 Debug native methods including 29 cache methods with no failure/skip/duplicate/omission, passed the actual inline Metal guard and standalone accounting, and finalized/exported the XCTest bundle. MacOS portable execution separately passed 379 tests. Release-native execution was not performed. The full workflow retains failure from other UI outcomes.

The exact observed command is:

```sh
/Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug -destination id=12FCFD0F-7FCF-463F-A605-132A7E18B5D5 -derivedDataPath /Users/runner/work/_temp/keyfill-build -parallel-testing-enabled NO -resultBundlePath NativeTests.xcresult CODE_SIGNING_ALLOWED=NO "-only-testing:KeyAndFillTests" test-without-building
```

[Raw log](evidence/ci/wave07-native-140103955982.log), [metadata](evidence/ci/wave07-native-140103955982.json), [artifacts](evidence/ci/wave07-attempt2-artifacts.json). The 14 actual Metal metric rows and 19 CPU resource payload rows exactly match the failed first attempt. Native1's178 method passes,18-minute command timeout and unfinalized result remain preserved; the retry changed no source, workflow, threshold, inventory or timeout. Suite execution/wall durations are test-run measurements, not GPU benchmarks.

Owner03's corrected observer now has successful Apple builds. Its aggregate job reports failure, but raw terminal logs are unavailable and stale step metadata cannot establish actual method counts or the corrected test outcome. The [root observation](evidence/owners/03-corrected-terminal-observation.json) supersedes earlier compile-pending statements without inferring a failed method, no execution or a combined owner pass.
