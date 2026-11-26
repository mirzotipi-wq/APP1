# W22 geometry/data

Runtime ID/canonical task: `/root/wave03/geometry_data`.
Input: `1cefc654630a86ab320e58283957f4e91d6cbce6`.
Private tree: `/tmp/keyfill03-7f4b/workers/W22-geometry`, detached and clean before/after.

**Executed:** Python 3.12.14, Linux x86_64/glibc 2.41:
`python3 /tmp/keyfill03-7f4b/builds/W22-geometry/probe.py` (exit 0; final redirected rerun also exit 0). Required source/protocol/evidence reads, status/HEAD/branch/log checks and scoped diff commands are recorded in `wave03-evidence/W22-geometry/commands.txt`. This is translated arithmetic, not Swift/BVH execution; root's 380/380 runs are not mine.

## Required witness/finite rays

All original normalized-plane witness fields reproduced exactly. Twice-area `1.521850571147037e-7 m²`; absolute determinant `1.521850570274425e-15`; new cutoff `1.521850571147037e-21`. Old `1e-14` rejects.

Witness plane distances: forward `4.999790731633365e-5 m`; reverse `5.000240675535184e-5 m`.

Reverse starts at `origin + direction*1e-4`, negating direction. Preserved plus 24 prescribed constructions, both directions: **50/50 unique matching faces** across 5,248 triangles. Each method's **150 windows** agreed: `[1e-6,4e-5)` miss, `[1e-6,1e-4)` hit, `[6e-5,1e-4)` miss. Maximum distance disagreement `4.114e-11 m`; weights `[0.3333311799,0.3333354868]`. Old cutoff misses 14 rays.

## Optional threshold stress

144 directions; two classifier disagreements at nominal incidence `1e-14`, positive tangent sign:

| Face | Plane incidence | Determinant/area incidence | 70-digit incidence (rounded) |
|---|---:|---:|---:|
| (0,16,true) | -1.0023286454302616e-14 | -9.976432544862613e-15 | -9.999650199732867222e-15 |
| (10,7,false) | -1.0019762797242038e-14 | -9.983974051913033e-15 | -9.977866066903078445e-15 |

Both high-precision represented-input decisions reject, agreeing with production. Zero determinant/high-precision classifier disagreements. Binary64 plane normalization is uncertain directly at the cutoff; this is not evidence of a production bug.

Cached normals preserve the same algebra (translated maximum length error `2.22e-16`). No geometry blocker found. Residual: no actual Swift/BVH/native execution or guarantee for arbitrary near-parallel rays. No source edits/builds/cleanup. Artifacts: `wave03-evidence/W22-geometry/{probe.py,results.json,summary.json,commands.txt}`; raw forward/reverse and stress rows retained.
