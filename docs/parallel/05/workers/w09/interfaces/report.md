# Wave09 interfaces review

**Pins.** Lane05 source `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; tree `5e3c76279f1ee6ca31ffe2429d1c2de38e7210d3`; campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. Required directives, architecture/design, acceptance, owner requests and native evidence read.

**Lifecycle.** `App/KeyAndFillApp.swift:14–18` hosts StudioView; its 3D caller is `StudioView.swift:482–513`, authored camera `722–739`. `SpatialPreview.swift:168–272` and `RealityStudioPreview.swift:68–94,189–226` refresh callbacks even with unchanged geometry and dismantle recognizers, callbacks and scene attachments. Invalid scenes discard equipment; removed/detached objects fail ownership checks (`StudioEntityGraph.swift:69–136`). The x86_64 simulator fallback precedes RealityKit construction. No new adapter defect found.

**Concrete frozen-source reproducer, unexecuted.** Unsaved draft → 3D → orbit/pan/zoom → first Save. `ProjectLibraryOperation.swift:115–133` changes generation while `resetsPresentation=false`; caller `.id(generation)` predicts coordinator recreation and initial Fit. Adapter update retention cannot survive caller destruction.

**Current owner checkpoint.** At 2026-11-26 16:01:06 UTC, read-only GitHub ref resolved `finish/01-architecture-composition` to `5ccfbaae821a32d88c12ed8b3abf1600aef25753`, superseding inspected `966c9c21adbb685d82127e7f88981b74daf47e3d`. Pinned `App/StudioView.swift:438–443` uses `.id(session.workspaceResetID)` while preserving captured-generation/live-UUID guards. `StudioSession.swift:331–334` rotates that identity only for presentation resets. `NativeTests/StudioSessionTests.swift:132–157,344–369` asserts first-save identity retention and project-switch reset at session level. Owner HANDOFF explicitly leaves native viewport retention unverified. Exact receipt, blobs and excerpts: `owner-checkpoint.json`.

**Owner request.** Lane01/lane20: integrate the pinned correction and verify hosted first-save camera/target retention, intentional switch/reload reset with overlapping UUIDs, and rejection of old-generation callbacks. Frozen `60059a0` remains unfixed. No owner edits made.

**Evidence limits.** Source `4e694bc` run 45838950713/job 139980771221 passed 184 native/38 spatial methods (28 direct SceneKit, 10 helper), plus Debug and Release builds; this is not a current-source pass. Source `60059a0` inventory is 185/39; dispatch evidence recorded 366 Debug/366 Release/100 tooling checks passed, native job 140022794410 queued. This reviewer did not poll native execution. RealityKit runtime, delivered gestures, device/manual VoiceOver/FPS/RSS/thermal remain unverified. No builds, toolchains, tests, source edits or ref updates performed.

