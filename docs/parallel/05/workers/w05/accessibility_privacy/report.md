# Wave05 accessibility/privacy — selection path

Worker: `/root/w05_acceptance/accessibility_privacy`
Input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`
Disposition: source review supports the list alternative; removed-selection VoiceOver feedback remains unverified. No source changes, builds, or native execution.

**Selection alternative.** `App/StudioView.swift` supplies named Lights buttons with a 52-point minimum row height, checkmark, and selected accessibility trait (L927, L942, L944, L948). Selection does not rely on color alone. Each action checks the current light UUID; `sceneAction` captures and checks the editor generation (L928, L1220). The spatial callback independently checks generation and current membership (L506). This depends on the generation contract already owned by lane01; no new ownership request.

**Removed selection.** Removal uses the captured target and generation (L253). `replace`, undo, and redo call `repairSelection`: retain a live selection, otherwise select the first remaining light or nil (L1321, L1330, L1333, L1338). The inspector follows that UUID, and an empty rig exposes “No light selected” (L114). There is no explicit announcement or accessibility-focus handoff in this reconciliation path. That is a native verification gap, not a demonstrated VoiceOver failure.

**Viewport boundary.** Both renderers hide implementation nodes and reject selection gestures while VoiceOver runs (`SpatialPreview.swift` L136, L187; `RealityStudioPreview.swift` L78, L154). Callback refresh occurs on each update; SceneKit resolves live attached nodes and RealityKit checks resolved UUID membership before dispatch (Spatial L150, L204; Reality L189, L273). The SceneKit unavailable message is separately exposed (Spatial L498).

**Native test plan, unrun.** On an arm64 iPhone running this revision with VoiceOver enabled: select 3D; navigate to Lights; select a nonfirst light; verify its spoken name/selected state and matching inspector. Remove it and verify understandable focus/feedback plus the first remaining selection. Undo/redo, then remove the final light and verify the empty state. Repeat at the largest accessibility text size. Record device/OS, SHA, speech/focus observations and captures; separately exercise stale UUID/generation callbacks in native tests. Intel SceneKit captures alone cannot establish VoiceOver behavior.

**Evidence/privacy limits.** Reviewed the three methods added at `3d5338dc`: callback publication and retained-node resolver tests, not gesture or VoiceOver execution. Historical `68c83` results do not validate this revision’s discovered tests. The traced selection path passes UUIDs locally; no upload invocation was observed in that path. This is not an application privacy audit.

