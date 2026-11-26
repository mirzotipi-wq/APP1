# W02-geometry

- Runtime/canonical ID: `/root/wave01/geometry`.
- Assignment: BVH/ellipsoid finite hit, normal and visibility review.
- Verified input: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
- Worktree: `/tmp/keyfill03-7f4b/workers/W02-geometry`.
- Status: complete. Source/fixtures/historical failures unchanged; no commit.

## Execution

Read required protocols/contract. Commands: `git rev-parse HEAD`, `git status --short --branch` (clean/detached), `git log -3 --oneline`, `cat`, `rg`, `wc`, `nl | sed`; two discovery misses corrected. All subprocesses used `TMPDIR=/home/agent/keyfill03-7f4b/tmp`.

Ran inline `python3 - <<'PY'`, exit 0: binary64 source-math transcription versus independent plane/area oracle; no saved script. **No Swift tests/builds/renders ran.**

## Path map

Source references are under `Sources/LightingCore`. `PortraitStudy.swift:106-128` selects panel → ellipsoid bound → BVH head → analytic parts. Mesh slab/triangle/traversal paths: `PortraitHeadMesh.swift:63-78,105-134,279-338`; triangle intervals are half-open. Ellipsoid roots/gradient: `PortraitStudy.swift:45-64`; bound/visibility: `98-101,136-150`. `ReferenceStudy.swift:303-324` offsets and re-aims finite shadow segments; sphere visibility is at `73-90`.

## Findings

1. **Determinant cutoff:** `PortraitHeadMesh.swift:109` applies absolute `1e-14` to an area-scaled determinant; `PortraitHeadMeshTests.swift:49-50` instead tests normalized angular cosine. Witness: first retained triangle, row 0/column 0 topology `(b,d,c)`; rename vertices `a,b,c`, set `n=unit(cross(b-a,c-a))`, `v=unit(b-a)`, `d=unit(v-n*1e-8)`, `o=(a+b+c)/3-d*5e-5`; interval `[1e-6,1e-4)`. Raw-normal magnitude `1.521850571147037e-7`; determinant `1.521850570274425e-15`; angular cosine approximately `-1e-8`. Full 5,248-triangle arithmetic scan: production math zero hits; oracle one at `4.9997910026839084e-5`. Add Swift hit/occlusion regression; consider area-relative parallelism. Existing grazing tests (`115-147`) lack tiny-face centroid/angular cases.

2. **Coverage only:** direct quadratic subtraction feeds ellipsoid hit/normal/visibility (`PortraitStudy.swift:45-64,148-149`); no failure demonstrated here. Add tangent ears/shoulders, inside exits, adjacent endpoints and long-distance valid-coordinate rays. `PortraitStudyTests.swift:24-28,56-62` covers only one shoulder normal and coarse segments; mesh endpoint tests do not establish analytic-part behavior.
