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

## Wave 4 checkpoint

Typed field commands are implemented and connected to every light scalar/position/optics, camera, subject, lens, preview, room and Plan mutation binding. StudioView now has a read-only scene projection. Full validation remains at arbitrary scene boundaries; typed payloads preserve UUID, SI, schema and optional representation. Session admission uses the current loaded/writable/idle generation. No feature-owner implementation was changed.

Fresh full Debug at `2f8be604d403d02a7a8c3273ce82cb4e3f969545` passed **413 tests, zero failures**, including 12 new typed-command methods and 12 actual StudioSession methods. All 79 App/NativeTests/UITests Swift files passed syntax parsing only. The 171-input source manifest, complete log and command receipt are in [evidence/wave04](evidence/wave04). The official Swift 6.0.3 archive signature and restored toolchain provenance are in [evidence/wave04-toolchain](evidence/wave04-toolchain). Native Apple compilation and runtime remain unverified.

## Next executable work

Wave 4 is complete: **40 actual fresh contexts across four waves**, with ten concrete roles in each. Exact canonical IDs and report hashes are in WORKER_LEDGER.json and wave-01 through wave-04.json. Root is excluded; acceptance schedulers count once. Followups and a rejected capacity spawn count zero.

1. Wave 5: enforce live presentation ownership and UUID revision admission, separating stable document identity from storage generation so first save can preserve the active feature. Retire matching callbacks synchronously; reject edit-away/undo-back results and repeated initial-load resets.
2. Waves 6–7: wire available reference/room/AR/arrangement/lux adapters and finish comparison/export/purchase navigation. Valid no-op acceptance is distinct from mutation; nested AR-room edits keep their owner transaction.
3. Reference currently clears session data before its Void callback. Composition can reject stale results but cannot guarantee retention of already-consumed drafts without the feature owner's acceptance interface. Arrangement/lux also dismiss after Void callbacks. Coordinate narrow interfaces without editing other owners' files.
4. Waves 8–10: package/generated target checks, independent lifecycle/state/undo challenge, fresh affected evidence and final lane 20 handoff. No Apple checks are passed without execution.

Latest inspected CI at published5c69: Project state45830511522 succeeded; iOS Prototype45830511439 remained queued. These are not results for the newer wave4 source. Main remains9e0e2ba with later changes reserved for lane20 integration. The baseline remainsf150f98 pending a published campaign BASE_SHA.

Source and reports use isolated durable workspace worktrees. Disposable test output uses separate /tmp build/cache directories. Only preserved work is cleaned, and only the assigned branch is pushed.
