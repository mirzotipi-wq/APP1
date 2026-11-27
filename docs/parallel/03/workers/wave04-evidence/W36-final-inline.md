## W36 resource — pinned-source proof; candidate check blocked

**Identity:** runtime ID and canonical path `/root/wave04/resource`.
**Input:** `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`.
**Private tree:** `/tmp/keyfill03-7f4b/workers/W36-resource` — inaccessible.
**Candidate SHA-256 supplied:** `f406fb496129d82f81dc429cc3bb002fc1b168b5ed771edcff8e449d5e2757cb`; **not independently observed**.

Two execution attempts failed with disconnected transport/recovery timeout; the environment then reported unavailable. Mandatory directives and relevant source were successfully read through GitHub at the immutable input revision. Actual JavaScript arithmetic and source checks ran.

### Storage and call graph

`PortraitHeadMesh.swift` declares `static let standard`, a private initializer, and private `let` triangle/node arrays. `PortraitGeometry` holds that mesh in `private static let head`; each frame’s geometry initializer assigns only its center. The inspected path cannot construct a new mesh per frame or mutate its arrays. Shared backing storage follows Swift Array value semantics; pointer identity and RSS were not measured.

`PortraitStudyRenderer.render` contains one primary `geometry.hit` call per pixel. That method performs at most one head BVH traversal, plus fixed panel/bound checks and six analytic parts. Lighting separately invokes bounded shadow traversals through `geometry.occludes`.

### Exact recurrence and conservative bounds

For the supplied **5,248 triangles**, the inspected builder splits at integer midpoint whenever count exceeds eight:

| Quantity | Result |
|---|---:|
| Total nodes / internal nodes | 2,047 / 1,023 |
| Leaves | 1,024 |
| Leaf distribution | 896 × 5; 128 × 6 triangles |
| Maximum depth | 10 edges / 11 levels |
| Maximum per-ray node / triangle tests | 2,047 / 5,248 |
| Maximum image | 144 × 96 = 13,824 pixels |
| Primary node tests per frame | 28,297,728 |
| Primary triangle tests per frame | 72,548,352 |

Each traversal visits a node at most once; each AABB performs at most three axis tests. Construction is fixed: 2,752 vertex entries, 5,376 triangle candidates, 2,047 builder calls and 57,728 bounds-loop iterations under the stated triangle count.

`Scene.validated()` limits lights to twelve. Interactive sampling uses 8 × 8 cells; clipping preserves that maximum. Consequently, each shaded pixel permits at most **768 shadow rays**, or **769 traversals including its primary ray**.

Cancellation runs before every pixel and polls every eight evaluations. A JavaScript counter model confirmed eight evaluations after an immediately preceding false poll. The conservative intervening bound is 12,593,144 node tests and 32,285,696 triangle tests. This is a work bound, **not a wall-time guarantee**.

### Camera correction and limitations

Replacing the existing call with `minimum: 0` and checking the returned first depth afterward requires one traversal and constant additional arithmetic **if the supplied patch description is complete**. Lowering the minimum can change pruning and actual work within that traversal; unchanged timing cannot be inferred. The candidate itself and W32 receipt were unavailable, so candidate-specific verification remains open.

No Swift test, build, benchmark, RSS, native execution or physical-device check ran. Report and raw evidence could not be persisted; raw JSON was delivered to the coordinator for preservation at the assigned W36 paths. No source, commits or remote refs changed.
