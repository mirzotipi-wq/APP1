# W03 concurrency

- canonicalID: `/root/w03_acceptance/concurrency`
- inputSHA: `35283bed09c609be424df80f36b42391aec19f74`
- Actual checks: read-only pinned `git show` of required protocol/plan, architecture/design, viewport implementations, Scene validation and native test declarations; numbered inspection plus `rg` for actor/transaction/asynchronous constructs. No build, test execution, toolchain work, source edits or child delegation.

## Findings

**No concrete application-level interleaving defect found.** SpatialPreview/coordinator are main-actor isolated; update/helper paths have no await, Task or dispatch (`App/SpatialPreview.swift:8`, `:27`). Callback replacement precedes the no-op return (`:207`). Availability and current ownership gate selection (`:137`, `:150`). Re-enabling availability before reconstruction introduces no actor suspension.

**Transaction exits balance.** Update begins a transaction with zero duration/disabled actions and deferred commit (`:219`), including the invalid-scene early return (`:235`). Incremental geometry, visibility, outlines and camera setup are within that scope. Layout projection uses the same begin/defer pattern (`:526`).

**Recovery is coherent in source.** Invalid scenes hide content, disable interaction/stop inertia, clear callback/equipment maps and reset lastScene (`:223`, `:230`, `:95`). Retained base nodes stay hidden; recovery rebuilds lamps and rejects old fixture identities. Camera-unavailable valid scenes retain equipment while hiding content/clearing point-of-view; corrected framing reinstates pose/lens (`:251`, `:260`). Degenerate aimed lights retain markers but remove their light component; optics/subject changes force reevaluation (`:374`, `:411`).

**RealityKit comparison:** synchronous main-actor invalidation disables anchor and clears roots/cache (`App/StudioEntityGraph.swift:69`); surface validates currentScene before graph update (`App/RealityStudioPreview.swift:189`). No asynchronous interleaving found.

## Outcome

Source supports logical main-actor atomicity, **not demonstrated frame atomicity** across renderer, view properties and UIKit overlays. Invalid identity/camera-recovery tests exist (`NativeTests/SpatialInteractionTests.swift:67`, `:107`) but inspect final state; none ran here. Historical passes/CI do not establish execution at this SHA. Remaining native evidence: consecutive rendered frames during valid/invalid/recovered transitions under an enclosing animation. No source patch requested.
