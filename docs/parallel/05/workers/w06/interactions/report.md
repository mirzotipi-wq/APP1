# Wave06 lane05 — interaction source review

Reviewer: `/root/w06_acceptance/interactions`. Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`. **No interaction blocker found in this bounded trace.**

Read `AGENTS.md`, architecture, design, and current `m02-m03-code-v2` acceptance; reviewed pinned source only. References: `App/SpatialPreview.swift` (`updateView`, `updateContent`, `Coordinator.lightID`); `App/StudioEntityGraph.swift` (`update`, `lightID`, `StudioLampEntity.update`); `App/RealityStudioPreview.swift` (`canInteract`, `selectLight`).

Assuming an otherwise valid scene and selected aimed emitter:

| State | Equipment / outline | RealityKit aim markers | Source eligibility |
|---|---|---|---|
| Valid rolled aim | Selectable; outline enabled; shared frame carries roll | Enabled when Float segment exceeds 0.0001 m | Eligible |
| Undefined/coincident aim | Equipment remains selectable; outline enabled; orientation resets | Both disabled; stale geometry cannot remain enabled | SceneKit light cleared; RealityKit components removed |
| Valid recovered roll, same UUID | Existing equipment reused; orientation refreshed; outline enabled | Recomputed and enabled for sufficient segment length | Restored |
| Zero candela after recovery | Equipment remains selectable; outline enabled | Remain enabled for valid geometry | SceneKit intensity zero; RealityKit components removed |

Selection off hides/disables outlines and RealityKit markers; selection on restores the applicable flags without changing source eligibility. RealityKit eligibility still respects its seven-emitter shading limit. SceneKit has fixture, child outline, source and stand nodes, **no separate aim markers**. Its visible outline resolves through the fixture; stand resolution requires height above 0.05 m. RealityKit collision shapes belong to point/housing/stand/feet, not outline or aim markers.

Stale-hit guards are source-consistent: SceneKit rejects hidden traversed nodes/hidden content, requires registered identity, direct content attachment and current UUID; removal rebuilds maps and detaches nodes. RealityKit rejects disabled traversed entities/anchor and requires the current owned root attached to that anchor; removal clears ownership. UI-disabled/inactive/detached interaction is blocked by actual tap guards, separately from graph lookup. Both taps also guard VoiceOver-running state; this establishes no navigation result.

Candidate `e66319bf8ee54925ae2121154adfbc4a6bbd099c` changes rectangle face scale, with no interaction-code change. Source inventory supplied: frozen 183/37, candidate 184/38; root-confirmed older `9725` native 176/30 pass is historical. No builds, tests, native gestures, occlusion, visual acceptance or RealityKit runtime claim. Core06/composition01/Plan07/AR13/Study03/04 untouched.
