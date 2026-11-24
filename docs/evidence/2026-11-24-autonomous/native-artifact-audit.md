# Native Release artifact audit — 2026-11-24

## Scope and outcome

The wave-ten native artifact specialist independently inspected the downloaded Release simulator artifact for source `0fce248b4e61bace88002b40f6c56fddedb19c8a`. The package has the expected executable, icon assets, privacy manifest and compiled shader library. No new packaging defect was established by these checks.

This is a **simulator artifact audit**, not a device install, an App Store archive, a runtime privacy audit, a native test pass or a release approval. Main advanced during the audit to `0d63dd872bbd20aaa72f9263b51e2208b6ee926f`; this artifact does not verify that newer source. No milestone or quality-score promotion follows from this report.

- [Source workflow 45355893140](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140).
- [Release artifact 14903072593](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140/artifacts/14903072593), `KeyAndFill-iOS-Simulator-Release`.
- Downloaded ZIP SHA-256: `92cf2f5b2328c3ba7aa22029aca3eeec5293a94a05fbf4949df5741adff0f5cb`, matching the GitHub artifact digest recorded by the integration lead.
- Scratch ZIP: `/workspace/scratch/73dcd6a65726/verification/0fce248-release.zip`.
- Extracted bundle: `/workspace/scratch/73dcd6a65726/verification/0fce248-release/KeyAndFill.app`.

The outer GitHub artifact ZIP and its nested `KeyAndFill-simulator-release.zip` both passed `ZipFile.testzip()` independently during this audit. No binary is added to the repository.

## Actual packaged values

| Item | Observed result |
| --- | --- |
| Display name and identity | Key & Fill; `com.example.keyandfill`; version `0.1.0`, build `2`. These remain development identity/version values. |
| Platform | `CFBundleSupportedPlatforms = [iPhoneSimulator]`; `DTPlatformName = iphonesimulator`. |
| Minimum OS and SDK | `MinimumOSVersion = 17.0`; `DTSDKName = iphonesimulator26.5`; SDK build `23F81a`. |
| Xcode build metadata | `DTXcode = 2660`; `DTXcodeBuild = 17F113`. |
| Device families | `[1, 2]` in the bundle metadata. This does not verify iPhone/iPad layouts or a physical device matrix. |
| Executable | 10,398,568-byte universal Mach-O; actual x86_64 and arm64 slices. |
| Mach-O platform commands | Both slices contain `LC_BUILD_VERSION` platform `7` (iOS Simulator), minimum `17.0.0`, SDK `26.5.0`. This independently agrees with Info.plist. |
| Icon packaging | `Assets.car` exists (32,568 bytes), and both phone/tablet primary-icon metadata refer to AppIcon. |
| Extracted icons | Phone PNG decodes as 120×120 RGBA; tablet PNG as 152×152 RGBA. Every decoded alpha value is 255. |
| Privacy manifest | Present, parseable, and semantically identical to the exact source revision. Declares no tracking, tracking domains or collected data types; file-timestamp reasons remain C617.1 and 3B52.1. |
| Metal library | `default.metallib` exists (10,892 bytes), begins with `MTLB`, and contains the `keyfillStudy` name requested by this revision's renderer. This is packaging evidence, not successful pipeline creation or GPU execution. |
| Distribution resources | No `embedded.mobileprovision` or `_CodeSignature` directory in the extracted app. No owner identity, certificate or App Store signing was used or verified. |

### Signing terminology

The workflow's build command sets `CODE_SIGNING_ALLOWED=NO`; the resulting artifact remains an unsigned simulator build in the distribution sense. The x86_64 slice has no `LC_CODE_SIGNATURE`. The arm64 slice does contain a single CodeDirectory with flags `0x20002`, which combines Apple's **ad hoc** and **linker-signed** flags. There is no CMS signature blob in that embedded superblob. This linker-generated code directory must not be described as an owner-signed device build or distribution archive.

The Mach-O layout/platform interpretation was checked against Apple's [loader.h](https://github.com/apple-oss-distributions/xnu/blob/main/EXTERNAL_HEADERS/mach-o/loader.h), and the two flag definitions against Apple's [cs_blobs.h](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/cs_blobs.h), retrieved on 2026-11-24. The parser traversed every bounded load command in each actual slice; the observed values above are from this executable, not inferred from its filename.

