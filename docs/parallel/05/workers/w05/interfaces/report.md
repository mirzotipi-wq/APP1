# Wave05 interfaces — source-only review

Frozen revision: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. Read pinned AGENTS, operating/continuity documents, product, architecture, roadmap, quality and design guidance.

**Result: no newly demonstrated interface gap.** The concrete check distinguishes replacing a project while retaining every light UUID—even an identical scene—from an ordinary scene update.

**Callback refresh:** `SpatialPreview.updateView` assigns the latest callback before its equality exit (`App/SpatialPreview.swift:204–213`). `RealityStudioSurface.Coordinator.update` likewise replaces its callback before updating the graph (`App/RealityStudioPreview.swift:189–199`); `StudioEntityGraph.update` may then return for equal scene/selection (`App/StudioEntityGraph.swift:69–80`). Therefore an unchanged scene does not retain the previous callback.

**Adapter boundary:** Neither adapter receives project identity. Existing UUIDs intentionally reuse nodes/entities (`SpatialPreview.swift:349–368`; `StudioEntityGraph.swift:100–115`). Their ownership checks reject removed/detached objects (`SpatialPreview.Coordinator.lightID:150–161`; `StudioEntityGraph.lightID:127–136`), but a retained object for an unchanged UUID remains current within the same coordinator. UUID-set comparison cannot distinguish replacement from ordinary editing.

**Composition boundary:** `StudioView.workspace` captures generation, rejects obsolete/busy callbacks and checks the live scene for the selected UUID before assignment; `.id(generation)` supplies replacement identity (`App/StudioView.swift:483,506–511`). The underlying guard requires both idle state and matching generation (`App/ProjectLibraryOperation.swift:81–83`); reload/recovery invalidates generation even when the project UUID is unchanged (`adopt:126–133`). Expected behavior is retained geometry/orbit for ordinary edits, current callbacks for equal-scene updates, and a new coordinator for a generation-changing replacement.

No composition edits or new owner request. The previously documented first-save reset remains with its existing owner action.

**Evidence limit:** GitHub source inspection only; executor unavailable. No build, tests, gestures or RealityKit runtime exercised. The supplied deff inventory of 180 native/34 spatial methods remains unexecuted; historical 68c83 results are not deff evidence.

