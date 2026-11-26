# Package and native target configuration

## Reviewed source and evidence scope

This inventory describes native source `08e80c756cb7c8aa4eaf11f27932c8f701000be1`,
the documentation checkpoint `46a161cb01d0aee2e91940dbd06d82cfe2df5821`, and
published root test source `7bdea15c771d7dfeeb3f20d011b3c02e4bc5b34f`.
All 179 entries in the root's [wave08 source manifest](evidence/wave08/source-manifest.json)
were compared with Git bytes at the frozen documentation checkpoint: no mismatch.
That establishes equality within the declared manifest scope, not whole-tree or
runtime equivalence. This document changes no package, native target, feature or CI.

The authoritative configurations are [Package.swift](../../../Package.swift),
[project.yml](../../../project.yml),
[ios-prototype.yml](../../../.github/workflows/ios-prototype.yml), and
[native_test_shards.py](../../../scripts/native_test_shards.py).
There is no `.github/workflows/ci.yml` at these revisions.
The root's successful [package dump](evidence/wave08/package-dump.json) and
[package description](evidence/wave08/package-describe.json) record actual SwiftPM
resolution. Native membership below is the XcodeGen **declaration**; generation,
Apple SDK compilation and native execution remain unverified.

### Observation correction after the initial inventory

Apple CI later supplied an actual owned-source failure, not merely an absent
native check. At `5ccfbaae821a32d88c12ed8b3abf1600aef25753`, macOS package job
`140019833325` and native UI build job `140019833234` failed under Apple Swift
6.3.3. The two task-lifetime properties in `StudioSession` produced unexpected
getter and init-accessor diagnostics from `ObservationIgnored`. Full logs and
exact source identities are retained in
[apple-observation-failure.json](evidence/wave08/apple-observation-failure.json).

Correction `8b18366c1c718c2c81f6b275d66140f6dc9d49c9` places each direct
`@ObservationIgnored` attribute on its complete Darwin property declaration,
with plain declarations in the Linux branch. Property visibility, types,
defaults and all orchestration methods are unchanged. This is the only changed
input between the original and corrected 179-entry manifests.

| Corrected-source evidence | Actual result and boundary |
|---|---|
| `observation-before.json` / `observation-after.json` under wave08 | Typechecking the actual before/after session source with only `canImport(Darwin)` changed to `true` reproduced the four errors before and exited zero after. Swift 6.0.3 Linux macro probe only; no Apple SDK or linking. |
| [wave08-fixed/debug-command.json](evidence/wave08-fixed/debug-command.json), [debug.log](evidence/wave08-fixed/debug.log) | Full corrected package: **431 passed, zero failures**. |
| [wave08-fixed/release-per-file-command.json](evidence/wave08-fixed/release-per-file-command.json), [release-per-file.log](evidence/wave08-fixed/release-per-file.log) | Full corrected package: **431 passed, zero failures** with per-file Release optimization, separately from default whole-module Release. |
| [wave08-fixed/native-syntax.json](evidence/wave08-fixed/native-syntax.json) |82 native Swift files parse successfully; syntax only. |
| Apple compilation and native execution of `8b18366` | **Unverified pending subsequent Apple CI.** The older failure is not relabelled as passing. |

Both corrected local case inventories were independently reconciled against
the raw logs. The configuration/source counts below are unchanged; their
historical receipts retain their original revision and scope.

## Swift package membership

The manifest declares Swift tools 5.9, iOS 17 and macOS 14 minimum platforms,
no external package dependencies, and one exported library product, `LightingCore`.
No target declares package resources. `StudioComposition` is an internal target;
it is not an exported product and is not a dependency of the native app target.

| Target | Source root and exact inclusion rule | Dependencies |
|---|---|---|
| `LightingCore` | Default `Sources/LightingCore`; all 35 Swift files, no exclusions. Exact resolved filenames are in `package-describe.json`. | None |
| `LightingCoreTests` | Default `Tests/LightingCoreTests`; all 51 Swift files, no exclusions. Exact resolved filenames are in `package-describe.json`. | `LightingCore` |
| `StudioComposition` | `App`; only `ProjectLibraryOperation.swift`, `ProjectStore.swift`, `StudioSession.swift`. | `LightingCore` |
| `StudioCompositionTests` | `NativeTests`; only `StudioSessionTests.swift`, `StudioPlanSessionTests.swift`, `StudioFeatureSessionTests.swift`, `StudioFeatureWindowTests.swift`. | `StudioComposition`, `LightingCore` |

