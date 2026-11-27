# W28 — accessibility/privacy review

Actual runtime/task: `/root/wave03/accessibility_privacy`; parent `/root/wave03`.
Input: `1cefc654630a86ab320e58283957f4e91d6cbce6`.
Private tree: `/tmp/keyfill03-7f4b/workers/W28-accessibility-privacy`.
Status: completed source inspection; no source changes.

## Findings

No new unsupported-state suppression or photograph-privacy change found in the two-file production diff. This is source review, not a test pass.

`PortraitHeadMesh.swift:117` scales the parallelism threshold by triangle area; line 136 reuses the geometric normal. Restored intersections legitimately change geometry and shadows. They do not erase masks: `PortraitStudy.swift:197–220` still checks facing, shades the actual hit, and handles invalid surfaces by incrementing the count, setting mask byte 1 and writing magenta. Shared near-field checks remain at `ReferenceStudy.swift:301,307`. Geometry correctness is distinct from unsupported-surface classification.

`ReferenceStudy.swift:447–457` now checks cancellation after resolution validation and before camera validation/sample preparation. A cancelled invalid-camera request therefore yields cancellation; live invalid-camera errors remain. `App/MetalStudyRenderer.swift:175–229` propagates cancellation and checks it before retaining results. `ReferenceStudyPreview.swift:117–133` prevents cancelled publication, ignores cancellation errors, and retains camera/emitter/general error messages.

The preview copies the unsupported count at line 121 and presents the count, warning icon and explanatory text at 69–75. An updating previous image lacks its old warning, but is explicitly labeled “Previous render” and “Showing the previous scene” (55,77–88). Different subjects and obsolete errors cannot replace the current request (50–52). That existing behavior is unchanged by this diff.

No photograph access, persistence, upload or telemetry is added. The bust remains procedural neutral geometry (`PortraitStudy.swift:74–84`); the preview consumes a scene and rendered RGBA. Later root camera/preview changes are outside this pinned review.

## Actual checks and limits

Read the four mandatory instruction/contract files. Ran `git rev-parse HEAD`, `git status --short`, `git log -6 --oneline`; compared the three review files using `git diff f150f98e35dd735927075aac4d2f8b02295c6a67 HEAD --`; checked production filenames with `git diff --name-only`; used focused `rg --files`, `rg -n -C 8`, `rg -l`, and numbered reads. Only `PortraitHeadMesh.swift` and `ReferenceStudy.swift` changed in production; preview is unchanged.

No blocker. No builds, renders, native/physical validation, VoiceOver/layout audit, or tests executed. Root's reported 380 Debug/380 Release results are not this worker's execution. Exact private HEAD and clean status verified before/after review. Only this report was written in the persistent checkout. Recommendation: no change requested within this scope.
