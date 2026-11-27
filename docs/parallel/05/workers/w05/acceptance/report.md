# Wave 05 — acceptance contract

Input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`; canonical worker `/root/w05_acceptance`. Source review only; no native execution.

## Scoped check and acceptance

Reviewed pinned `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, lane 05 PLAN/CHECKPOINT/OWNER_REQUESTS/RECOVERY, and the selection/update paths in the three viewport adapters. The wave accepts the following behavior without changing the existing product thresholds:

1. A fixture, visible descendant/outline, or enabled stand resolves only through a registered live object identity under the current content/anchor. Hidden/disabled descendants and detached/deleted objects resolve nil, including after reintroduction of the same UUID.
2. Invalid content removes equipment registrations and detaches equipment roots. Valid recovery allocates replacement equipment; retained old roots and descendants never regain selection authority.
3. An identical-scene update replaces callback A with B before returning early; changing B to nil clears callback authority without rebuilding live equipment or changing the useful viewpoint. Callback invocation in a unit test is not gesture execution.
4. Actual tap delivery requires current interaction/lifecycle/window/mode eligibility and current-scene membership. A direct resolver may still identify retained live geometry while interaction is disabled; that does not establish delivery.
5. Project replacement with overlapping UUIDs is a composition identity boundary. Ordinary same-UUID scene edits preserve live geometry. Adapter-local evidence cannot prove the parent generation guard or workspace replacement behavior at runtime.

## Source findings and evidence boundary

`SpatialPreview.updateView` refreshes `onSelect` at line 207 before its line 213 early return. `lightID(for:)` at lines 150–162 checks current availability, hidden state, root registration, direct content parent and live UUID membership. Its action at lines 141–145 performs a fresh hit and invokes the current callback after admission. `StudioEntityGraph.lightID(for:)` at lines 127–136 checks enabled ancestors, registered root identity and direct anchor parent; RealityKit delivery additionally checks current-scene UUID membership.

Existing native tests change scene values while exercising callback replacement, and deletion/recovery tests retain only the old fixture. The writer is scoped to at most three new native methods covering unchanged-scene callback transitions and fuller retained-node lifetime. Acceptance of that patch requires an independent exact-diff review, then root-owned native execution. Source evidence supports the contract; current native, RealityKit device, VoiceOver and performance acceptance remain unobserved. Historical 171/25-spatial passing evidence at `68c83` is not a test result for this input.

