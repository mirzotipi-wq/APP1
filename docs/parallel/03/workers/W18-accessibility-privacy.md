# W18 — Preview state semantics

Runtime/task: `/root/wave02/accessibility_privacy`. Input: `9c172d3e2d0c3f18636d84e8f31150236c63cbaa`.
Recreated worktree: `/tmp/keyfill03-7f4b/workers/W18-accessibility-privacy`; output: `/tmp/keyfill03-7f4b/builds/W18-accessibility-privacy`. Clean detached input verified. No source edit/commit.

`L` means exactly “Rendered neutral sphere and panel” or “Rendered neutral mannequin bust,” matching the requested subject. The table specifies assertions, not observed native behavior.

| State | Required presentation and semantics | Action/transition |
|---|---|---|
| Initial load or changed subject — current | `studyLoading`: “Rendering light study”; no other-subject image or previous error. | No Retry. Current completion selects ready/unavailable. |
| Same-subject update — current | `studyPreviousPreview`: “Previous render. L. Updating light study.”; `studyUpdating` label “Updating light study,” value “Showing the previous scene”; old backend/warning hidden. | No Retry. Current completion replaces previous pixels. |
| Ready — current | `studyPreview`, label L; current backend only. Positive unsupported count exposes `studyWarning` text “N unsupported pixels (magenta). Move the lights farther away.” plus triangle cue. | No Retry. Status is understandable without color. |
| Unavailable — current | `studyUnavailable`: “Study unavailable” plus applicable guidance below; no rendered-image claim. | No Retry button exists. Reappearance/reactivation retries; identical-request error remains visible until completion. |
| Retry available — proposed | Retain current unavailable guidance; `studyRetry` button labeled “Retry light study.” | Activate once; reissue current scene/subject with new attempt identity, preserving scene equality. |
| Retry pending — proposed | Hide stale error; `studyLoading`, “Rendering light study,” value “Retrying current light study.” | Hide Retry until completion. Cancellation/supersession cannot publish an obsolete result. |
| Retry completion — proposed | Success returns ready; failure returns unavailable with current guidance and enabled Retry. | A later activation starts a fresh attempt. |

Exact guidance: camera → “Move the camera above the panel and away from the subject.” Emitter → “Check the aiming direction of each active light.” Other error → “Check the camera, light positions, and preview settings.” Conversion → “The rendered image could not be displayed.” Fallback → “Check camera and lighting geometry.”

Proposed hosted checks: actual labels/values/actions and pixels; default/largest text keeps guidance/actions reachable; Retry target ≥44pt; status remains understandable with Reduce Motion. Check synthetic subject and unchanged scene; infer no runtime privacy or VoiceOver result.

Actual checks: prescribed directives/source and Git state read; `agent_cycle.py check/next` exited 0 (structure/M03 queue only). No Swift build/test/render, native execution, branch mutation or cleanup.
