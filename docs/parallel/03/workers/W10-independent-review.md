# W10 — independent review

Runtime/canonical ID: `/root/wave01/independent_review` (only exposed ID). SHA: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Detached worktree: `/tmp/keyfill03-7f4b/workers/W10-independent-review`. Status: inspection completed; clean input; no builds/renders/tests/downloads/source edits/commit.

## Finding

The twelve images (seven sphere/panel, five mannequin) check renders/artifacts, dimensions/storage, opacity, zero-unsupported masks, and changed comparisons. There is no independent pixel oracle; visual review is separate. Six backend parity fixtures are distinct, with intentional near-field unsupported pixels.

The 63-ray suite independently compares hits/distances/occlusion/normals. Its 18 grazes target rows 10/20/30, side offsets, direction −Z. Fifteen finite cases use exterior Y = −0.08/0/0.08; exact endpoints derive from accepted production hits. Neither targets nearly tangent tiny pole faces within short segments.

Production's `1e-14` determinant cutoff scales with face area: supplied pole witness `1.52185e-7 × 1e-8 ≈ 1.52e-15` is rejected before interval checks; the unit-normal oracle accepts `1e-8`. Root/W02 supplied a miss versus independent `t≈4.99979e-5` in `[1e-6,1e-4)`, excluding later surfaces. I did not execute this probe.

**Regression:** one pole-centroid near-tangent finite ray, independently asserting nearest hit/distance and occlusion.

**Limit:** selected checks cannot establish all-ray correctness or resolve this counterexample. No runtime or milestone pass claimed.

## Commands actually run

From the private worktree; every command except initial discovery carried `TMPDIR=/home/agent/keyfill03-7f4b/tmp`:

- `pwd && rg --files -g 'AGENTS.md' -g 'OPERATING_PROTOCOL.md' -g 'WORKER_PROTOCOL.md' -g 'm02-m03-code.md' -g 'render-study-fixtures.swift' -g 'PortraitHeadMeshTests.swift' -g '*Intersection*' -g '*Mesh*'`
- Separate `cat` commands for `/tmp/keyfill03-7f4b/repo/docs/parallel/03/WORKER_PROTOCOL.md`, `AGENTS.md`, `agents/OPERATING_PROTOCOL.md`, `docs/acceptance/m02-m03-code.md`.
- `sed -n '1,300p' scripts/render-study-fixtures.swift`
- `rg -n 'graz|intersect|occlu|triangle|segment|parallel' Tests/LightingCoreTests/PortraitHeadMeshTests.swift Sources/LightingCore/PortraitHeadMesh.swift`
- `git status --short`, `git rev-parse HEAD`, `git branch --show-current` (chained with `&&`).
- `sed -n '1,310p' Tests/LightingCoreTests/PortraitHeadMeshTests.swift`
- `sed -n '1,145p;275,345p' Sources/LightingCore/PortraitHeadMesh.swift`

Report written with `apply_patch`; no other artifacts produced.
