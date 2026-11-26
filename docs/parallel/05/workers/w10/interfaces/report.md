# Wave10 interfaces review

**Pins.** Production `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; documentation parent `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`; campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. Required directives, architecture/design, acceptance, HANDOFF and OWNER_REQUESTS were read.

**Live owners.** GitHub exact-prefix matching-ref requests for `heads/finish/06` and `heads/finish/20` both returned `[]` by 2026-11-26 16:30:21 UTC. Independent branch searches returned `branches:[], cursor:null` by 16:32:00 UTC. The requested baseline remains unchanged; no owner acknowledgment is inferred. Historical 14:17 UTC observations remain historical.

**Frozen first-save defect.** `App/StudioView.swift:482–513` captures generation and keys the 3D wrapper with `.id(generation)`. `App/ProjectLibraryOperation.swift:115–133` preserves presentation on save but changes generation when the draft gains its first project ID. Therefore unsaved draft → 3D navigation → first Save predicts coordinator replacement/initial Fit; this reproduction was not executed. `App/StudioSession.swift` is absent from frozen production.

**Owner implementation.** Inspected `5ccfbaae821a32d88c12ed8b3abf1600aef25753`: `App/StudioView.swift:414–443` uses `.id(session.workspaceResetID)` while retaining captured-generation and live-UUID guards. `App/StudioSession.swift:331–334` rotates identity only for presentation resets. `NativeTests/StudioSessionTests.swift:132–157,344–369` asserts first-save retention and project-create reset; these are source assertions, not native viewport execution. The live lane01 ref resolved to newer `7bdea15c771d7dfeeb3f20d011b3c02e4bc5b34f` at 16:32:29–30 UTC; its code was not reviewed.

**Disposition.** Lane01/lane20 must integrate the reviewed correction and verify hosted camera/target retention, deliberate switch/reload with overlapping UUIDs, and stale-generation callback rejection. No composition merge or source change was made.

**Execution and limits.** Executed read-only Git inspection, GitHub reads, and artifact hashing only; no builds, installations, tests, CI polling or ref updates. Frozen 185/39 is inventory; preceding `4e694bc` 184/38 pass is not transferred. Pending-at-cutoff history, four executor outages, and wave01 summary-only recovery remain explicit. No deallocation, renderer-thread atomicity, FPS/device or manual-accessibility acceptance is claimed. Exact receipts and source excerpts are in the two adjacent evidence files.
