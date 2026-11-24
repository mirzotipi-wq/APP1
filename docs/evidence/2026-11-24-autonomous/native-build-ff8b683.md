# Current native simulator build evidence

Exact source: `ff8b683098a720b4c7abdddf212f85a79f3cfd39`. Workflow [45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829), native job [138342789331](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138342789331).

Both generated-project unsigned Debug and Release build/upload steps completed successfully before the job entered native unit testing. The portable core job [138341537614](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138341537614) also completed successfully: 245/245 Debug and Release, 28 Python checks, six established shared-kernel fixtures and eight strict far-camera controls. Its full retrieved log is `ff8b683-github-core.log`.

## Commands and toolchain

The exact committed workflow generates the project with `xcodegen generate`, selects an available iPhone simulator, and executes both configurations with:

```sh
xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Debug \
  -destination "id=$SIMULATOR_ID" -derivedDataPath "$RUNNER_TEMP/keyfill-build" \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project KeyAndFill.xcodeproj -scheme KeyAndFill -configuration Release \
  -destination "id=$SIMULATOR_ID" -derivedDataPath "$RUNNER_TEMP/keyfill-build" \
  CODE_SIGNING_ALLOWED=NO build
```

Each build step includes the icon and privacy bundle validators, and the following upload step passed. The job's complete unit-test log was not yet available at this artifact observation; these commands are captured from the exact executed workflow, while step completion and actual artifact metadata provide the independent build evidence.

The actual current Release bundle records **Xcode 26.6 (`DTXcode=2660`, build `17F113`)**, **iPhoneSimulator SDK 26.5**, and **iOS 17 minimum**. The local package test toolchain (Swift 6.4.3 Linux) is distinct from GitHub's core Swift 6.4.2 and the native Apple build.

## Retrieved artifacts and checks

- [Release simulator artifact 14906397278](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14906397278): outer ZIP SHA-256 `b0e2ab6397be3f1dc65118280a788e51f23a1d4c050ada65543a26eaabf49b3a`, matching GitHub's digest; both outer/nested CRC checks passed.
- [Debug simulator artifact 14905269362](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14905269362): upload and source association verified through the artifact API. This audit downloaded Release, not Debug.
- The actual Release executable contains x86_64 and arm64 slices. Each has Mach-O `LC_BUILD_VERSION` platform 7 (iOS Simulator), minimum 17.0.0 and SDK 26.5.0.
- Bundle identity is `com.example.keyandfill`, version 0.1.0, build 2. This is a prototype identity, not owner-approved production signing configuration.
- Existing source/bundle icon and privacy validators passed locally on the downloaded app. Actual `Assets.car`, app-icon metadata, packaged privacy plist and `default.metallib` with `MTLB` header are present. The privacy plist declares no app tracking/collection and retains C617.1 / 3B52.1 for its scoped file metadata use.
- Machine-readable extracted metadata is retained in `ff8b683-release-inspection.json`.

## Gate scope

This satisfies the protected **native_build** criterion: generated project, actual unsigned simulator build, captured command, Xcode version and SDK. It does not establish complete unit/UI execution, file-provider behavior, performance, native accessibility, physical-device launch, a signed device/archive, App Store compliance or owner approval. Native units and UI shards remain separately pending. M01 remains active until its persistence smoke gate is established at this candidate.