The last four files select `@testable import KeyAndFill` when that module is
available and otherwise import `StudioComposition`. Their portable execution
uses the actual session/store implementation, but does not instantiate SwiftUI
sheets, native windows, UIKit, AR, StoreKit or an Apple renderer.

### Exact app exclusions

The 47 `StudioComposition.exclude` entries below are relative to `App`.
`Assets.xcassets` excludes its whole subtree. None of these entries removes a
file from the native application; SwiftPM and XcodeGen have separate membership.

```text
ARPlacementController.swift
ARPlacementView.swift
Assets.xcassets
BoundedFileReader.swift
CameraInspector.swift
DistanceValueButton.swift
EntitlementStore.swift
KeyAndFillApp.swift
LightTargetLuxView.swift
LightingPlanExportView.swift
LightingPlanPDF.swift
ManualRoomPlacementView.swift
MetalStudyRenderer.swift
NeutralCardInspector.swift
OpticsInspector.swift
PhotoComparisonView.swift
PrecisionValueButton.swift
ProFeaturesView.swift
ProjectBackupView.swift
ProjectDocumentIO.swift
ProjectLibraryThumbnail.swift
ProjectLibraryView.swift
RealityStudioPreview.swift
RecoveryCapacityView.swift
ReferenceAnalysisService.swift
ReferenceComparisonView.swift
ReferencePhoto.swift
ReferenceStudy.metal
ReferenceStudyPreview.swift
SceneArrangementView.swift
SpatialPreview.swift
StudioEntityGraph.swift
StudioFeatureSheets.swift
StudioGuideView.swift
StudioMeterReadout.swift
StudioPalette.swift
StudioPlanMarkers.swift
StudioPreferences.swift
StudioSettingsView.swift
StudioSlider.swift
StudioSliderEditing.swift
StudioSliderTracking.swift
StudioTextField.swift
StudioTextLayoutDiagnostics.swift
StudioView.swift
StudyKernel.h
SubjectInspector.swift
```

### Exact native-test exclusions from SwiftPM

The 19 `StudioCompositionTests.exclude` entries below are relative to
`NativeTests`. All remain included in the native unit-test target.

```text
BoundedFileReaderTests.swift
LightingPlanPDFTests.swift
ProjectDocumentIOTests.swift
ProjectLibraryPresentationTests.swift
ProjectNameEditorTests.swift
ProjectStoreOperationTests.swift
ReferencePhotoTests.swift
RoomRotationReadoutTests.swift
SpatialEmitterGeometryTests.swift
SpatialPreviewTests.swift
StudioPaletteTests.swift
StudioSliderEditingTests.swift
StudioSliderTrackingTests.swift
StudioTextFieldTests.swift
StudioTextLayoutDiagnosticsTests.swift
StudioTrackingSliderTests.swift
StudioViewportGeometryTests.swift
StudyRenderCacheTests.swift
StudyRendererTests.swift
```

## Native targets, resources and configuration

`project.yml` names the project and scheme `KeyAndFill`, declares an iOS 17.0
deployment target, and references the local package at `.`. All three native
targets set `SWIFT_VERSION: "5.0"` and generate their Info.plists. This is a
language-mode setting, distinct from the installed compiler version.

| Native target | Declared sources/resources | Dependencies and host |
|---|---|---|
| `KeyAndFill` (`application`) | Entire `App` directory, without native exclusions: 47 Swift files, `ReferenceStudy.metal`, `StudyKernel.h`, and three tracked asset-catalog files. Separately includes `Resources/PrivacyInfo.xcprivacy` with `buildPhase: resources`. | Local package product `LightingCore`; the three portable composition files compile as app-module sources. |
| `KeyAndFillTests` (`bundle.unit-test`) | Entire `NativeTests`: 23 Swift files. Also `UITests/StudioViewportGeometry.swift`, a shared helper. | App target plus package product `LightingCore`; `TEST_HOST` is `$(BUILT_PRODUCTS_DIR)/KeyAndFill.app/KeyAndFill`, and `BUNDLE_LOADER` is `$(TEST_HOST)`. |
| `KeyAndFillUITests` (`bundle.ui-testing`) | Entire `UITests`: 12 Swift files, comprising nine XCTest classes and three helpers (`StudioContentReachability`, `StudioViewportGeometry`, `StudioViewportObservation`). | App target. |

