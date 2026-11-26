# W08 — Accessibility/privacy

Runtime ID: `/root/wave01/accessibility_privacy` (only exposed identifier).
Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Private detached worktree: `/tmp/keyfill03-7f4b/workers/W08-accessibility-privacy`.
Status: complete, bounded source inspection; no source edits or commit.

## Answer

No concrete text/state misstatement found. `App/ReferenceStudyPreview.swift:32-33,55-61` supplies current-subject and explicit previous-render labels. Lines 78-88 identify updating and “Showing the previous scene”; lines 102-105 name initial rendering. Lines 69-75 describe unsupported-pixel count and recovery in text, independently of magenta. Lines 90-99,123,129-133 provide unavailable/error explanations. This confirms authored semantics, not their runtime accessibility-tree presentation.

The inspected render path is local in design: the view passes scene/subject to the engine and creates a `CGImage` from memory (`App/ReferenceStudyPreview.swift:116-145`). CPU/Metal routing and cache admission remain in-process (`App/MetalStudyRenderer.swift:175-245`); the default Metal shader library is loaded locally (line 28). CPU renderers return memory-backed data (`Sources/LightingCore/ReferenceStudy.swift:532-533`; `Sources/LightingCore/PortraitStudy.swift:219-220`), and cache storage is an array (`Sources/LightingCore/StudyFrameCache.swift:23`). No explicit network request or file write was observed in these inspected paths.

## One gap

Non-success accessibility states lack located regression assertions. `UITests/StudioSmokeTests.swift:303-305,322-330` checks successful images/labels/backend; `UITests/ReferenceComparisonUITests.swift:17` checks existence. Searching Tests, NativeTests and UITests for transient/error identifiers and their text found no matches. Add deterministic state presentation checks for loading, previous/updating, unsupported warning, and unavailable explanations. This is a coverage gap, not a demonstrated VoiceOver defect.

## Actual checks and limits

All shell subprocesses used `TMPDIR=/home/agent/keyfill03-7f4b/tmp`. Ran `git status --short --branch`, `git log -3 --oneline --decorate`, `git rev-parse HEAD`, `nl -ba App/ReferenceStudyPreview.swift`, `rg --files`, targeted `rg -n` identifier/text/I/O searches, and Python numbered source excerpts. Worktree was clean at the stated SHA; final state-text test search returned exit 1 (no matches).

Tests/builds/renders/downloads: none. Physical VoiceOver, app-wide privacy, runtime network traffic and platform/framework file behavior were not verified. No acceptance pass claimed.
