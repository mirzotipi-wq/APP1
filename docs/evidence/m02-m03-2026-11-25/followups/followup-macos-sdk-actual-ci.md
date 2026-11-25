# Actual macOS SDK repair: verified CI artifact

**PASS for the completed Darwin x86_64 host atomic-write probe.** Run [45604744523](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523), simulator job [139182923426](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523/job/139182923426), compiled revision `f6f43dde19be7a554bc5c6924e3239c18b34d1be`. This review reads the downloaded artifact and raw phase outputs, not merely successful step metadata.

## Download and provenance

Artifact [atomic-library-write-macos-evidence, ID 15017404141](https://github.com/mirzotipi-wq/APP1/actions/runs/45604744523/artifacts/15017404141), created `2026-11-25T11:51:16Z`, downloaded as **39,276 bytes**. Computed SHA256 `c26208e64bdf0f68681e39596c0657afcb23b162306be8ae30aae5ae0f377b42` matches GitHub's digest; ZIP CRC validation passed.

Both retained compile-manifest copies are byte-identical. Their SHA256 `816323347f58d3e9b742a481f4393f50f8d3a5005c187be838a7a7c4fe922ca1` matches wrapper and probe references. Independently rehashed all **31 compiled sources and two diagnostic scripts against committed f6 bytes**; their recorded hashes remain identical before compilation, after compilation, and after the probe. The runtime reports the helper matched its manifest hash `9dd2276885aff203edc534b33ae80df5afc0be8203bcc0a2cd380fe8278ac449`; the temporary executable itself is not included in the archive, so this is a verified runtime receipt, not a downloaded-binary rehash.

## Actual SDK and execution

The raw SDK stdout and manifest agree: `/usr/bin/xcrun --sdk macosx --show-sdk-path` selected `/Applications/Xcode_26.6.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk`. Discovery returned zero in **0.017 seconds**, under its ten-second bound. Recorded `DEVELOPER_DIR` is Xcode 26.6; `SDKROOT` and `TOOLCHAINS` were unset.

The actual compiler argument array contains exactly one `-sdk` pair with that host SDK, alongside `-O`, the isolated module cache, all 31 sources, and the output binary. Apple Swift **6.3.3**, target `x86_64-apple-macosx26.0`, compiled successfully in **57.307 seconds** under the 180-second bound, with empty compile stdout/stderr. The probe returned zero in **0.396 seconds** under its 140-second bound. Both wrapper and probe status are `passed`.

## Persistence checks and scope

All **11 EFBIG checks are true**. All four raw phase JSON files match the result. The real save reports `save_threw`, `writeAttempted=true`, immediate errno **27**, and an `NSPOSIXErrorDomain` code-27 entry beneath the Cocoa error. Only the injection child receives the 32,768-byte file limit; the receipt records unchanged parent limits and signal handling.

Independently checked all five fixture sizes/hashes: prior, after, and reopened library are identical **3,900-byte** snapshots; candidate and unrestricted control are identical **242,569-byte** snapshots. Fresh verification preserves active identity, both unrelated records, complete prior state, and exact prior bytes, and successfully reopens the unrestricted candidate.

This resolves the previously pending actual macOS helper-compile/EFBIG validation for f6. It does **not** establish a full native-suite, Metal, UI, physical-device, iOS, ENOSPC, power-loss, or macOS interruption/rename-only pass. Commit-interruption execution was explicitly not requested in this macOS artifact.

Owned evidence: `/var/tmp/keyfill-c0abc39c4f18/sdk-repair-macos-ci-f6-15017404141/`, including the original ZIP, metadata, download receipt, ZIP inventory, `verified-summary.json`, `raw-text-receipt.json`, and unchanged extracted raw files. No source edits, commits, pushes, reruns, or cancellations were performed.
