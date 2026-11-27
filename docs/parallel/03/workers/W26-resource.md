# W26-resource — cached triangle storage

Runtime/task: `/root/wave03/resource`. Input: `1cefc654630a86ab320e58283957f4e91d6cbce6`.
Tree: `890c0472d1f56ab36f6c17110c1f759937ee1211`.
Private worktree: `/tmp/keyfill03-7f4b/workers/W26-resource`; clean detached HEAD verified before executor loss.
Host: Linux 6.18.57 x86_64; Python 3.12.14.

## Findings

`PortraitHeadMesh.Triangle` adds `SIMD3<Double> geometricNormal` and `Double twiceArea`: **32 bytes of scalar payload per triangle**. W22's independently supplied 5,248 retained triangles imply **167,936 bytes / 164 KiB** additional logical payload. The unchanged reservation request of 5,376 slots corresponds to **172,032 bytes / 168 KiB** scalar-equivalent payload.

These are **not measured Swift allocation sizes**. SIMD padding, aggregate alignment/stride, actual Array capacity and allocator overhead are unmeasured. For equal actual capacity C and stride increase d, backing-store growth is C×d; neither C nor d was established.

Parent-source comparison shows unchanged mesh generation, rejection predicate and BVH construction. Executed JavaScript arithmetic for the existing split recurrence, using W22's count, yields **2,047 nodes, 1,024 leaves, maximum depth 10** with root depth zero. No geometry reproduction was performed.

`static let standard`, referenced by `PortraitGeometry.head`, retains one immutable shared mesh. Added storage persists after first initialization. Constructor normalization and larger existing sorting temporaries occur during initialization. No new per-frame triangle/BVH arrays appear.

## Bounds preserved by source comparison

| Bound | Value |
|---|---|
| Portrait image | 144×96; 55,296 RGBA + 13,824 mask bytes |
| Sphere interactive/reference | 192×128 / 96×64; 120 / 30 KiB combined payload |
| Lighting | ≤12 lights; ≤768 interactive / 12,288 reference samples; ≤12 area guards |
| Completed-frame cache | ≤4 frames; 262,144 RGBA + 65,536 mask bytes |
| Cancellation | Existing eight-pixel polling interval |

Portrait, cache, engine and validation source have no parent diff. ReferenceStudy changes only setup cancellation plumbing; width/sample/pixel limits remain intact. Mesh storage is separate from frame-cache payload budgets. **No resource gate violation identified; no runtime gate pass claimed.**

## Actual checks and interruption

Executed protocol reads, `git rev-parse`, status/show/diff, bounded `rg`/`sed`/`nl` reads, host/version checks, and code-mode JavaScript arithmetic. No Swift builds/tests, MemoryLayout execution, RSS/timing measurement, source edit or commit. Root's 380 Debug/380 Release results remain external.

The attempted Python probe/report-writing process was rejected before creation: executor transport disconnected and recovery reported an executor-key change. No Python probe execution or file was confirmed. W26 returned these findings in its final message. W21 preserved this report after access returned and recreated the vanished private worktree at the same input; these later actions are the coordinator's, not W26's executions.
