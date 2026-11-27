# Wave 01 — CPU Study acceptance map

Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Exactly ten actual contexts: leader `/root/wave01` plus nine fresh specialists; maximum two specialists active together. Ten detached sparse worktrees were created sequentially and verified clean at this SHA. No source edits/worker commits. The [ledger](wave01.json) records actual IDs, assignments, paths, reports and checks.

## Confirmed finding

`PortraitHeadMesh.swift:109` compares an area-scaled determinant with absolute `1e-14`. W02 arithmetic found a valid short grazing segment missed on a tiny pole triangle. Root independently reproduced it with shipped Swift: oracle hit near `4.99979e-5` m, production hit/occlusion absent. See root's [probe](../evidence/grazing-ray-probe.swift) and [original result](../evidence/grazing-original.json). A separate root correction candidate is unaccepted here.

W10 confirms why fixtures pass: the image matrix lacks an independent pixel oracle; existing grazing/segment tests omit this tiny-face angular case. Preserve fixtures and add independent hit/occlusion regressions.

## Contracts and follow-up

- CPU paths: `ReferenceStudy.swift` owns sphere/panel lighting, visibility and checkpoints; `PortraitStudy.swift` selects panel/bound/BVH/analytic parts. W04 established no additional defect.
- Whole-frame invalid input throws; unsupported surfaces use opaque magenta plus count/mask; valid darkness is black. Compute sentinels become opaque.
- Preview task identity/cancellation/request matching guard adoption; previous images are labeled. No stale-frame defect established. Conversion failures can retry on reappearance/reactivation. `ReferencePNG` sanitizes imports; Study converts RGBA directly.
- Next: confirmed geometric witness/adjacent segments; sphere pre-cancelled setup ordering; small malformed-scene matrix; controlled preview late-completion, conversion-retry and non-success semantics. Sphere evaluates zero pixels before its first poll, so no eight-pixel violation was found. Existing switching tests remain preserved.

## Actual evidence

[W01 acceptance](W01-acceptance.md) preserves frozen gates. Workers performed source/status inspection, structural ledger checks, W02 inline arithmetic and W09 environment probes. No worker Swift build/test/render/benchmark, Metal or UI run. Root's separate runs remain separately attributed.

W09 verified Swift 6.2.1/Linux x86_64; Apple tools absent. Native preview/Metal, runtime privacy and VoiceOver are unverified here. No milestone/release acceptance promoted.
