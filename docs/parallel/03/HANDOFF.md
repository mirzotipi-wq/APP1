# Lane 03 — CPU Study and mannequin

## Active checkpoint

Branch: `finish/03-cpu-study-mannequin`.
Campaign fallback: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Remote main at startup: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`.
No lane 20 baseline was published in the initial remote branch inventory.
Later main changes are preserved for lane 20 integration. Canonical status, CI,
shared composition, photometry and GPU/cache implementation remain with their owners.

Baseline Linux Swift 6.2.1 Debug suite: 366 tests, zero failures. All twelve
unchanged image configurations render with zero unsupported pixels; original
PPMs, PNG conversions, scene JSONs, manifest and source hashes are retained in
`evidence/`. Root inspected `evidence/original-contact.png`.

Verified geometry defect: the absolute determinant threshold rejects a legitimate
near-tangent finite ray on the small bottom-pole triangle. The independent
normalized ray/plane and projected-area witness has positive barycentric weights
and distance 0.00004999790731633365 m. The shipped BVH and visibility test both miss
it. `grazing-original.json` preserves the actual Swift result; no correction has
yet been applied at this checkpoint.

Wave 1 is running with real fresh contexts; its live ledger explicitly distinguishes
created workers from unspawned assignments. The execution plan is ten acceptance
leaders plus nine distinct specialists per leader, with at most two children active
alongside root and leader. The root integrator is not included in the count.

## Runtime and recovery

The original shared workspace had only 95 MiB free and shared `/tmp` subsequently
filled. The first attempted build could not write a log. The retry passed using
private TMPDIR and build outputs under `/home/agent/keyfill03-7f4b`; the original
`/tmp/keyfill03-7f4b` name is a symlink to that directory. No other task's files
were removed. The existing Swift toolchain is used read-only.

Linux can execute portable Swift and the shared C++ kernel harness. SwiftUI,
CoreGraphics rendering, native Metal and Apple simulator tests cannot execute on
this host. No native or physical-device pass is inferred. Later wave reports and
the final handoff must preserve this distinction.

## Next work

Finish wave 1, build independent geometry/visibility probes in wave 2, correct the
verified intersection defect in wave 3, and proceed through the user's remaining
waves. Add explicit preview generation/adoption coverage and review loading,
retry, cancellation and subject transitions. Preserve the six parity fixtures,
eight precision cases, twelve original images and all resource/cancellation bounds.
