# Wave 10 — final lane evidence and worker reconciliation

**Status: complete.** Ten actual contexts completed this wave: W91 and exactly nine fresh specialists, W92–W100. All ten campaign waves now contain **100 unique actual runtime IDs and 100 completed, existing primary reports**, with ten distinct roles per wave. [The aggregate ledger](../WORKER_LEDGER.md) and [machine-readable ledger](../WORKER_LEDGER.json) record every exact report hash. Root, followups and precreated trees are excluded.

## Source and scope

The immutable executable input is `342e3280e3eb077d55e122c8bfb88b4062b431ed`, tree `629fc14bf911700b924e4d9b2515ed3c9ddc794d`. SwiftPM CPU paths, portable tests and fixture scripts remain unchanged from `db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5`. App preview and native-test identities are separately bound in the JSON ledger. Current documentation was initially read at `92dc7a69c0032141ee49de0b96940fccab83a33e`; private source trees retain older documentation, so current receipts are read from the durable checkout.

W94 rewrote [HANDOFF.md](../HANDOFF.md) as sole writer. W97 finalized this lane's [owner routes](../OWNER_REQUESTS.md), preserving their historical sections. W91 owns aggregate worker normalization. No production, test, shared, GPU/cache or CI implementation was edited by this wave.

## Reconciled evidence

- W92 separates 25 actual Swift near-tangent cases from W22's 150 distinct translated-arithmetic windows and W30's 75 high-precision windows. The historical 11,708-invalid-pixel camera diagnostic becomes `invalidCamera` without a frame; all 40 held-out calls reject afterward.
- W93 independently verifies 31 CPU hashes and the distinct 12-image, six-parity and eight-required-precision inventories. Twenty-five supplemental probes are separate. Original raw standard RGBA/masks were not archived; final zero masks do not establish historical raw-mask equality.
- W95 confirms request-plus-ticket adoption and preserved pipeline/test bodies. The hosted test supplies synthetic active-sphere outputs and manual cancellation; actual GPU downgrade, lifecycle scheduling and the latest original before/fail execution remain unproved.
- W96 reconciles declared resource bounds, retained failures and cleanup. Exact token counters are unavailable; word/byte sizes are proxies. Repeated executor losses are preserved, without inventing a deduplicated outage census.
- W97 binds current 04 helper/engine identities and preserves open 02/04 tiny-Float policy and other owner actions. Requests are not acknowledgments.

Source-342 portable CI passed 391 Debug and 391 standard Release tests, plus six host parity and eight precision gates. Its Apple Debug build-for-testing passed, but the source-342 optics job then failed before any test method started: ten required methods remain unstarted after simulator/AX runner initialization failure. Native 165 execution remains pending while its separate job is in progress. Source-36's 164 native passes, its two library failures, and missing-artifact visual failures remain separate source-bound results. No global M02/M03, physical-device, manual VoiceOver or release acceptance is claimed.

## Independent review and preservation

W100 independently confirmed the actual identity/role/source graph, prior report hashes and retained evidence. It identified omitted camelCase recorded-hash/followup fields; W91 corrected the normalizer before finalization. Actual hashes matched throughout. Strict final normalization exits zero with 100 completed reports and no errors. W100's [standalone final verification](wave10-evidence/W100-final-ledger-verification.json) records its independent check of the frozen result without changing the primary report.

The [artifact inventory](wave10-artifacts.json) hashes this wave's primary reports, receipts and immutable reviewed document snapshots. Mutable HANDOFF/OWNER_REQUESTS, aggregate ledgers and the late W100 verification receipt are excluded from upstream artifact hashes to avoid circular dependencies and permit later CI-only status updates. The reviewed snapshot retains native165 execution pending and the current optics startup failure. The initial snapshot write failed with ENOSPC before writing bytes; its zero-byte artifact is preserved separately, and one bounded retry succeeded. This was storage failure, not an executor reset. Root alone integrates, preserves remotely and cleans up; this wave performed no cleanup.
