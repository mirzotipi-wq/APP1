# W86 resource audit

- Worker/runtime ID: `/root/wave09/w86_resource`; private detached tree `/tmp/keyfill03-7f4b/workers/W86-resource`.
- Input: `a7c93be58a04154748c951b3d485b05300e9692c`; clean on arrival. Scope: resource/numeric review only. Source/test SHA-256s, inspection commands and arithmetic receipt: `wave09-evidence/W86-resource-bounds.json`.
- Baseline/hypothesis: challenge logical cache payload, mask accounting, overflow, resolution and geometry bounds. Accepted contracts read; parent owns broader governance. Qualitative checkpoint completed; no additional tests/builds requested. No source edits.

## Findings

1. No new resource defect established. Cache rejects negative/oversized costs before replacement. Eviction uses `maximum - incoming` before addition; recorded counters remain nonnegative and within limits, including `Int.max`. `retain` charges actual RGBA and mask `Data.count`; masks use one byte for every pixel, including supported pixels. Inspected tests cover independent mask eviction, replacement, zero-cost entries and integer extremes; they were not executed here.
2. Validated dimensions precede multiplication. Interactive sphere maximum is 192×128 (98,304 RGBA + 24,576 mask bytes); reference sphere 96×64; mannequin 144×96 (55,296 + 13,824). Two largest sphere frames fit; a third exceeds both budgets. Engine clamps high mannequin widths, including `Int.max`, to 144; direct mannequin API rejects widths above 144. Low/invalid widths remain rejected.
3. Twelve validated lights bound prepared samples to 768 interactive/12,288 reference; each rectangle uses at most 64/1,024 evaluations. Mesh construction is private/static: 42×64 segments, expected 5,248 triangles; balanced subdivision and six analytic parts bound traversal. The eight-pixel cancellation contract is a work-count bound, not elapsed time; final cancellation was outside this audit.
4. The 4-entry/256-KiB/64-KiB guarantee applies to cache logical payload. It excludes caller-retained frames, render arrays/Data conversions, Metal buffers, allocator capacity, static geometry and other metadata overhead. Cache keys strip display names, but initial scene/name validation still scales with Unicode input bytes; 80 graphemes does not impose a byte limit (existing owner01 caveat).

## Evidence and limits

Independent Python arithmetic checked all legal widths and integer-boundary subtraction; assertions held. This is arithmetic evidence, not a Swift/runtime test pass. No build, render, benchmark, RSS/device measurement or production modification. Recommend preserving current narrowly scoped resource claims; no new blocker.
