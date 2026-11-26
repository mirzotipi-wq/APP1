# Lane 01 handoff — waves 1–3 complete

## Current checkpoint

Exactly **30 actual fresh worker contexts** have completed three waves of ten. The next wave separates typed mutation commands from rendering. Seven waves / 70 fresh contexts remain. See [WORKER_LEDGER.json](WORKER_LEDGER.json), [wave-03.json](wave-03.json), earlier wave ledgers and original reports for IDs, frozen inputs, provenance and outcomes. Followups and one capacity-rejected spawn received no extra credit.

Work is confined to `finish/01-architecture-composition`. Lane 19 owns CI; lane 20 owns canonical state and final integration. Campaign baseline remains `f150f98e35dd735927075aac4d2f8b02295c6a67` pending lane 20's published BASE_SHA. Inspected main remains `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`; its later native-test correction is preserved for integration. No canonical status, CI or other feature-owner implementation was changed.

## Implemented composition

- `StudioEditorState` owns validated scene, stable selection, revision identity and bounded history. Invalid candidates are atomic. A no-reset receipt cannot replace scene content beneath retained redo or an open gesture.
- `StudioSession` owns each window's editor and project/library reconciliation. It reserves operations before closing edits, stages editor and operation adoption before publishing either, and retains asynchronous work until its receipt settles. Existing ProjectStore and ProjectLibraryOperation source remain unchanged.
- Cumulative Plan gestures now belong to the session. The frozen origin and scale survive rejected stale Save callbacks; accepted reservations finish the group. A delayed end from an old generation cannot end a newer gesture. StudioView renders the session's gesture state.
- Both numeric editing phases pass through generation admission. A stale end captured before first save cannot close a newer same-control transaction; the View forwarding correction is statically reviewed, with the session guard/grouping exercised in actual tests.
- Ordinary numeric-control identity now follows `workspaceResetID`, retaining identity across first save, metadata changes and undo. Intentional document switch/reload rotates it. Callback generation checks remain separate. Actual native focus/caret preservation is still unverified.
- `StudioFeatureContext` / `StudioFeatureSession` define live owner, generation and revision admission. They are **not yet wired into native feature routes**; existing equality-based route guards remain pending work.
- The internal StudioComposition package target compiles the actual storage adapters and session for portable orchestration tests. Native Observation remains enabled on Darwin; Linux test results do not verify SwiftUI observation.

[INTERFACES.md](INTERFACES.md) contains scene invariants, examples and the feature integration rules.

## Actual verification

The original environment disappeared after local implementation/test commits. Code and reports were recovered through GitHub, then a fresh environment returned. Published recovery checkpoint `7b37b79f5d399942b9dd226667fcd67f2ba705f6` was fetched and its commit/tree plus all six recorded source hashes verified. The original outage evidence remains under [evidence/recovery](evidence/recovery).

The latest full fresh check is at restored source `6fe2cfab49f1b087553f65341f4471f786b309f9`: **400 Debug tests passed**, including 11 session and six Plan methods. Its complete log, command receipt, native syntax receipt and 169-input source manifest are under [evidence/wave03-restored](evidence/wave03-restored). The acceptance reviewer independently verified all 169 hashes and actual session method results. The real two-window conflict/recovery test passed.

The temporary filesystem reset again during wave 3. Exact worker test source and report variants were recovered and verified. Code, reports and new logs now live in a persistent sparse workspace checkout. Earlier 10-test and 16-test wave 3 runs passed, but their raw logs were lost; the new full run provides retained current-source evidence. See [recovery provenance](evidence/wave03-recovery/manager-ledger-original.json).

Earlier restored-environment evidence remains under [evidence/revalidated](evidence/revalidated):

| Source / check | Actual outcome |
|---|---|
| Local `a98be93`, full Swift 6.0.3 Linux Debug | 392 tests passed; 0 failures |
| Local `66aec8b`, changed control-identity session suite | 9 tests passed; 0 failures |
| Local `66aec8b`, all App/NativeTests/UITests Swift syntax | Passed parsing only |
| Apple SDK compilation, native UI/Observation, AR/StoreKit | Unverified |

The full run preceded the small control-identity change; the affected nine session tests were rerun afterward. Do not relabel that as one full run at the newer source. Exact commands, source hashes, complete new logs and compiler provenance are retained. Pre-outage 383-test and separate 8-test outcomes are historical and separately described; their lost raw logs are not presented as recovered.

Latest inspected recovery-source CI: iOS Prototype run `45822436205` queued; Project state run `45822436005` succeeded at `7b37b79`. Structural checks are not runtime acceptance. Earlier main UI failures remain documented in CAMPAIGN.md.

## Next executable work

1. Wave 3 is complete. Preserve its source-specific evidence and continue with exactly ten fresh wave 4 contexts.
2. Wave 4: add closed typed field commands to avoid revalidating unchanged imported names on every scalar update. Keep full validation for external candidates/import/adoption and preserve optional representation, UUID, SI and history semantics.
3. Wave 5: enforce live presentation ownership and UUID revision admission; retire matching callbacks synchronously and reject edit-away/undo-back results.
4. Waves 6–7: wire available reference/room/AR/arrangement/lux adapters and complete comparison/export/purchase navigation. Preserve the difference between accepted no-op and actual mutation. Retain nested AR-room undo as one transaction.
5. The current ReferenceComparisonView clears session data before a Void Apply callback. Composition can reject a stale scene result, but cannot promise preservation of that already-consumed reference session without an owner-provided acceptance/draft interface. Coordinate this explicitly; do not claim the gap is fixed by core receipt tests.
6. Waves 8–10: check package/generated targets, challenge duplicate state/lifecycle/undo, revalidate changed evidence and deliver the final precise lane 20 handoff. Native checks unavailable on Linux remain unverified.

Only preserved work may be cleaned. Current checkout is `/workspace/scratch/e08d5190f17c/keyfill-01`; worker source trees and reports use isolated durable sibling directories. Only disposable build/cache output is placed under `/tmp`. A shared read-only Swift 6.0.3 toolchain is used through the lane alias after verifying startup/dependencies and hashes; the archive for 6.2.1 was verified but not extracted because of capacity limits.
