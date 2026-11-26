# Wave03 synthesis — stable entities and incremental updates

Ten actual fresh contexts completed: `/root/w03_acceptance` plus nine named specialists. All canonical IDs, pinned inputs, tasks, reports, commits and dispositions are recorded in `ledger.json`. No builds, native tests, profiling or toolchain recreation ran in this wave.

## Outcome

No blocking product or test defect was identified by the focused source reviews. Continuing UUIDs retain live SceneKit fixture/source/stand/indicator nodes and RealityKit lamp entities. Kind and rectangle-dimension edits may replace SceneKit geometry; material/component updates may allocate. Invalid input, deletion and reintroduction intentionally reset lamp identity. Retained stale hit objects cannot resolve through current ownership maps. Selection cues and accessible equipment-list alternatives remain supported by source.

## Concrete contribution

Worker commit `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` adds only `NativeTests/SpatialEntityUpdateTests.swift`: three tests, 217 lines, exercising kind changes, individual rectangle dimension changes versus pose/output edits, and stand threshold detach/reattach. Tests assert live node/resource identities, geometry replacement, authored front plane and basis, selected-outline ownership, lookup rejection and bounded node counts. Independent and platform reviewers approve by source; no API/discovery blocker was found. Root reports cherry-pick integration as `956a3b1`.

Exact test source, patch, commit metadata and writer report are preserved under `implementation/`; the ledger includes source and patch digests. Tests are authored and unrun.

## Evidence boundary and remaining gaps

Root reports historical CI `45817222487` succeeded at source `68c83`: 171 tests, zero failures/skips, including 25 spatial tests (8 pure, 9 interaction, 3 fit, 5 geometry). Two original SceneKit ordinary/crowded captures were downloaded and viewed by root. These results do not verify pinned `35283bed`, worker `44550b6` or integrated `956a3b1`.

Targeted coverage still absent: direct RealityKit graph mutation tests; identical-scene callback A→B→nil replacement; valid→coincident→recovered aim; complete source/stand/indicator lifetime reset assertions. Source-node identity must not be generalized to `SCNLight`, which is recreated after degenerate aim. A tiny Double/Float stand-threshold mismatch can register a detached stand internally, but current parent-ownership checks reject its hit, so no stale-selection defect is demonstrated.

Logical main-actor atomicity and bounded application topology are source-supported; frame atomicity, heap/GPU lifetime, measured performance and device/VoiceOver behavior remain unverified. Hand off for exact integrated native execution and the next planned wave; no additional audit is required for this wave.
