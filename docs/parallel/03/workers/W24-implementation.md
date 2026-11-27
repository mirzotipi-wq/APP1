# W24 — cached mesh normal/area precision review

- Runtime ID/task path: `/root/wave03/implementation` (no separate opaque ID exposed).
- Role: implementation, wave 03; source inspection.
- Exact input: `1cefc654630a86ab320e58283957f4e91d6cbce6`.
- Private detached tree: `/tmp/keyfill03-7f4b/workers/W24-implementation`.
- Read `AGENTS.md`, `agents/OPERATING_PROTOCOL.md`, `docs/acceptance/m02-m03-code.md`, and `docs/parallel/03/WORKER_PROTOCOL.md`.

## Findings

No concrete numerical regression found for the shipped fixed mesh.

1. **Finite safety depends on fixed geometry.** The private constructor receives bounded submeter profile/ring coordinates, excluding overflow. Its squared-area guard gives a positive divisor above `1e-12` and cutoff above `1e-26`. The guard alone rejects NaN but accepts infinity; the previous `headUnit` rejected infinite length. Arbitrary large geometry would need an explicit finite check or robust normalization. This is a generalization limitation, not a shipped failure.
2. **Arithmetic/winding are preserved.** Cached `(b-a) × (c-a)` divided by `sqrt(headDot(areaVector, areaVector))` uses the same component operations and immutable edges as previous hit-time `headUnit(headCross(edge1, edge2))`. Vertex order, smooth-normal fallback and outward face selection are unchanged. This establishes source equivalence, not measured cross-build bitwise identity.
3. **Scaling gives the angular criterion.** `det = -direction · areaVector`; for unit directions the new guard is mathematically `abs(direction · geometricNormal) > 1e-14`. Camera/shadow callers normalize their rays; mesh entry points do not enforce that precondition. Area scaling removes triangle-size dependence but does not prove robustness against cancellation arbitrarily near the threshold.
4. **Hit/occlusion share the predicate.** Both call `intersection`; barycentric tolerance `1e-10`, half-open `[minimum, maximum)`, BVH traversal, tie tolerance, true-minimum distance retention and front-facing tie selection are unchanged. `PortraitStudy.swift` is unchanged against the parent revision.

## Actual checks and limits

Ran `pwd`, `git rev-parse HEAD`, status/log/detached-HEAD checks, `rg --files`, required-file reads, `git diff HEAD^ HEAD --stat`, focused mesh diff, parent-source `git show`, mesh/test reads, targeted caller `sed`/`rg`, and `git diff --exit-code HEAD^ HEAD -- Sources/LightingCore/PortraitStudy.swift`. Two initial `rg` calls used nonexistent filenames (exit 2), then corrected to `PortraitStudy.swift`.

No Swift/Python execution, builds, full geometry/ray enumeration, source edits or commits. W22's 5,248-triangle/50-ray probe and root's 380 Debug/380 Release results are external evidence. Final private-tree `git status --porcelain=v1` was empty; HEAD remained exact. Report is the sole deliverable. Budgets were targets, not measured counters.