## Debug-fixture exclusion evidence

At the artifact's exact revision, `App/ProjectStore.swift` encloses fixture setup and conflicting-write simulation in `#if DEBUG`. Searching the complete Release executable bytes found zero occurrences of each of these seven distinct markers:

`KEYFILL_UI_TEST_ID`, `KEYFILL_UI_TEST_CONFLICT`, `KEYFILL_UI_TEST_CORRUPT`, `KEYFILL_UI_TEST_FULL_LIBRARY`, `intentional UI test corruption`, `KeyAndFill-UITests`, and `-ui-testing`.

The source condition and absence of those strings support exclusion of the specific fixtures. They are not a formal proof of every Release code path, a complete symbol audit or an executed attempt to activate fixtures. The normal application's process behavior was not exercised here.

## Verification commands and provenance

The following commands ran successfully from the repository:

```sh
python3 scripts/verify_app_icon.py --bundle /workspace/scratch/73dcd6a65726/verification/0fce248-release/KeyAndFill.app
python3 scripts/verify_privacy_manifest.py --bundle /workspace/scratch/73dcd6a65726/verification/0fce248-release/KeyAndFill.app
file /workspace/scratch/73dcd6a65726/verification/0fce248-release/KeyAndFill.app/KeyAndFill
python3 scripts/agent_cycle.py check
python3 scripts/agent_cycle.py next
```

Both verification scripts and the source icon PNG/catalog were byte-compared with `git show 0fce248:<path>` and are unchanged from the artifact's revision. The packaged privacy plist was separately parsed and compared with that revision's exact source plist. Python standard-library `zipfile`, `plistlib`, `struct` and `hashlib` checked archives, metadata, Mach-O commands and hashes; Pillow decoded the two compiled icon PNGs. No macOS `codesign`, `otool`, `actool` or simulator is available in this Linux audit environment, and none is claimed to have run.

| File | SHA-256 |
| --- | --- |
| `KeyAndFill` | `a1d510a88f565384c89ff5f8b9b68644612abe8b826dcdf262fc1ef6dcce545f` |
| `Info.plist` | `43926632a2662f98485b091a6fa76c5eaf6f63143b15f6e1c76d872b8280ee8d` |
| `Assets.car` | `b3a34f8fca06436ad53d02c4a5dc67123fbf7103a5ef794561b66b4a92c097c8` |
| `PrivacyInfo.xcprivacy` | `eabf4d87037a59ab0d747076f8cd55297a2bf47cecdf7b54b760e3552c0f3ea8` |
| `default.metallib` | `18a18e2f70fb1399e48057db456ef65bd33cfbeb090b7bc82a8d1c7ad27c2560` |
| `AppIcon60x60@2x.png` | `35c4bd2a7dbe0bc6e44354d900b95c60598a7984fb65b2268e962f05eda72684` |
| `AppIcon76x76@2x~ipad.png` | `2bfa5894109b7d9202d87628a412a3c1664ed062c4f19cc31cdb966af928cbed` |

## Native job observation and missing evidence

The direct single-job fetch URL was unsupported by the connector, so the reviewer used the supported run-jobs endpoint once. Job `138314533584` was still finalizing when inspected. Its Debug and Release build/upload steps were successful. The native-unit step was **cancelled**, from `08:41:04Z` to `08:57:50Z`; the finalized-result export step failed, and evidence-upload steps completed. No test count or assertion outcome was available from that status.

One attempt to retrieve the native job log returned **BlobNotFound** at `08:57:35Z`. The reviewer did not repeatedly poll. The integration lead subsequently reported the newer grouped workflow [45360664075](https://github.com/mirzotipi-wq/APP1/actions/runs/45360664075), but this report does not infer the exact cause of the older unit cancellation from timing or concurrency configuration. Retrieve the completed log before diagnosing it.

The complete native unit/persistence/UI results, actual Metal execution, file-provider behavior, current-source bundle, physical-device tests and signed distribution evidence remain outstanding. The next useful native verification is the exact newer source's build/test output, followed by genuine result-bundle and screenshot inspection; this historical artifact cannot substitute for it.