The app asset files are exactly `App/Assets.xcassets/Contents.json`,
`App/Assets.xcassets/AppIcon.appiconset/Contents.json`, and
`App/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
The `.metal` and `.h` files are included by the app directory declaration;
their generated build-phase treatment and actual Metal compilation are not
established by this source inventory.

The app sets `MTL_FAST_MATH: NO`, `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`,
device families `1,2`, display name `Key & Fill`, version `0.1.0` / build `2`, and
bundle identifier `com.example.keyandfill`. Test identifiers append `.tests` and
`.uitests`. Generated Info.plist settings include the existing camera-purpose
text, launch-screen generation, and `KEYFILL_PRO_PRODUCT_ID` substitution. That
product ID defaults to an empty string; configuration inventory is no evidence
of a purchase or restore.

The scheme builds `KeyAndFill`, tests both native test targets, and runs in
Debug. The workflow requests Debug `build-for-testing` and Release `build` with
`CODE_SIGNING_ALLOWED=NO`. These are unsigned simulator operations, separate
from SwiftPM Debug/Release and from signing or distribution.

### Privacy manifest and sparse checkout

`Resources/PrivacyInfo.xcprivacy` is tracked at Git blob
`e400f8aa47d2371eab42ca43eb9197fbcb0a48dc`, SHA-256
`faf85354c10094841f8a1dcd974ca746433553eb93d4683243d57357a83602a7`.
The worker's sparse checkout omits `Resources`; its absence on that local disk
does not mean the resource is missing from the repository or native target.
Use a checkout that includes `Resources` for native generation and resource
checks. The declared resource must still be verified in the actual built app.

CI invokes `scripts/verify_app_icon.py` and `scripts/verify_privacy_manifest.py`
on source and on both Debug/Release app bundles. Source hashes and the package
description do not substitute for those bundle checks. No current native
bundle has been inspected by this worker.

## Native test selection

The current source inventory contains **189 native methods** in 23 classes.
The four portable composition classes contribute 35 of those methods; native
execution of all 189 is still a separate requirement. The UI inventory contains
**36 required methods** and **two opt-in diagnostic methods**. Counts here are
declarations, not passing results. The protected-storage navigation regression
is a method inside the existing `StudioSmokeTests` class.

| Selector passed to `native_test_shards.py` | Target/classes | Declared methods |
|---|---|---:|
| `unit` | Entire `KeyAndFillTests` target | 189 |
| `room-precision` | `ManualRoomPlacementUITests`, `PrecisionEditingUITests` | 5 |
| `library-reference` | `ProjectLibraryUITests`, `ReferenceComparisonUITests` | 9 |
| `studio-export` | `StudioSmokeTests`, `LightingPlanExportUITests` | 11 |
| `studio-optics` | `StudioOpticsUITests` | 10 |
| `app-accessibility` | `StudioAppAccessibilityUITests` | 1 |
| `platform-audit` (opt-in) | `AccessibilityAuditUITests` | 2 |

`check` discovers nested UI Swift files and requires every XCTest class to
belong to exactly one required/diagnostic shard. It also checks the five-shard
matrix in `ios-prototype.yml` and the explicitly dispatched
`platform-accessibility-diagnostics.yml`. `verify-log` requires exactly one
ordered start/pass pair for every expected selected method, rejecting failures,
skips, duplicates, foreign methods and omissions. A successful `xcodebuild`
exit alone is insufficient. The main workflow additionally requires the three
actual Metal methods in `StudyRendererTests` to pass without skips.

## Reproducible package commands

Run from the repository root. These are the root's recorded Swift 6.0.3 Linux
commands; the temporary toolchain/build paths are environment-specific. The
root owns serialized builds. This documentation worker ran no build or test.

```bash
KEYFILL_SWIFT=/tmp/keyfill01-swift-6.0.3/usr/bin/swift
"$KEYFILL_SWIFT" --version
"$KEYFILL_SWIFT" package --scratch-path /tmp/keyfill01-build-v8-inspect \
  --cache-path /tmp/keyfill01-cache-v8 dump-package
