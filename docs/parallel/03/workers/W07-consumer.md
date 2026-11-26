# W07 — consumer

- Runtime ID / canonical task path: `/root/wave01/consumer` (live `collaboration.list_agents` entry).
- Input SHA: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
- Private detached worktree: `/tmp/keyfill03-7f4b/workers/W07-consumer`; clean at inspection.
- Assignment: preview failure/retry trace and ReferencePNG role.
- Status: inspection complete; no source changes, builds, renders, tests, downloads, children, or commit. Output allocation: `/tmp/keyfill03-7f4b/builds/W07-consumer`; no execution artifacts.

## Failure and retry

Conditional conversion failure: the engine returns/retains successful pixels (`App/MetalStudyRenderer.swift:227–245`). The preview converts them but stores a current frame even if `makeImage` returns nil (`App/ReferenceStudyPreview.swift:116–123,138–145`). This is a branch trace, not an observed failure.

The user sees a warning icon, **Study unavailable**, and **The rendered image could not be displayed.** (`:90–99,123`). The error replaces earlier pixels and remains visible during retry.

Failure alone does not restart `.task(id: activeRequest)` (`:109`). Reappearance restarts the task; inactive→active also changes request→nil→the identical request (`:29–31`). The early return requires a nonnil image (`:111–114`), so failure permits another attempt after 80 ms. Successful engine pixels may come from cache (`App/MetalStudyRenderer.swift:181–185`); conversion failure occurs downstream. The error view has no retry button.

## PNG role

`ReferencePNG` is a metadata sanitizer, not an encoder/general decoder (`Sources/LightingCore/ReferencePNG.swift:3–14`). ImageIO encodes imported references before filtering (`App/ReferencePhoto.swift:93–105`). Preview conversion uses RGBA→CGImage without ReferencePNG.

## One actionable coverage gap

Add a conversion-fails-once regression asserting the unavailable message, unchanged-request inactive→active retry, second conversion, and `studyPreview`. Existing reopening coverage uses success (`UITests/StudioSmokeTests.swift:296–312`); scoped searches found no preview-error assertions. This is a test gap, not a runtime/stale-frame defect.

## Commands / actual evidence

Ran instruction `cat`, `git status --short --branch`, `git rev-parse HEAD`, `git log -3 --oneline`, `rg --files`, scoped `rg -n`, `nl -ba … | sed -n …`, and report `wc -w`. Initial search exited 2 for nonexistent `AppTests`; corrected searches succeeded. Assigned TMPDIR used after instruction reads. Tests: **none**; W2 owns probes. No execution pass claimed.
