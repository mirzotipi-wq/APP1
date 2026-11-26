# Lane 03 — CPU Study and mannequin

## Active checkpoint

Branch: `finish/03-cpu-study-mannequin`.
Campaign fallback: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Remote main at startup: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`.
No lane 20 baseline was published in the initial remote branch inventory.
Later main changes are preserved for lane 20 integration. Canonical status, CI,
shared composition, photometry and GPU/cache implementation remain with their owners.

Baseline Linux Swift 6.2.1 suites: 366 Debug and 366 Release tests, zero failures. All twelve
unchanged image configurations render with zero unsupported pixels; original
PPMs, PNG conversions, scene JSONs, manifest and source hashes are retained in
`evidence/`. Root inspected `evidence/original-contact.png`.

Verified geometry defect: the absolute determinant threshold rejects a legitimate
near-tangent finite ray on the small bottom-pole triangle. The independent
normalized ray/plane and projected-area witness has positive barycentric weights
and distance 0.00004999790731633365 m. The shipped BVH and visibility test both miss
it. `grazing-original.json` preserves the actual Swift result. The candidate now
scales its parallel cutoff by triangle area and caches the outward geometric
normal. Independent plane/projected-area probes cover 25 near-tangent finite rays;
the original failures are retained in `wave02-original-probes.log`.

Sphere setup now checks cancellation after resolution validation and before
camera preparation or light-sample allocation, matching the mannequin's ordering.
All 380 portable Debug and 380 Release tests pass with these two corrections, including new
input-boundary, analytic-visibility and cancellation probes. This is a Linux
Swift result, not an Apple UI or Metal result.

Waves 1 and 2 completed twenty real fresh contexts; their ledgers contain actual
IDs, reports, hashes and private-worktree/recovery receipts. Wave 3 independently
reviews the accepted intersection and early cancellation fixes. The execution plan is ten acceptance
leaders plus nine distinct specialists per leader, with at most two children active
alongside root and leader. The root integrator is not included in the count.

## Runtime and recovery

The original shared workspace had only 95 MiB free and shared `/tmp` subsequently
filled. The first attempted build could not write a log. The retry passed using
private TMPDIR and build outputs. The execution environment then became
unavailable and its temporary files were lost. The published `9c172d3` checkpoint
survived. Worker test patches were recovered through content-addressed GitHub
blobs; the geometry file's recorded SHA-256 also matches. The checkout is now
`/workspace/scratch/7f4be4bbb2d6/APP1-lane03`, with private build outputs and TMPDIR
under `/home/agent/keyfill03-7f4b`. `recovery/README.md` distinguishes recovered
content from rerun evidence. No other task's files were removed.

Linux can execute portable Swift and the shared C++ kernel harness. SwiftUI,
CoreGraphics rendering, native Metal and Apple simulator tests cannot execute on
this host. No native or physical-device pass is inferred. Later wave reports and
the final handoff must preserve this distinction.

## Next work

Finish independent review of the corrected intersection in wave 3 and proceed
through the remaining waves. The camera correction now rejects outward back
faces exposed by the near plane as invalidCamera. Original width144 overhead
output had 11,708 false unsupported pixels with no lights; the corrected renderer
returns no image for that invalid camera. Thirteen close front/side and safe
overhead views remain supported, and the clear overhead image is byte-identical.
Twenty-one targeted camera/portrait/visibility/cancellation tests pass. Initial
test-design failures and their corrected pixel-ray witness are recorded in
evidence/camera-review.json; no true near-emitter mask was weakened. Add explicit preview
generation/adoption coverage and review loading,
retry, cancellation and subject transitions. Preserve the six parity fixtures,
eight precision cases, twelve original images and all resource/cancellation bounds.
