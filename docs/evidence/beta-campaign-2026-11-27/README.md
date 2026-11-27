# Beta engineering campaign — 27 November 2026

User request: launch 100 actual agents and bring APP1 to beta. Starting main was `664e404d1bddf6d19724760139592da30c799418`. Root integrates on `main`; three specialist slots run alongside root. The ledger records only actually created contexts, not planned workers. This packet is an active checkpoint, not a beta/release acceptance declaration.

## Current published source: 100 workers and verified native builds

All **100 distinct worker contexts** have been created. At this checkpoint, 98 assignments are complete; worker 098 is finishing current UI reconciliation and worker 100 awaits the final readiness-summary delta on their existing identities. The [ledger](worker-ledger.json) distinguishes those follow-ups from new workers. Twenty-six scoped writer commits and their original source objects are preserved.

Current production/test source is **`f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5`**, published with the complete tree of local `a5a6038`. [Publication receipt](validation/publish-03.json) records the expected parent, actual guarded ref update and exact tree. Documentation-only edits after this source do not alter its compiled inputs.

| Current-source verification | Actual outcome |
| --- | --- |
| Linux portable tests | 588 Debug + 588 Release, zero failures/skips |
| Python tooling | 104 passed |
| macOS portable package | 591 passed, including three Darwin-only observations |
| Native unit tests | 323 passed exactly once, no omissions/skips; command and shell exited 0; finalized result |
| Required actual Metal methods | All three passed; six retained fixture comparisons, maximum channel error at most 1 |
| Simulator app/test and Release | Passed; actual Debug x86_64 and Release x86_64/arm64 simulator bundles inspected |
| Unsigned device Release | arm64 iPhoneOS 26.5 compile/link, plist, icon and privacy-bundle checks passed; no physical execution |
| Library/reference UI | All nine passed with finalized result and four retained original PNGs |
| Room/precision UI, attempt 1 | Four passed, one failed exact room-measurement entry |
| Required app accessibility, attempt 1 | One failed exact-value entry; five Default originals retained, zero AXXXL; 23/28 required captures absent |
| Optics and studio/export UI | Still executing at this checkpoint; no inferred pass |

[Core reconciliation](validation/published-03-core/reconciliation.json), [native/build receipt](validation/published-03-native/receipt.json), [library reconciliation](validation/published-03-library/reconciliation.json), and [the actual accessibility failure](validation/published-03-accessibility-attempt-1/reconciliation.json) preserve source-specific evidence. All twelve current synthetic images and scene JSONs are byte-identical to the earlier originals actually viewed by root; their exact hashes are independently reconciled. Native Metal evidence is separate from the portable shared-kernel harness. Current host/compiler timing differs from the preceding host and is not a controlled performance comparison.

The accessibility field remained `900` after one replacement request with `4321.5`; the room width remained empty after Clear and one request for `2`. Original screenshots and AX descriptions agree. Keyboard-queue diagnostics exist, with different timing in the two jobs; they do not establish a product or host-only cause. No parser, typing action, deadline or assertion has been changed. A single fresh-runner retry will be considered after the first run completes, with the originals preserved. Existing library failures from `134f9ad` also remain preserved; current passes with unchanged assertions do not demonstrate a causal source repair.

M01 still needs its current corrupt-file UI smoke. M02's code evidence is ready but its milestone depends on M01; M03 still needs all required workflows and 28 actual layout originals. Eight new beta screenshots are supplemental and cannot replace those 28. Physical reference/AR/device, commerce/customer, signing and owner approval remain outside the passing evidence. The [tester guide](../../BETA_TESTER_GUIDE.md) and [privacy draft](../../PRIVACY.md) reflect the implemented recovery, feedback and locale behavior. The following sections retain earlier snapshots and are not current runtime status.

## Retained candidate checkpoint before publication f94


82 actual worker contexts have been created; 79 assignments are complete. [Checkpoint 07](validation/checkpoint-07.json) pins candidate `700486b`: **588 Debug and 588 Release tests** pass (86 composition + 502 domain), together with 104 tooling tests, source syntax and shard checks. Required inventory is now **323 native and 44 UI methods**, plus two opt-in diagnostics. The existing 28 original layout captures and eight supplemental beta capture sites remain distinct; capture sites alone do not prove retained images.

The target-lux editor now binds unfinished text to immutable locale values. A locale change blocks preview/Apply until a changed bounded edit, with visible guidance; switching back or an unchanged binding echo cannot reactivate it. Nine new regressions and an independent 45-assertion probe cover the original counterexample and boundary cases. The existing dirty-library UI workflow now makes and proves a real scene edit before testing save gating; all of its previous assertions and deadlines remain.

Published [run 45999974158](https://github.com/mirzotipi-wq/APP1/actions/runs/45999974158) at `134f9ad` passed core579/579 and104 tooling. Its [original core archive](validation/published-02-core-original.zip), [independent reconciliation](validation/published-02-core-reconciliation.json), and [actual twelve-image review](validation/published-02-core-visual-review.json) are retained. All five Apple UI build-for-testing steps passed, verifying the earlier expression repair. Runtime remains in progress at this snapshot; the native simulator job is queued. This run will be superseded by the current locale/library-test candidate, and partial outcomes must remain separate from acceptance.

The newly required recovery-fault CI step also passed on its actual Linux ext4 host. [Independent hosted reconciliation](validation/published-02-recovery-reconciliation.json) verifies40 pinned inputs, raw witnesses,19 interruption checks,18 EIO checks, seven filesystem receipts and distinct retry/reopen processes. Its earlier local missing-hook negative control is not mislabeled as hosted execution.

## Published second checkpoint: session safety and fresh Apple validation

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
