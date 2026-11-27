# W36 — immutable mesh and bounded work

Runtime/canonical ID: /root/wave04/resource. Input: ace9f2eba068bc31dd04bb2f1e2028af315d6bdb. Assigned private tree: /tmp/keyfill03-7f4b/workers/W36-resource.

**Preservation:** coordinator summary of the complete returned report and raw JSON, preserved in wave04-evidence/W36-final-inline.md and W36-resource-model.json. No local report was originally written; both exec attempts failed before source reading.

Immutable GitHub directive/source reads and actual JS arithmetic succeeded. PortraitHeadMesh has a private initializer, static let standard and private let arrays; PortraitGeometry holds a static head and initializes only its center per frame. The pinned renderer calls primary geometry.hit once per pixel, which traverses the head BVH at most once. Pointer identity/RSS were not measured.

The independently calculated half-split recurrence for 5,248 triangles gives 2,047 nodes, 1,023 internal nodes and 1,024 leaves: 896 contain five triangles; 128 contain six. Maximum depth is ten edges/eleven levels. Conservative per-ray bounds are 2,047 node visits and 5,248 triangle tests. Construction uses 2,752 vertex entries, 5,376 candidates and 57,728 bounds-loop iterations.

The image maximum is 144×96 = 13,824 pixels. Twelve lights and 8×8 interactive sampling permit at most 768 shadow rays per shaded pixel, plus its primary traversal. The eight-pixel cancellation model bounds intervening work at 12,593,144 node visits and 32,285,696 triangle tests, not a wall-time guarantee.

Replacing the primary call with minimum 0 and checking its result requires one traversal if the supplied patch description is complete; it can change pruning. Candidate SHA-256 f406fb496129d82f81dc429cc3bb002fc1b168b5ed771edcff8e449d5e2757cb was supplied but not independently read. No Swift build/test, timing, native/device measurement, source edit or ref mutation occurred.
