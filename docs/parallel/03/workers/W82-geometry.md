# W82 — Geometry and archive challenge

**Runtime:** `/root/wave09/w82_geometry`. **Input:** `fb6ebdb7f9f73dab22b55df6f7919ef2f26eaad7`; tree `80b37a028b29c61e816587f1a26a714269aa17e1`. Private detached worktree: `/tmp/keyfill03-7f4b/workers/W82-geometry`; initially clean. No production edits.

## Executed evidence

Read required instructions, actual mesh/renderer, independent oracle, original grazing witness and camera records. Viewed both contact sheets and original clipped-camera PNG. `python3 scripts/agent_cycle.py check` passed structural validation; `next` reports M03 editing/accessibility/persistence.

Executed `python3 docs/parallel/03/workers/wave09-evidence/W82-geometry-data.py` from the integration checkout; exit 0. [Script](wave09-evidence/W82-geometry-data.py) and [receipt](wave09-evidence/W82-geometry-data.json) retain exact inputs, file hashes, command, host, results and corrected inspection errors. Receipt SHA-256: `df63fcf1001aebd07fb7b9a2ad6b8c1c9c0e9f9fe0df416c4debca5453aa728e`.

The topology check reuses W22's disclosed Python surface translation. Welding yields **2,626 vertices, 7,872 edges, 5,248 triangles**, one connected component, Euler characteristic 2. Every edge has two opposing incidences. Only 128 coincident-pole triangles are excluded; minimum retained twice-area is `1.000147841917296e-7 m²`, above the `1e-12 m²` floor.

## Findings and acceptance significance

- **No new geometry defect demonstrated.** Original/current profile, vertex-generation and topology/BVH blocks match. The narrow crown is inherited authored shape: the final ring is 1.918 mm wide before closing. `bust-soft` top five foreground runs contain 6/10/14/18/20 contiguous pixels. This supports saved-image continuity, not anatomical realism.
- **Grazing repair:** the retained independent oracle finds an interior crossing near 50 µm while original hit/occlusion miss. Source now uses twice-area-scaled determinant cutoff and independent plane/projected-area regressions. Swift tests were read, not rerun.
- **Archive truth:** twelve PPMs and scene JSONs are byte-identical; final masks are zero, alpha 255, RGB matches RGBA, and diagnostic magenta is absent. Original standard raw masks/RGBA are absent; manifest zero counts cannot establish raw-mask equality. Zero masks cannot prove geometry coverage.
- **Camera:** all 11,708 original mask positions equal magenta positions. Corrected clipping records `invalidCamera` without frame files; clear PNG/PPM/mask bytes agree. Source finds first surface before near-depth rejection, retaining open-panel clipping; the hidden-neck regression covers the earlier facing-only repair's failure.

All **31 CPU source hashes** in the final manifest match this input. No Swift/BVH execution, rerender, build, benchmark, native run, self-intersection proof or exhaustive ray validation occurred. Historical failures remain intact. These checks support only geometry/archive scope, not full milestone acceptance. Progress checkpoint sent; exact token counters unavailable.
