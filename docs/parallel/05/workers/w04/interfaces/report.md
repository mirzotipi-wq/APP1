# Wave04 interfaces

canonicalID: /root/w04_acceptance/interfaces

inputSHA: 956a3b1d70cb3d67ba136821d9828be80aee1c3b

lane01CheckpointSHA: 966c9c21adbb685d82127e7f88981b74daf47e3d

## Outcome: first-save viewpoint continuity fails by source trace

Read pinned AGENTS.md, architecture/design, four owned spatial files, composition/adoption boundaries and viewport test source. Used immutable git reads and checkpoint GitHub file reads. Actual original-pin reads predate the executor reset; no substituted live-head evidence.

**Identity transition:** Draft in 3D: projectID=nil, generation G0, workspaceResetID W0, Fit counter N, adjusted pose P. First save creates a project ID. ProjectLibraryOperation.swift:115-120,131-134 preserves scene/history/presentation but rotates G0→G1. Checkpoint StudioSession.swift:210-214 retains W0. StudioView.swift:515-520 nevertheless uses `.id(generation)` for RealityStudioPreview, replacing its representable/coordinator. Input StudioView.swift:506-511 has the same boundary: this is a retained defect.

The new checkpoint RealityKit coordinator initializes lastFitRequest=nil/needsFit=true (RealityStudioPreview.swift:105-112); update/layout resets target, distance, yaw and pitch (179-181,216-230) despite unchanged N. SceneKit fallback initializes nil lastCameraMode/lastFitRequest (SpatialPreview.swift:28-33), triggering Fit (153,187-189). P is lost without pressing Fit. This is source-derived lifecycle evidence, not an observed native result.

**Other checks:** At the input pin, retained-coordinator edits/selection refresh callbacks without refitting (RealityStudioPreview.swift:189-205; SpatialPreview.swift:204-269). Explicit Fit changes the counter; SpatialOrbitState.fit resets navigation. StudioEntityGraph updates geometry by UUID independently of viewport state. Later same-project saves/renames retain generation; switch/reload/recovery reset presentation. Camera mode follows the authored camera.

**Lane01 owner request:** In StudioView composition, key the 3D wrapper by `session.workspaceResetID`; retain captured generation for stale-selection rejection. Cover first-save G0→G1/W0→W0 retaining the native coordinator and adjusted pose, explicit Fit resetting pose, and switch/reload W0→W1 resetting identity. Existing viewport state tests cover navigation math, not this SwiftUI transition. Root integrates; no owned spatial source change is needed for this fix.

**Limits:** No builds/toolchain/native runs. Historical CI 68c83/run45817222487: 366 Debug + 366 Release core, 100 tooling, 171 native/25 spatial. Pin discovery: 176 native/30 spatial, unexecuted. No RealityKit runtime, device or VoiceOver acceptance claims.

Files/commits: report.md only; source files none; commits none.
