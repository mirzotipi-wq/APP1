# Renderer correctness and guided assumptions — checkpoint 3

Source `5ac2d1e2e8e8762c84ababa93e1982ec914fbef8`, exact tree `4f2d2ef3b496891fbed3ec89463e26c36111acd9`, integrated and remotely read back on main.

## Verification

**201/201 Debug and 201/201 Release**, zero failures, in the isolated exact-index snapshot using Swift 6.4.3 on Debian 13 x86_64. **24/24 Python** evidence/shard tests passed; real six-class shard coverage, state validation and native Swift syntax parsing passed. Native SDK/GPU/UI execution is not implied. [Current workflow 45354563409](https://github.com/mirzotipi-wq/APP1/actions/runs/45354563409) was in progress at observation. Earlier editable-copy source e45a1c8 core job 138304054517 completed successfully; native jobs were queued before the newer run superseded that grouped workflow.

Commands: `swift test --jobs 2`, `swift test -c release --jobs 2`, Python unittest discover, `scripts/agent_cycle.py check`, `scripts/native_test_shards.py check`, `swiftc -frontend -parse App/*.swift NativeTests/*.swift UITests/*.swift`. Full raw test logs below; host clock difference from connector UTC remains preserved.

## Correctness and cancellation

A new independent plane/projected-area oracle reconstructs 5248 triangles and checks 300 deterministic rays, including exterior views, seams/poles/edges, interior exits and finite half-open segments. It exposed two silhouette ties where a back-facing incident triangle won a distance comparison differing by approximately 1e-16 m. A 24×16 actual render reproduced a magenta unsupported pixel at (8,13). The correction keeps the actual nearest distance and allows an outward front-facing normal for a numerical tie bounded by max(1e-12 m, 8 ulps); exact segment endpoints remain exclusive. The regression now yields a black valid pixel and zero unsupported pixels. Six new mesh tests plus existing portrait tests pass. This validates prescribed geometry intersection, not calibrated portrait shape or skin.

Four independent photometry tests add arbitrary coordinate changes, geometric similarity, off-normal BRDF reciprocity, and scene yaw/translation consistency. Existing analytic and independent Simpson fixtures remain intact.

First-use Metal parity validation now checks cancellation between fixtures and during CPU work. Cancellation leaves the engine unchecked for a later real retry rather than permanently selecting CPU. Actual backend failures retain CPU fallback. Two new native tests cover initial-validation cancellation/retry and actual Task cancellation; native execution pending.

## Measured performance, including rejected change

[Baseline measurement packet](render-benchmark.md) records exact commands, seven samples per workload, raw JSON and source hashes. On the shared Linux CPU, the 144×96 mannequin with three area lights had a 140.659 ms median in that baseline; receiver visibility added 23.704 ms per 1000 evaluations compared with the same disabled-visibility control. These are CPU diagnostic measurements, not iPhone/GPU/FPS results.

An attempted reciprocal-direction cache passed 17/17 targeted tests in both configurations and 8/8 byte-identical complete images, but repeated whole-frame timings did not show a stable improvement. The unchanged control also varied substantially. [The negative experiment](bvh-optimization.md) preserves every canonical sample and decision. The optimization was reverted exactly to the independently verified silhouette-fix source. No speedup is claimed or retained.

## Honest guided alternatives

GuidedRigBasis preserves the exact entered categorical cues and distinguishes observations from unknown defaults. Distance, camera-relative angles, 400 lx and 5600 K are explicitly chosen values. The UI shows the selected candidate's basis, with a native far/near/apply/undo regression awaiting execution. Four new portable cases cover 108 input combinations / 216 candidates, camera-relative geometry, actual lux and unknown-vs-explicit-absence semantics. There is no confidence percentage, ranked inverse inference, or measured exposure claim.

## Remaining work

M01 remains active with current native build and persistence smoke unverified. Room measurement notes and asymmetric EXIF/alpha regressions are ready for the next integration; descriptor-based shared selected-file reading and adversarial import review are active. Physical-device, calibrated reference, AR, commerce, customer and release approval gates remain outstanding.

## Raw exact-tree logs

- `cycle3-debug.log` SHA-256 `e225b0c433432c147e6fa922596db492b3f1a40e63a7731ba135e46ff87b7305`.
- `cycle3-release.log` SHA-256 `ade1c4f2ea35c9602b26b5df3ec6c5c979bd34165c75eb66621d440a212a35dd`.
