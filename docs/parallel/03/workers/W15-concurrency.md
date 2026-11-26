# W15 — Controlled preview lifecycle test design

Runtime/task: `/root/wave02/concurrency`. Input: `9c172d3e2d0c3f18636d84e8f31150236c63cbaa`.
Recreated private worktree: `/tmp/keyfill03-7f4b/workers/W15-concurrency`; output: `/tmp/keyfill03-7f4b/builds/W15-concurrency`. The earlier precreated tree disappeared before this worker started. Current tree was clean/detached. No source edit or commit.

## Minimal seam

Propose `NativeTests/ReferenceStudyPreviewLifecycleTests.swift`, hosting the actual view in a window. Inject a renderer closure matching `(LightingScene, StudySubject) async throws -> StudyRenderedFrame`, a cancellable debounce closure (production remains 80 ms), and a default-no-op attempt-finished event. Preserve existing task-cancellation guards and frame predicates.

An actor stub records started calls and suspends each in a continuation keyed by invocation number. It deliberately permits completion after cancellation. Tests await started/finished events, release chosen continuations, then await layout/accessibility predicates; no timing sleeps. Return distinct solid-color `StudyImage` frames and verify a stable interior screenshot pixel as well as actual accessibility elements. This distinguishes stale pixels despite identical image labels. The finished event makes negative assertions occur after the obsolete task has actually returned.

| Controlled sequence | Required hosted observation |
|---|---|
| Start A; change to B; finish B; finish cancelled A successfully | B pixels remain `studyPreview`; no updating or unavailable state. |
| Same, but cancelled A throws | B remains; A's error text never appears. |
| Publish A; start same-subject B and hold | A is `studyPreviousPreview`; label says previous; `studyUpdating` value says “Showing the previous scene”; old backend/warning hidden. Finish B replaces A. |
| Publish sphere A; switch to bust B and hold | `studyLoading`; no previous-sphere image. Late A success/error cannot replace B; completed B has bust label/pixels. |
| Current A fails; deactivate/reactivate with identical scene/subject; succeed next call | Current error is initially `studyUnavailable`; a second render starts and success replaces it. Scene stays equal. |

Existing source retries on reappearance/reactivation and has **no Retry button**. A proposed explicit Retry needs task identity `(renderRequest, retrySerial)`; increment only the serial, retain scene/subject and current cancellation checks. Specify its in-flight presentation separately: current code retains the error while that same request retries.

## Actual checks and limits

Read prescribed directives and preview/engine signatures; Git HEAD/status/log; structural `agent_cycle.py check/next` passed. Two guessed engine/test paths failed lookup and were corrected using `rg`. No Swift build/test/render, native execution or race was observed. Existing cancellation guards are not proven defective.
