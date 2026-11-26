# W05-concurrency

Runtime/canonical ID: `/root/wave01/concurrency`.
Assignment: trace preview identity, task cancellation, lifecycle and frame/message adoption.
Input SHA: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Private detached worktree: `/tmp/keyfill03-7f4b/workers/W05-concurrency`.
Status: bounded source inspection complete; no concrete stale-current-frame defect established. No source edits or commit. 

## Protection mapped

- `App/ReferenceStudyPreview.swift:14–31`: identity is the scene snapshot with `placementRoom` removed, plus subject. Inactive scene phase makes the task ID nil. Geometry only scales the display (`:54–59`); engine width defaults to 192, bust capped (`App/MetalStudyRenderer.swift:175–179`).
- `App/ReferenceStudyPreview.swift:109–134`: SwiftUI owns the task by active request. Snapshot/debounce precede direct actor await; cancellation checks follow rendering/conversion and guard errors. Successful matching frames are reused; failures retry on reappearance (`:111–114`).
- `App/ReferenceStudyPreview.swift:50–99`: current images/errors require exact request equality. A prior image is deliberately allowed only for the same subject, with previous/updating identifiers and label; backend/warnings require the current request. Old errors and different-subject images are hidden.
- `App/MetalStudyRenderer.swift:175–245`: actor rendering has no internal suspension; entry/cache-hit/final-work cancellation checks precede returning/admitting frames. A submitted GPU command finishes before the result is checked (`:82–87`, `:214–216`). Await alone establishes no race.

## One deterministic coverage gap

No inspected test forces late cancelled success/error delivery through preview adoption. Add a controllable completion boundary around the render dependency (`App/ReferenceStudyPreview.swift:116`): suspend A's delivery, replace with B, then release cancelled A; assert B remains current, prior same-subject imagery is explicitly marked only while pending, and obsolete errors/warnings/different subjects never appear. This is a test gap, not a demonstrated race.

Existing native engine checks cover cancelled cache hits and final CPU cancellation (`NativeTests/StudyRenderCacheTests.swift:265–316`). UI coverage also includes completed Study→Plan→Study and sphere→bust→sphere transitions (`UITests/StudioSmokeTests.swift:296–341`), plus `UITests/ReferenceComparisonUITests.swift:17`; none controls in-flight completion.

## Actual execution

All subprocesses used `TMPDIR=/home/agent/keyfill03-7f4b/tmp`. Ran `git status --short --branch` (clean detached HEAD), `git rev-parse HEAD`, `git log -5 --oneline`; read protocols/source/tests using `cat`, `nl -ba`, `sed`; searched with `rg -n 'ReferenceStudyPreview|studyPreviousPreview|studyUpdating|studyUnavailable|studyLoading|studyPreview' Tests NativeTests UITests`. No tests, builds, renders or downloads ran; no native/device pass claimed.
