# W04 exact patch review

canonicalID: `/root/w04_acceptance/concurrency` (same context)

Candidate: `b35671f971be2e2dd4d05d7531486a3de4ce25c2`  
Verified parent: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`  
Verified patch SHA256: `6b6165acef74c09df9ba709ece84e5eb390bc7123d83c825b69cd686390e0ec9`

**Disposition: no source blocker found; suitable for integration and native validation.** Exactly two files change: one conditional assignment with explanation in `SpatialPreview.swift`, and 137 lines containing four new native tests.

The conditional publishes mode before availability for valid scenes, preserving initial empty-orbit interaction. Invalid scenes still publish unavailable content and disable interaction while retaining the last applied mode. Camera → invalid orbit → valid orbit therefore keeps its Fit pending; orbit → invalid orbit → orbit retains the user's pose. Existing request accounting, callback replacement and transaction lifetime remain unchanged.

| Regression | Adequacy in source |
|---|---|
| Authored camera recovery | Establishes 85 mm camera state, invalidates, then requires orbit position/target, 48-degree FOV, clipping, visibility and interaction with Fit0 unchanged. |
| Undefined camera recovery | Establishes nil POV, then requires recovered orbit state. |
| Same-mode invalid recovery | Requires the same user camera and target, challenging unconditional refitting. |
| Initial empty orbit | Requires interaction and fitted state without UUID cancellation or control-mode refresh. |

Swift source appears consistent with existing tests: main-actor XCTest isolation, SceneKit imports, accessible helpers, Float-ULP tolerances, transaction flush and deferred dismantling. Invalid-fixture indexing is confined to nonempty portrait fixtures. Expected geometry reuses the orbit helper appropriately for this lifecycle test; numerical geometry coverage remains separate.

Actual checks: pinned `git show` full two-file diff/stat/parent; `git diff --check 9725fb1177a5c7afbdf798ffd627e65e604c75b1 b35671f971be2e2dd4d05d7531486a3de4ce25c2` exited 0; Python SHA256 verification and declaration scan found four methods. Candidate source hashes:

- SpatialPreview: `f7d90394a449c859a0fdebd98e7b11b0a5dad942d971d6a1d3a24474c9f0a585`
- New tests: `fda09865e8e15476789f5ae20a3770002d88f5003677335ead59f11cdb9ebd51`

No builds, native execution, source edits or commits by this reviewer. Test adequacy and Swift plausibility are source conclusions, not executed passes. Prior report/model remain pinned to the original input.
