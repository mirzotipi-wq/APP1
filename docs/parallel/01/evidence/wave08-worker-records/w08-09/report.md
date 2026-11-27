# W08-09 — platform evidence review

Read-only review completed at fixed source `8b18366`; no builds or repository edits by this worker.

Root's corrected source passes **431 Debug and 431 per-file Release cases**, independently reconciled with unique ordered start/pass pairs, zero failures/skips, and matching log hashes. These rebuild affected sources in existing scratch directories. Default Release remains a separate retained signal-9 failure at `7bdea15`; the missing-time setup executed no Swift.

The prior Apple failures were concrete: jobs `140019833234` and `140019833325` rejected conditional Observation annotations at StudioSession lines 46/50. Root's full-declaration correction exactly matches the before/after probe: four errors/exit 1 became exit 0. That Linux macro probe does not establish Apple acceptance.

All 179 fixed manifest hashes match Git. StudioSession is the sole changed manifest/portable input; the earlier 94-input equality and CI passes belong to pre-fix source. At 16:38:39 UTC, `7bdea15` core job `140036374958` passed 431 per configuration; six Apple jobs remained queued. Prior overall cancellation preserves individual failures.

Package dump/describe receipts pass; native declarations select 189 unit, 36 required UI and two diagnostic methods. Apple generation/typecheck/runtime remain unverified. Three Void producers still consume rejected drafts. Startup check/next exited 0; M03 remains active. Worker tree stays clean; source.patch is empty. Detailed commands, hashes, job timestamps and limits are in receipt.json.
