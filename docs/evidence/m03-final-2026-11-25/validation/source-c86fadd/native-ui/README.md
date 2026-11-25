# C86 native and UI execution evidence

Source: `c86fadd867322b816f400b003de461e0e418dc52`  
Workflow: [iOS Prototype run 45709267885](https://github.com/mirzotipi-wq/APP1/actions/runs/45709267885)

This run completed naturally. All 118 selected native methods passed. The required UI shards recorded 34 passes and one accessibility failure. **The complete required native/UI execution is failed.** These observations apply to C86; they do not establish acceptance of a later source revision or completion of M03.

| Shard | Expected | Started | Passed | Failed | Skipped | Unstarted | GitHub job conclusion |
|---|---:|---:|---:|---:|---:|---:|---|
| Native | 118 | 118 | 118 | 0 | 0 | 0 | Success |
| Room precision | 5 | 5 | 5 | 0 | 0 | 0 | Success |
| Library reference | 9 | 9 | 9 | 0 | 0 | 0 | Success |
| Studio export | 10 | 10 | 10 | 0 | 0 | 0 | Success |
| Studio optics | 10 | 10 | 10 | 0 | 0 | 0 | Success |
| App accessibility | 1 | 1 | 0 | 1 | 0 | 0 | Failure |

## Source-specific accounting

Each shard retains its original `native-tests.log`, CI `native-method-accounting.json`, pre-existing `root-method-accounting.json`, attachment manifest, and `macos-environment.log`. The CI and root reports agree on the expected methods and all accounting outcomes. Their original bytes are preserved, including the failed AX reports.

The summaries use those retained C86 inventories. The 118-method native log was **not** reparsed against the later C855 checkout, which contains 132 native methods. No app tests were run during this retention task. Existing older failed evidence remains unchanged.

The machine-readable [executed summary](executed-summary.json) records the six jobs and method totals. The [GitHub observation](github-observation.json) records the completed job summaries and artifact metadata fetched for this run.

## Accessibility failure retained

`StudioAppAccessibilityUITests.testEssentialWorkflowAtDefaultAndLargestAccessibilityTextSize` failed in the default-size Intensity editor. The `precisionValue` field, labeled **Intensity in cd**, had an observed frame of `(32.0, 267.0, 310.66666666666663, 22.0)`. Its 22-point height failed the 44-point target-height requirement. The largest-accessibility-text portion was not reached. The accounting report's one invalid sequence identifies this same failed method; it is not an additional failed test.

The original exported files are retained under `ax/`:

| Evidence | File |
|---|---|
| Failure screenshot | [A7BA7EAC-2EA1-4F67-B461-384B0B47C6B8.png](ax/A7BA7EAC-2EA1-4F67-B461-384B0B47C6B8.png) |
| Observed control and text frames | [9E5FCE5B-A908-4947-9436-BA91C792594D.txt](ax/9E5FCE5B-A908-4947-9436-BA91C792594D.txt) |
| Failure accessibility hierarchy | [2A2C9EC2-7AEB-4BC9-8FC1-7EFA353E02B4.txt](ax/2A2C9EC2-7AEB-4BC9-8FC1-7EFA353E02B4.txt) |
| Default Inspector screenshot | [16A7EC9F-3DBB-4FC6-8A49-2E2B66BFDCAC.png](ax/16A7EC9F-3DBB-4FC6-8A49-2E2B66BFDCAC.png) |
| Default Plan selection screenshot | [7FB9A55B-6191-4917-BDDB-0677DE5E391F.png](ax/7FB9A55B-6191-4917-BDDB-0677DE5E391F.png) |
| Default Plan choices screenshot | [44C297FF-A40D-4A3E-8900-3BD0213147F0.png](ax/44C297FF-A40D-4A3E-8900-3BD0213147F0.png) |

Attachment names and originating test identity remain in the original AX manifest. A later repair requires its own execution; this failure has not been relabeled.

## Artifact integrity

[Artifact receipts](artifact-receipts.json) identify the exact six full GitHub artifacts: native `15068218762`, room `15069156874`, library `15069173506`, export `15070070056`, optics `15068608323`, and AX `15068312010`.

Each actual local ZIP's SHA256 and byte length matched its GitHub API record. All ZIP members passed CRC verification. Each retained archive-derived file matched its ZIP member byte-for-byte; per-file SHA256 and original archive member paths are recorded. The pre-existing root accounting reports are separately identified as retained derived reports and hashed without rewriting them.

The full ZIPs, movies, result bundles, and unselected attachments are not duplicated in this packet. The manifests and exact artifact receipts preserve their provenance without adding those large files to the repository.
