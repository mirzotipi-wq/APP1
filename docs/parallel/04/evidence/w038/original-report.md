# Worker 038 — accessibility and privacy review

- ID: lane04 / wave4 / w038; role: independent accessibility/privacy reviewer.
- Base and inspected HEAD: `c08cd0be2548467add169c3594207cf489760787` (detached, clean).
- Ownership: private report only; integration destination `finish/04-metal-cache`, archive `docs/parallel/04/workers/w038.md`. Root integrates; no source, UI, global state, commits, or refs changed.

## Baseline, hypothesis, and acceptance

One bounded source falsification: malformed packed metadata must retain explicit invalid-pixel semantics, ordinary CPU fallback text, and synthetic-only diagnostics without introducing user-name/photo flows. Dependencies are w034 header, w037 raw metadata test, and w039 strict precision matrix. Budget: one pass, no compilation, SDK installation, or runtime tests.

## Inspected identities

- `App/StudyKernel.h`: blob `f60258402a96f58b62607d5cefec5e41c7ec4137`; SHA256 `5bdba47a2620807b9fa61f899c2c6d8ed2cc534f5a3e26693cbdbfbc786ef628`.
- `NativeTests/StudyRendererTests.swift`: supplied blob `ffe6a6804eb3aa1bf4268331ff1ec52eeba9a119`; independently matched SHA256 `2ab0a71b0996035e853b379f4b281128a58532d386356a604e3a2c42bfa80299`.
- `NativeTests/StudyPrecisionMatrixTests.swift`: local blob `e101657aeea929186b0059df6963ee33d17769a5`; SHA256 `adad419fc6b3f441ed6e7251382b85c9ff07e75ad16c242aaa317d75213cf32f`.

## Actual commands and results

Read mandatory startup files. `git status --short`, `git branch --show-current`, `git rev-parse HEAD`, and `git log -3 --oneline` confirmed baseline. `python3 scripts/agent_cycle.py check` passed structural references only; `python3 scripts/agent_cycle.py next` reported global M03 editing/accessibility/persistence, superseded for this packet by lane ownership. `git diff --no-index -- /tmp/keyfill04-2987b1ee980d/workers/w038/App/StudyKernel.h /tmp/keyfill04-2987b1ee980d/workers/w034/App/StudyKernel.h` isolated new metadata guards. `sha256sum` and `git hash-object` identified inspected candidates. `rg`, `sed`, and `cat` reviewed renderer, decoder, preview, fixtures, and both test candidates. Two guessed filenames were absent; discovery resolved the actual `ReferenceStudyPreview.swift` and `ReferenceStudy.metal`. A read-only inline Python source checklist passed 11 assertions; it is not execution evidence.

## Findings and recommendation

No blocking source regression found. Guards precede relevant integer conversions; invalid output remains `(255,0,255,0)`. Decoder preserves an explicit unsupported mask and restores opaque magenta. Existing preview supplies an unsupported count, explanatory text, and warning icon, so meaning is not color-only. Precision fallback still returns `.cpu` / “CPU reference”; no new UI state is required.

New diagnostics derive from fixed synthetic fixture labels, numerical metrics, pixel bytes, and masks; no user account names, photos, scene dumps, or upload paths were identified. Production command label is constant; cache keys omit light display names. The new raw test also prints system `command.error` on failure; runtime contents were not inspected. Eight-case assertions retain maximum error <=1 and exact masks.

Recommend integrating reviewed candidates subject to source-specific CI. **hostCpp: UNRUN by w038. actualMetal: all new native tests UNRUN.** Parent-reported c08 host results predate this header. No VoiceOver, layout, device privacy, or platform-audit pass is claimed. Thresholds, CPU oracle, cache bounds, and UI remain unchanged. No separate evidence files produced.
