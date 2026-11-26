# W01 — Acceptance inspection

Runtime ID/task: `/root/wave01` (canonical name is the exposed ID). Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Worktree: `/tmp/keyfill03-7f4b/workers/W01-acceptance`. Acceptance assignment and wave coordination complete. No source edits/commit.

## Frozen gates

`docs/acceptance/m02-m03-code.md` governs; preserve historical failures. Photometry: <=1% point and <=5% area-reference errors; existing analytic/invalid/range/transform/color/invariant tests pass Debug and Release.

Rendering: twelve actual images plus scene JSONs, zero unsupported pixels and visual review: `soft`, `hard`, `warm`, `bust-soft`, `bust-hard`, `bust-side`, `key-only-hard`, `fill-only-soft`, `bust-rim-only`, `bust-roll-90`, `exposure-minus-two`, `white-balance-3200` (`scripts/render-study-fixtures.swift:164–231`). Six parity cases: exact count/mask, mean RGB error <=1, fraction >4 <=0.005. Eight precision cases: max error <=1. Preserve geometry/visibility/cancellation/routing regressions.

Performance: cancellation within eight pixel evaluations after a false poll; no cancelled/failed publication/cache; <=4 frames, <=256 KiB RGBA +64 KiB masks, mannequin width <=144, existing input/sample bounds. Optimized benchmark: warm-up +>=7 samples for eight frame/four visibility workloads; twelve observed cancellation probes; repeat bytes and supported masks. Host timing/shared math cannot establish physical performance/actual Metal.

Preview M03 obligations: meaningful state, non-color cues, largest-size reachability and preserved edits.

## Coverage findings

1. Fixture script checks dimensions/opaque RGBA/masks (`:143–160`) and only nonzero changed pixels for comparisons (`:88–98`); actual geometry/shadow review remains essential.
2. `UITests/ReferenceComparisonUITests.swift:4–29` checks image existence/reopened empty-photo state. No focused hosted superseded-frame regression appeared in native/UI inventory. Engine tests do not establish SwiftUI adoption.
3. Near-field parity intentionally contains unsupported pixels; keep it separate from the twelve supported-image cases.

## Actual checks

With assigned TMPDIR, `python3 scripts/agent_cycle.py check` reported valid structure, not test truth; `next` selected active M03. Prescribed documents/fixture/test source read with `cat`, `rg`, `nl`. Final `git rev-parse HEAD`/`git status --porcelain` checks verified all ten private worktrees clean at the input SHA. No Swift build/test/render/benchmark, Metal or UI run; no acceptance promoted.
