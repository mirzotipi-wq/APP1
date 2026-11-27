# Beta engineering campaign — 27 November 2026

User request: launch 100 actual agents and bring APP1 to beta. Starting main was `664e404d1bddf6d19724760139592da30c799418`. Root integrates on `main`; three specialist slots run alongside root. The ledger records only actually created contexts, not planned workers. This packet is an active checkpoint, not a beta/release acceptance declaration.

## Current checkpoint: session safety and fresh Apple validation

67 actual contexts have been created; 64 assignments are complete. [Checkpoint 06](validation/checkpoint-06.json) pins candidate `6661170`: production, portable and native unit inputs remain unchanged from the 579 Debug/579 Release source `2e35eb0`. The updated tooling suite passes 104 tests; source syntax and shard accounting pass. Required inventory is **314 native and 44 UI methods**, plus two diagnostic methods. The **28 original layout captures** remain mandatory. The new largest-text beta workflow adds eight supplemental original screenshot call sites; none has executed yet.

The candidate now requires three real Plan-marker touch workflows and one largest-text welcome/recovery/feedback workflow. Independent source review identified a missing Tools reveal in the new test and the integration corrects it. The simulator job also requires an unsigned arm64 iPhone Release build after native evidence collection, with explicit SDK, executable, icon and privacy-bundle checks. This compile/link gate does not establish signing, distribution or physical execution.

Published [run 45990069958](https://github.com/mirzotipi-wq/APP1/actions/runs/45990069958), source `ee2b160`, is terminal and failed. Its core job passed 550 Debug/550 Release; [independent reconciliation](validation/published-01-core-reconciliation.json) confirms exact tests, twelve original image hashes, six parity/eight precision records and benchmark arithmetic. [Original core artifact](validation/published-01-core-original.zip) and [actual image review](validation/published-01-core-visual-review.json) are retained. Native test bundles failed to compile the complex all-pixel assertion at ReferenceAnalysisServiceTests.swift:60 before any native/UI method ran. The candidate splits the same assertion into explicitly typed comparisons; no method, assertion or tolerance is removed. Fresh Apple execution is required.

The new Linux recovery probe witnesses actual post-archive rename EIO and pre-rename process interruption. It verifies complete originals and identities, retained archives, fresh confirmed retry and separate-process reopen. Its missing-hook negative control rejects an unwitnessed recovery success. Independent replay passed; the probe is now a required bounded core CI step.

Three independently reproduced defects are repaired: exact unchanged AR coordinates at the scene boundary; uncertain finite-panel Float32 silhouette edges now conservatively routed to CPU; and stale Plan gesture callbacks that could move a light twice or erase a later accepted height from history. The Plan probe failed 48 of 62 checks before the repair and passes all 62 afterward. Independent review accepts the state/session implementation; native event ordering remains unobserved until the newly registered real Plan-marker UI drags execute.

Source reviews and focused probes also covered decoding, photometry, caches, color math, PNG filtering, numeric locales, privacy and spatial lifecycle. These are not physical, photographic or platform acceptance. Worker054 records a near-plane projection rounding witness with no current production caller; worker055 records sub-precision room-warning translation sensitivity. Neither review demonstrated a practical beta blocker, and no broad tolerance change was made. The [tester guide](../../BETA_TESTER_GUIDE.md) describes implemented controls and limitations.

## First integrated engineering checkpoint

At the first checkpoint, 26 actual workers had been created and 23 had completed their initial assignments. The [worker ledger](worker-ledger.json) records identities, input revisions, reports and integrated commits. Subsequent batches continue within the root-plus-three concurrency limit.

Implemented: a guarded recovery flow that preserves unreadable original files before creating a healthy library; first-use New/Import without an unwanted starter save; dismissible welcome guidance; local, bounded feedback notes with exact review before sharing. Four real UI workflows and seven native image-analysis rejection/cancellation tests are now registered. These are implementation facts, not native runtime acceptance.

| Verification | Observed result |
| --- | --- |
| Local Swift Debug | 550 passed: 67 composition plus 483 domain |
| Local Swift Release | 550 passed: 67 composition plus 483 domain |
| Python tooling | 102 passed |
| Native source syntax | 103 files parsed; Apple typechecking unrun locally |
| Required fresh Apple inventory | 298 native; 40 required UI; two opt-in diagnostics; 28 original layout captures |
| App icon and privacy source checks | Passed |

[Pinned validation and original logs](validation/checkpoint-01.json) record actual tested revisions. Core Debug was run at `fae13b6`, Release at `b0624cc`; subsequent Apple-only tests and their explicit portable-target exclusion do not change production or portable test bodies. Fresh Apple CI is required for all changed native interfaces.

## Baseline and observed failures

The branch already contains the published finish lanes. Source review found an unreadable-library recovery dead end, first-use New/Import requiring an unwanted starter save, and no local beta-feedback handoff; the implementations above address these gaps. No protected acceptance criterion, pricing decision or publication authority has been changed.

Local Swift 6.4.3 Debug verification passed 37 composition plus 445 domain tests (482 total); 100 Python tooling tests, native Swift syntax, test-shard assignment, app icon and privacy-source checks passed. Linux cannot type-check Apple SDKs or validate native interactions.

Baseline run [45979992218](https://github.com/mirzotipi-wq/APP1/actions/runs/45979992218), source `660b50a`, built unsigned Debug/test and Release simulator apps. Its required accessibility method failed when its first `app.screenshot()` request timed out, after preceding layout assertions passed. The later diagnostic original shows the foreground studio. This is a failed required method, not accepted accessibility evidence. The source candidate captures the physical display via `XCUIScreen.main`, checks foreground state for required captures, and preserves observed metrics before teardown requests. Worker 007 reviewed the final candidate; fresh runtime evidence remains required. The original capture names, 28 opportunities, layout thresholds and accounting gates remain unchanged.

The baseline run is now terminal and failed. Its native job executed all 261 methods successfully, including three real Metal methods, but exceeded the outer 18-minute command deadline after XCTest completed. A reviewed candidate allows 24 minutes for that command and 100 minutes for the complete job, adds phase diagnostics, and preserves normal process exit, all assertions, exact accounting and artifact requirements. Library/reference UI passed eight of nine methods; the archive-delete method timed out waiting for the project-name field value before any archive/delete action. Room/precision, optics and studio/export shards passed. Current-source execution must not be inferred from these earlier results.

## Current limits

Later native/UI results remain source-specific and must be reconciled. Held-out human reference evaluation, physical AR/device trials, payment sandbox/product configuration, customer feedback, signing and owner distribution approval have not been supplied by this campaign. Code work proceeds independently; these checks are not marked passed or removed.

Published checkpoint `ee2b1604bd02176f70a7dcb4c82dbe8146f1b521` has the identical complete tree as local checkpoint `f1d75d5`. [Publication receipt](validation/publish-01.json) records each changed blob, expected parent and exact tree proof. Workflow 45990069958 at that source is terminal with the compiler failure recorded above.
