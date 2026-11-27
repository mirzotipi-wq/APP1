# W52 — geometry/data

- Runtime/canonical ID: `/root/wave06/w52_geometry`.
- Input: `74f7584b4e474c752ec0939add6b7522ba98094f`; clean detached tree.
- Private tree: `/tmp/keyfill03-7f4b/workers/W52-geometry`.
- Output: `/tmp/keyfill03-7f4b/builds/W52-geometry`.
- Source: `App/ReferenceStudyPreview.swift`; SHA256 `f609041d40414637955ff8cf1d143c3269c0305a7a0dba8d937c845e95ecf4e2`.
- Status: completed source inspection; defect confirmed, correction proposed only.

## Exact current display

“Current” compares normalized scene plus subject; room placement is removed. Inactive includes background. These are body snapshots, before any subsequent task mutation.

| Frame | Active | Inactive/background |
|---|---|---|
| Current image | Image; optional backend/warning | Same |
| Stale image, same subject | Previous image + Updating | Same |
| Other-subject image | Rendering; image hidden | Same |
| Current error/conversion failure | Unavailable + Retry | Same |
| Stale same-subject error | Rendering; error hidden | Same |
| Other-subject error | Rendering; error hidden | Same |
| No frame | Rendering | Same |

Current images use `studyPreview`. Stale images use `studyPreviousPreview`, suppress backend/warning, show `studyUpdating`, and announce “Previous render. [subject label]. Updating light study.” Loading uses `studyLoading`; current failures use `studyUnavailable`/`studyRetry`.

The body never reads phase (lines 113–180). `activeRequest` becomes nil (91), and the task begins a new ticket then exits (186–187). Thus inactive progress/AX claims contradict the task state. Active retry/re-entry clears a matching failed frame before debounce; inactive exits before clearing it.

## Minimal correction and regression proposal

Gate only pending progress and the stale-image Updating accessibility text on active phase. Inactive/background should show a static “Light study paused” cue, retaining any eligible previous image. Keep current images/errors, subject filtering, room normalization, frame reuse, ticket/cancellation guards, debounce, renderer and cache unchanged.

Proposed native hosted-view matrix: all seven rows across active/inactive/background; assert visible image identity, status and accessibility text. Exercise active→inactive→active with pending work: no inactive spinner/Rendering/Updating; foreground restores pending status and then the current frame. Preserve existing pipeline regressions. These tests were not run.

## Evidence and limits

`git rev-parse HEAD`, status, branch and log succeeded; status stayed clean. `python3 scripts/agent_cycle.py check` and `next` exited 0 (structural check only; M03 remains queued). `rg` and `sed` inspected source/tests. Nine existing pipeline tests were read, not executed. No model, Swift/SwiftUI execution, build or source edit. Broad search/startup output was truncated; no command failures. Token counter unavailable.

Full commands, source witness and table: [W52-source-inspection.json](wave06-evidence/W52-source-inspection.json).
