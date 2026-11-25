# Independent accessibility audit control

## Work packet

Base revision: **cbf94cecb113c1f03b0b8c7287e763655c14ec11**. Root owns integration and evidence; existing worker a100 implemented the separate diagnostic; a097 independently reviewed the frozen source. All 100 original workers remain completed. This packet changes no protected contract or production application source.

Two completed Intel runs, b298 and f6, reached both required Key & Fill audit screens and returned Apple `Code=-56` without issue-handler findings. The later 214 library job acquired no ARM runner and executed no audit. These observations establish neither a clean app audit nor a specific platform cause. Prior concrete accessibility findings and the manual device gate remain unresolved.

The primary candidate retains all application assertions and deadlines, builds UI bundles before boot, and captures host/failure diagnostics. It was published as cbf94ce and is now executing. A small independent control investigates audit execution while the complete application workflow continues. Its dedicated workflow has separate concurrency and triggers only for its own source/workflow changes or manual dispatch.

## Falsifiable question and implementation

Can the same full Apple audit complete on a minimal standard SwiftUI screen in the current Intel/Xcode/runtime environment? The fixture has system text and one standard button; its action changes an in-memory label. The audit leaves that button untouched. There is no Key & Fill rendering, persistence, custom control, network work or repeating animation. This is a separate target, not a production launch mode.

The environment is standard `macos-26-intel`, Xcode 26.6/build 17F113, iOS 26.5 and iPhone 17 Pro. The workflow records the actual host image, architecture, selected Xcode/SDK, destination, source revision, exact source copies and pre/post hashes. It builds before boot and executes exactly one named XCTest method with parallel testing disabled.

The test verifies a visible, enabled button, retains a genuine before-audit screenshot, and invokes `.all` once. Every issue handler returns false. Descriptions have UTF-8-safe bounds; at most 32 issue descriptions are logged, while every issue remains a failing XCTest issue. Thrown errors are logged with their original NSError domain/code and rethrown. Monotonic markers distinguish launch, readiness, audit entry, returned issue count and thrown error. No issue-element query, fallback selector, sleep, retry or idle override is added.

A pass requires exactly one expected test start and terminal pass; exactly one audit entry and zero-issue return; no thrown marker; successful original native/log commands and GitHub test-step outcome; stable source hashes; and finalized native counts of one passed, zero failed and zero skipped. Raw audit evidence is retained separately from verification/export failures. Missing or unfinished execution cannot become a pass.

The new diagnostic's boot limit matches the primary workflow's ten minutes: actual f6 boot steps took 419 seconds for library and 325 seconds for studio, exceeding the initial four-minute proposal. The diagnostic's step maxima sum 30 minutes; its job allows 32 minutes including setup/finalization overhead. Its audit step remains six minutes. All existing primary bounds remain unchanged. Independent review also caught a workflow source copy under a hidden directory; its final visible copy path and manifest mapping retain that source in the uploaded artifact without enabling broad hidden-file upload.

## Interpretation and acceptance boundary

An observed `audit_threw` Code=-56 reproduces that error independently of the full app. Entry without return proves an unfinished control audit within its deadline, not necessarily the same service error. Build, boot, launch and readiness timeouts cannot establish audit reproduction. A control returning with findings differs from a timeout and remains failed. A clean control would not establish that Key & Fill is accessible or replace the two required app audits or manual device review.

The control imports no production package and changes no primary workflow, app assertion, audit type, test inventory or deadline. Local preparation and an eventual control result provide diagnostic evidence only. M02/M03 completion still requires the existing acceptance gates.

## Local validation and independent review

The [structural receipt](../validation/accessibility-control/structural.json) records two YAML parses, seven shell parses, six Python parses, one declared control test and final file hashes. Linux Swift syntax parsing passed; this is not Apple typechecking. The [ten synthetic result-flow checks](../validation/accessibility-control/synthetic-result-checks.json) accepted one complete pass and rejected empty execution, skipped/wrong tests, interruption, returned issues, Code=-56 and zero native counts, while preserving original native exit 65. They did not execute an Apple process.

The [independent review](followup-accessibility-control-independent-review.md) approved final workflow SHA256 `e9241d0ef66cc09e33ef0043975b82114a1ea841f7953de89e5da49241f0cf8f` and README `11e7fbba52cc9f429b9ebff4ea892d47524ace5c3a2ccab699ee79c8b6b61425`; all five hashes are in the receipt. Root also read the complete source and checked the correction boundaries. Actual Apple compilation, native-result schema and audit outcome remain unverified before publication.

An executor reset interrupted preparation. The five code/project/README files were recovered and matched to retained hashes before validation. Full CI logs were retained independently; native/room excerpts were selected again and have fresh manifests. Identity with the lost intermediate excerpt files is not claimed. The earlier preparation review is preserved as a timestamped historical observation, not substituted for current-source review.

## Actual preceding and current CI

[Run 45613203857](https://github.com/mirzotipi-wq/APP1/actions/runs/45613203857), exact 214ca90, completed with failure at 13:47:26 UTC because its ARM library job acquired no runner. Every executed job passed: core, unsigned Debug/Release/native, room/precision and studio/export.

| Executed scope | Actual result |
| --- | --- |
| Native | 110 unique passes, zero failures/skips; all three required Metal methods passed |
| Room/precision UI | 5/5 passed, zero failures/skips |
| Studio/export UI | 20/20 passed, zero failures/skips; all ten optics workflows passed |
| Library/reference UI | No runner, no steps, all eleven methods unrun |

Root independently parsed the complete logs and verified exact native/studio inventories. Selected raw lines, terminal metadata, artifact metadata and summaries are retained for [native](../validation/214-native-terminal/terminal-summary.json), [room](../validation/214-room-terminal/terminal-summary.json) and [studio](../validation/214-studio-terminal/terminal-summary.json), each with root verification. Full artifact archives were listed, not downloaded. These 25 UI passes do not make an unexecuted library shard or full workflow pass, and do not erase f6's earlier library readiness failures.

At **13:57:07 UTC**, current [cbf run 45623581873](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873) had core success, native build in progress, and all three UI bundles built successfully before simulator boot. [API progress receipt](../validation/checkpoint9-progress.json). No new UI/audit outcome or independent-control execution is inferred from this progress.

The [focused readiness review](followup-launch-readiness-diagnosis.md) established no decisive state/data defect or actual duplicate accessibility node. A large-fixture double load is a concrete unmeasured cost. The new failure-state and host diagnostics should inform any product patch. Editing remains unverified pending revalidation of the outstanding library readiness workflows; the newer ten complete optics passes are retained explicitly.

## Primary references

Apple documents the automated current-screen audit, failure behavior and the continuing need for assistive-technology testing in its [audit documentation](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app.md). The [official Intel image manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md) lists installed toolchains; the workflow checks its actual selected environment. [Official artifact documentation](https://github.com/actions/upload-artifact#uploading-hidden-files) explains the hidden-file omission resolved during review. The bounded research and source-constraint reports in this folder retain alternative-toolchain options without claiming any such comparison executed.
