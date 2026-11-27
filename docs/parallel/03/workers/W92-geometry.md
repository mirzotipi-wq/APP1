# W92 — Mesh, ray and camera reconciliation

**Runtime:** `/root/wave10/w92_geometry`. **Input:** `342e3280e3eb077d55e122c8bfb88b4062b431ed`; private detached tree `/tmp/keyfill03-7f4b/workers/W92-geometry` remained clean. All 31 final-manifest CPU hashes match; CPU diff against `db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5` is empty.

**Executed:** `python3 docs/parallel/03/wave10-evidence/W92-geometry.py` from the integration checkout, final exit 0; Python 3.12.14/Linux. The [receipt](../wave10-evidence/W92-geometry.json) retains 146 artifact identities, exact commands, source bindings and read corrections. First execution exited 1 because the original manifest wraps `fixtures`; the reader was corrected. Later executions clarified count labels. Agent-cycle checks were structural only.

- **Grazing scopes:** retained Swift logs support **25 cases**, one preserved plus 24 constructed. W22 is **translated Python arithmetic: 50 forward/reverse rays, 150 distinct input windows**, each evaluated by both methods; 14 original-cutoff misses. W30 separately records **25 selected-face solves on six faces, 75 windows, 90-digit arithmetic**, seven original misses. Python windows do not add to Swift coverage.
- **Mesh:** W22-derived surface data yields 2,626 welded vertices, 7,872 edges and 5,248 triangles; all edges have opposing paired incidences, one component, Euler 2. Only 128 coincident-pole triangles are excluded. This checks combinatorial closure, not self-intersection or universal ray correctness.
- **Camera:** original mask and magenta positions coincide at **11,708** pixels. Earlier overhead correction records `invalidCamera` with no clipped-frame files. W32's retained 40 calls change from **32 images / 8 rejections to 40 rejections**; its authoritative sidecar matches current mesh/renderer hashes despite stale embedded labels. Source uses one primary traversal from minimum zero, rejects clipped closed surfaces, and clips the open panel to background.
- **Ordinary matrix:** twelve PPM/scene pairs remain byte-identical; final masks are zero. Original raw masks/RGBA are absent, so their equality is unproved.

No blocker found. No Swift execution, build, render, native/device check or global M02/M03 acceptance. Exact token counters unavailable. Receipt SHA-256: `0a22bb0ca91f15b7818d834ada633bc8963d1c52a8b90a89777c31b36fabeba4`.