"$KEYFILL_SWIFT" package --scratch-path /tmp/keyfill01-build-v8-inspect \
  --cache-path /tmp/keyfill01-cache-v8 describe --type json
"$KEYFILL_SWIFT" test --configuration debug \
  --scratch-path /tmp/keyfill01-build-v8-debug \
  --cache-path /tmp/keyfill01-cache-v8 --jobs 1 -Xswiftc -disable-batch-mode
"$KEYFILL_SWIFT" test --configuration release \
  --scratch-path /tmp/keyfill01-build-v8-release \
  --cache-path /tmp/keyfill01-cache-v8 --jobs 1 -Xswiftc -disable-batch-mode
```

The retained CI recipe instead uses `swift test --jobs 2` and
`swift test --configuration release --jobs 2`. Its Linux syntax command is
`swiftc -frontend -parse App/*.swift UITests/*.swift NativeTests/*.swift`:
parsing alone cannot type-check Apple SDK APIs. Full CI also runs tooling,
fixtures and host probes beyond these package commands.

## Reproducible native commands — not executed here

The existing workflow requires `macos-26-intel`, Xcode at
`/Applications/Xcode_26.6.app/Contents/Developer`, iOS simulator SDK 26.5, and an
available **iPhone 17 Pro / iOS 26.5** simulator. Record `git rev-parse HEAD`,
`swift --version`, `xcodebuild -version`, `xcodebuild -showsdks`, and
`xcodegen --version`. Run `bash scripts/ensure-metal-toolchain.sh`, then
`xcodegen generate`. The workflow checks the installed architecture and SDK;
it does not silently select a different simulator or platform.

Set `DEVELOPER_DIR` to that Xcode path, `RUNNER_TEMP` to a writable build root,
and `SIMULATOR_ID` to the available matching device's UDID from
`xcrun simctl list devices available -j`. The workflow's selector rejects an
absent exact device/runtime. Execute each shard with separate build/results
storage, as CI does on separate runners; `NativeTests.xcresult` must be a fresh
destination. The following Bash commands preserve the workflow's native flags.

```bash
set -euo pipefail
TEST_SHARD=unit
selectors=$(python3 scripts/native_test_shards.py "$TEST_SHARD")
tests=()
while IFS= read -r selector; do
  tests+=("$selector")
done <<< "$selectors"
[ "${#tests[@]}" -gt 0 ]

xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug \
  -destination "id=$SIMULATOR_ID" -derivedDataPath "$RUNNER_TEMP/keyfill-build" \
  CODE_SIGNING_ALLOWED=NO "${tests[@]}" build-for-testing 2>&1 | tee build.log
xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Release \
  -destination "id=$SIMULATOR_ID" -derivedDataPath "$RUNNER_TEMP/keyfill-build" \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tee release-build.log

xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug \
  -destination "id=$SIMULATOR_ID" -derivedDataPath "$RUNNER_TEMP/keyfill-build" \
  -parallel-testing-enabled NO -resultBundlePath NativeTests.xcresult \
  CODE_SIGNING_ALLOWED=NO "${tests[@]}" test-without-building 2>&1 | tee native-tests.log
python3 scripts/native_test_shards.py verify-log "$TEST_SHARD" native-tests.log \
  --report native-method-accounting.json
```

For each of the five required UI shards, set `TEST_SHARD` to its table value and
recreate `selectors`/`tests`. The workflow's UI `build-for-testing` uses the same
Debug command **without** `"${tests[@]}"`; the run and `verify-log` remain selected
by that shard. The platform audit is a separate explicit diagnostic workflow.
CI's optional preparatory `boot_simulator.py` step is diagnostic, not test
acceptance. Preserve its actual outcome separately from required execution.
The workflow also verifies built resources, exports result bundles/attachments,
and retains method accounting after failures; the command excerpt is not a
replacement for those evidence steps or the dedicated Metal-method check.

## Actual wave08 receipts and remaining limits

The following root receipts were read at source
`7bdea15c771d7dfeeb3f20d011b3c02e4bc5b34f`; none is a worker-run build.

| Receipt | Observed result | Limit |
|---|---|---|
| [configuration-commands.json](evidence/wave08/configuration-commands.json) | Toolchain, package dump and description each exit 0. | `xcodebuild` and `xcodegen` are both recorded as unavailable (`null`). |
| [debug-command.json](evidence/wave08/debug-command.json), [debug.log](evidence/wave08/debug.log) | Exit 0; terminal XCTest summary: **431 tests, zero failures**. | Linux package coverage only. |
| [release-command.json](evidence/wave08/release-command.json), [release.log](evidence/wave08/release.log) | Exit 1; compilation terminated by signal 9, followed by `fatalError`, before test execution. | Default Release attempt failed; cause is unproven. This is not a passing Release receipt or a source diagnostic. |
| [release-per-file-command.json](evidence/wave08/release-per-file-command.json), [release-per-file.log](evidence/wave08/release-per-file.log) | Exit 0; **431 tests, zero failures**, matched against the full Debug case inventory. | Release `-O` with `-Xswiftc -no-whole-module-optimization`; this changed compilation mode is separate from default Release. |
| XcodeGen, unsigned native builds, Apple typecheck, native/UI execution | **Unverified** at this source. | Neither portable results nor source inventory establish native behavior. |

The successful retry used a separate fresh scratch path,
`/tmp/keyfill01-build-v8-release-per-file`, and retained `--jobs 1` and
`-Xswiftc -disable-batch-mode`. Adding `-Xswiftc -no-whole-module-optimization`
kept Release optimization while compiling individual files. Its Python child
resource accounting recorded a maximum resident size of 359,096 KiB; this is
compiler-process evidence, not app performance. The original default failure
remains unchanged. An optional `/usr/bin/time` wrapper was absent in an earlier
retry setup attempt, before Swift execution; that separate setup receipt is
also preserved. Signal 9's cause has not been established.

[portable-input-equivalence.json](evidence/wave08/portable-input-equivalence.json)
compares all 94 declared inputs from the four resolved package targets plus
`Package.swift`: none differs between the prior CI source `5ccfbaa` and current
`7bdea15`. The prior Swift 6.4.2 CI core job passed default Debug and Release on
those identical portable inputs. This states source equality, not native/UI or
compiler/environment equivalence. The prior overall workflow was subsequently
cancelled after a newer source push; its successful core job remains a distinct
result. Subsequent `7bdea15` CI core job `140036374958` also passed 431 tests
in default Debug and Release; see
[ci-current-core.json](evidence/wave08/ci-current-core.json). Both CI core
results precede the Observation correction. Neither validates its Apple branch.

The prior 175-input manifests included `App` assets/icons, Metal and headers,
core source, package/native/UI tests, `Package.swift`, and `project.yml`. They
omitted the direct native resource `Resources/PrivacyInfo.xcprivacy`. The
expanded 179-input manifest adds that privacy resource plus
`scripts/native_test_shards.py` and the two native workflow YAML files. Git-byte
hashing includes the resource despite sparse local absence. This is **selected
configuration coverage**, not complete CI dependency closure: other invoked
helpers, including `boot_simulator.py`, `ensure-metal-toolchain.sh`, resource
validators, evidence exporters and tooling inputs, remain outside that manifest.
Installed tools, SDKs, runners and runtime state are also separate evidence.

Earlier-source CI failures remain failures; no current-source Apple result is
inferred from historical logs. Startup `agent_cycle.py check` and `next` exited
0 here and identify M03 as active; they validate state references and work
selection, not milestone acceptance. The three existing Void producers still
consume rejected drafts as documented in [FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md)
and [NAVIGATION.md](NAVIGATION.md). Configuration inspection does not fix that
interface boundary or establish Observation, sheet lifecycle, device behavior,
commerce, accessibility acceptance or release readiness.
