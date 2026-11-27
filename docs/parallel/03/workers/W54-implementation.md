# W54 — implementation

- Runtime/canonical ID: `/root/wave06/w54_implementation`.
- Input SHA: `74f7584b4e474c752ec0939add6b7522ba98094f`; clean detached tree at assignment.
- Private tree: `/tmp/keyfill03-7f4b/workers/W54-implementation`.
- Output: `/tmp/keyfill03-7f4b/builds/W54-implementation`.
- Source: `App/ReferenceStudyPreview.swift`; SHA256 `cbed7ca5aab555ff9ed4b4e306054a50382ee99dfb8481380a08f7e16bcc9376`.
- Status: patch completed; source checks only; native verification pending.

## Change

Pending previews now use static “Light study paused” text when `activeRequest == nil`, covering inactive and background phases. A retained stale same-subject image also announces “Light study paused” in its accessibility label and keeps “Showing the previous scene.” Paused text uses `studyPaused`; active progress retains `studyLoading` and `studyUpdating`.

Completed frames, their backend/warnings, matching errors/retry, request/subject eligibility and retained-frame behavior stay unchanged. No helper or architecture refactor. Native tests are unchanged, following the root's explicit instruction to avoid tests that mirror string/phase gates.

| Eligible frame/state | Active | Inactive/background |
|---|---|---|
| Current image | Existing image/backend/warning | Same |
| Stale image, same subject | Previous image + Updating | Previous image + static paused cue |
| Matching error | Existing Unavailable + Retry | Same |
| No frame, other subject or obsolete error | Rendering | Static paused cue |

This table is source review, not executed SwiftUI behavior.

## Checks and evidence

`git diff --check` exited 0. `git apply --check` against the current integration checkout exited 0. Only `App/ReferenceStudyPreview.swift` is modified (17 insertions, 5 deletions). Exact byte comparisons confirmed unchanged pipeline, request/frame definitions, lifecycle/task, 80 ms debounce, engine/conversion, current backend/warning, error/retry UI, and all nine existing pipeline tests. These are source checks, not test passes.

Patch: [W54-paused-preview.patch](wave06-evidence/W54-paused-preview.patch), SHA256 `2fbf52d65654796f5f89d285f34cfe7c8d967551f5b62907c9c7309cfaba4341`.
Full command receipts and hashes: [W54-command-receipts.json](wave06-evidence/W54-command-receipts.json); private copy in the output directory.

## Limits and errors

Linux host; no native SwiftUI build or display execution. No tests or heavy builds run; parent/root owns serialized harness/native verification. The first report read used an absent `/tmp/keyfill03-7f4b/repo` cwd and was retried successfully at the actual integration path. Default-PATH Swift lookup failed; the supplied Linux Swift exists. Both probed Xcode locations were absent. No commits, pushes, cleanup or external messages. Token counter unavailable.
