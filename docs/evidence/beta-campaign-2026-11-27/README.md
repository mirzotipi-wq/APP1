# Beta engineering campaign — 27 November 2026

User request: launch 100 actual agents and bring APP1 to beta. Starting main was `664e404d1bddf6d19724760139592da30c799418`. Root integrates on `main`; three specialist slots run alongside root. The ledger records only actually created contexts, not planned workers. This packet is an active checkpoint, not a beta/release acceptance declaration.

## Integrated engineering checkpoint

26 actual workers have been created and 23 have completed their initial assignments. The [worker ledger](worker-ledger.json) records identities, input revisions, reports and integrated commits. Subsequent batches continue within the root-plus-three concurrency limit.

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

The baseline run is now terminal and failed. Its native job executed all 261 methods successfully, including three real Metal methods, but exceeded the outer 18-minute command deadline after XCTest completed. A reviewed candidate allows 24 minutes for that command and 100 minutes for the complete job, adds phase diagnostics, and preserves normal process exit, all assertions, exact accounting and artifact requirements. Library/reference UI passed eight of nine methods; archive-delete confirmation timed out waiting for a label. Room/precision, optics and studio/export shards passed. Current-source execution must not be inferred from these earlier results.

## Current limits

Later native/UI results remain source-specific and must be reconciled. Held-out human reference evaluation, physical AR/device trials, payment sandbox/product configuration, customer feedback, signing and owner distribution approval have not been supplied by this campaign. Code work proceeds independently; these checks are not marked passed or removed.
