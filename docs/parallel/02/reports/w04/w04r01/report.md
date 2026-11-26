# W04 R01 — rectangle acceptance

Agent: `/root/w04r01`. Worktree HEAD `47de6afe6afe24a7822f4276950f70bd3db9f57d`; frozen production/probe snapshot v1 `1b286885cb803ba17e159713651515ab119e17f1` (HEAD difference is documentation only). **Second-executor provenance:** first execution succeeded, then `/tmp` was erased. These raw artifacts are from a real rerun after root rebuilt v1 with Swift 6.0.3 from `047803c` (root verified Sources diff versus production is empty). No raw results were fabricated or reconstructed.

**Accepted within this bounded check.** The tiny-output branch terminates after at most one recursive call: positive intensity below `Double.leastNormalMagnitude * 1024` (`2.2784756311113742e-305`) constructs an otherwise identical unit-intensity emitter. Intensity 1 cannot re-enter the branch. Invalid separation and zero/back emission return before recursion.

Swift evaluated full and half-clipped 5 cm square faces at 5 cm depth with minimum subnormal, minimum normal, threshold.nextDown and threshold intensity. All eight outputs were finite and positive; all six tiny-branch results exactly matched `unitLux * intensity`. Minimum-subnormal outputs were `1.487e-321` lx (full) and `1.73e-322` lx (partial). This checks termination/scaling, not independent quadrature accuracy.

The source suffix beginning `let right = emitter.right.vector, up = emitter.up.vector` is byte-identical to `f75aa27^`: clipping, triangle fan, Gaussian u/v loops, midpoint j/i loops, normalization and accumulation order remain. SHA256: `1a787215d25aa4a57d757b027f4f2711d835452baabcaf4e5f3d9aec2561c071`. Normal construction intentionally changed in `58b3ca4`; no bitwise all-angle equivalence claim follows.

Commands: `git show f75aa27 -- Sources/LightingCore/SurfacePhotometry.swift`; `git show 58b3ca4 -- Sources/LightingCore/SurfacePhotometry.swift`; Python equality of current/baseline integration suffix; `python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r01 /tmp/keyfill02-r2-workers/w04r01/private-output/probe.swift v1` (exit 0, second executor).

Evidence: `probe.swift`, `compile.log`, `probe.log`, `source-order.json`. No production edits, package build, calibration/device claim or weakened 1% point / 5% area gates.
