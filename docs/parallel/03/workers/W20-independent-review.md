# W20 — Independent geometry-test review

Runtime/task: `/root/wave02/independent_review`. Input: `9c172d3e2d0c3f18636d84e8f31150236c63cbaa`.
Private worktree: `/tmp/keyfill03-7f4b/workers/W20-independent-review`, recreated after interruption; clean. Output: `/tmp/keyfill03-7f4b/builds/W20-independent-review/review-checks.json`.
Reviewed W12 file SHA-256: `6024e0cbfb315c68bb3f761fc725a90656d5ddffe1df16db9762081527d85aef`, exactly matching its recovered committed file. Original W12 commit: `d281faae891e38184bc96adb0d794656bb702592`.

## Decision

No blocking test-design issue found; accept the patch for root's runtime validation. This is an independent source/numeric review, not a test-execution pass.

The oracle shares prescribed vertices/topology but uses unaccelerated plane intersection and projected-area containment. It does not derive expected distances from the BVH or production triangle query. New cases require all barycentric weights strictly between 0.30 and 0.37 and exactly one full-segment oracle candidate, so the existing −1e-10 edge allowance cannot manufacture the intended interior hit. Three regular faces provide scale controls alongside three polar faces.

The unchanged 1e-8 m distance tolerance is 10 nm. For the preserved witness, the nearer fixed miss-window boundary is 9.9979073163 μm away: over 999 tolerances. Its normalized incidence is about one million times the oracle's parallel cutoff. The recorded direction has unit length within the existing 1e-12 requirement. Before/through/after classifications therefore do not depend on marginal endpoint rounding.

Existing exact half-open tests remain unchanged. Their production-returned distance is used only to test floating-point endpoint semantics; independent brackets test geometric location. The helper still checks both nearest hit and occlusion even when its Boolean return is false.

Limit: shared vertex generation means this oracle does not independently validate the authored surface shape. Its useful scope is intersection/traversal/finite visibility, as intended.

## Actual checks

Required directives and baseline/test/witness files read; Git status/HEAD/log and Python diff/SHA-256 checked; small Python arithmetic checks saved above; agent_cycle check/next exited 0 (structure/M03 queue only). No source edit, commit, Swift build/test/render, native/Metal run, candidate implementation inspection or cleanup.
