# Wave 06 — concurrency review

Worker: `/root/w06_acceptance/concurrency`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`

**Disposition:** No stale-cache defect found in the bounded sequential source-state trace. No patch proposed. Read AGENTS, architecture/design, and lane05 acceptance/geometry notes; reviewed pinned source only.

Symbolic trace (not execution): selected auto-aim valid → pose/roll edit → subject equals source, with light unchanged (coincident) → selection off/on and unchanged-scene callback replacement → subject moves away (valid) → manual target equals source (coincident) → manual target/pose/roll changes (valid).

`RealityStudioPreview.Coordinator.update` refreshes `onSelect` before graph work and replaces `currentScene` before subsequent interaction (`App/RealityStudioPreview.swift:193`). `StudioEntityGraph` compares the complete scene/selection, recalculates shading eligibility, and commits its scene cache after lamp updates (`App/StudioEntityGraph.swift:80, :117, :123`). Subject edits therefore reach unchanged lights.

`StudioLampEntity` independently keys on light, subject, selection and shading allocation. Position or effective-optics changes, including manual target/roll, and subject changes invalidate geometry; geometry invalidates source components. Coincidence resets orientation, hides the face, clears `hasAimGeometry`, disables both aim markers, and removes emission. Selection-only updates consult the current `hasAimGeometry`; recovery recomputes geometry/source before publishing lamp caches (`App/StudioEntityGraph.swift:249, :253, :297, :306, :335, :340`). Shading-budget changes also invalidate source components.

SceneKit computes `renderChanged` against previous light/subject before updating those caches; the synchronous render branch then clears or recreates the source and resets fixture transforms (`App/SpatialPreview.swift:376, :409, :429`). Selection-only updates alter indicators without reviving emission; unchanged-scene updates still refresh callbacks before their early return (`:205, :245`).

Both paths are `@MainActor` with no suspension in these updates. This establishes ordering for delivered calls, not actual native frames, SwiftUI delivery of every intermediate edit, or gesture timing. SceneKit transaction commit is deferred to function exit; presentation follows its run-loop boundary.

Candidate `e66319bf8ee54925ae2121154adfbc4a6bbd099c` changes rectangle face scale and one SceneKit test only; it has no scheduling/cache changes. Root-confirmed historical evidence remains 9725: 176 native/30 spatial passing. Candidate inventory 184/38 includes eight unexecuted methods; no RealityKit runtime evidence. No builds, tests, helpers, or shared-source edits were performed; Core06, composition01, Plan07, AR13 and Study03/04 remain untouched.
