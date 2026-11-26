# Wave 04 — accessibility/privacy

Canonical ID: `/root/w04_acceptance/accessibility_privacy`  
Input SHA: `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

## Actual checks

Pinned `git show` reads: AGENTS; architecture/design; lane-05 and M02/M03 acceptance; privacy excerpts; RealityStudioPreview/SpatialPreview; SpatialInteractionTests/SpatialPreviewTests/SpatialEntityUpdateTests; relevant StudioView and StudioAppAccessibilityUITests sections. Discovery: `git ls-tree -r --name-only`. Inspection: `nl -ba`, `sed -n`, `rg -n`. Exact representative command:

`git -C /tmp/keyfill05-be879deb/repo show 9725fb1177a5c7afbdf798ffd627e65e604c75b1:App/SpatialPreview.swift | nl -ba | sed -n '490,650p'`

A SpatialPreview permission/session/network-symbol search returned exit 1 (no matches); this is not runtime evidence.

## Outcomes — source evidence

- Equipment alternative: StudioView:912–948 has named 52-point-minimum light buttons, values, checkmark and selected trait. Busy state disables rack/workspace (:111–113); selection validates generation (:1220–1224) and membership (:927–929). UI test source asserts list selection and targets; no VoiceOver execution occurred.
- RealityStudioPreview:149–162,247–288 gates all custom gestures on enabled/rendering, valid scene, window and VoiceOver state. SpatialPreview:73–87,136–138,195–197 gates disabled/inactive interaction and VoiceOver selection.
- **Source gap:** SceneKit native navigation lacks an explicit VoiceOver gate: orbit-mode `allowsCameraControl` stays enabled (SpatialPreview:184,246–248); the VoiceOver predicate belongs to custom selection. This asymmetry does not establish actual gesture interference.
- Unavailable feedback exists: RealityStudioPreview:43–44 invalid-setup note; SpatialPreview:223–229,496–520 multiline, Dynamic-Type-aware label with accessibility children exposed; StudioView:722–738 camera-framing error and corrective instruction. Native assertions cover hidden geometry/recovery, not spoken feedback.
- Navigation updates renderer camera state; immutable scene input and selection-only callback do not author camera edits. Camera mode disables selection/control and applies authored pose/lens (SpatialPreview:207,246–258). Fit has a 44-point labeled button/hint (StudioView:554–557). No additional missing selection/feedback control established.
- RealityStudioPreview:71–72 explicitly constructs `.nonAR` with automatic session configuration disabled; its source contains no permission request, session start or network operation. Device permission/network behavior remains unobserved.

Files changed: this report only. Source edits/commits: none. Builds, toolchain/native/UI runs, manual VoiceOver and device privacy checks: not performed. Historical/successor results are not fresh worker evidence. Known first-save identity and invalid-mode issues were not reopened.
