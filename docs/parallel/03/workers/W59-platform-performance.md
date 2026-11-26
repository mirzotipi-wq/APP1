# W59 — platform/performance

- Actual runtime/canonical ID: `/root/wave06/w59_platform_performance`.
- Input: `74f7584b4e474c752ec0939add6b7522ba98094f`; restored private tree `/tmp/keyfill03-7f4b/workers/W59-platform-performance` was clean.
- Output: `/tmp/keyfill03-7f4b/builds/W59-platform-performance`.
- Candidate/root preview SHA256: `45a899619938e4a9c719f42af9c37d79e685c3a98d51465ca1995cc260595fc6`.
- Candidate/root test SHA256: `a68a38abce16baff2eee55c175bd3874664d8707d6c358d04282691455407c99`.

## Evidence binding

Retained `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb` native run 45826013515/job 139932504817 passed 163 methods, including nine preview methods, without native skips. Its Debug/Release simulator builds succeeded; six actual simulator Metal fixtures reported exact invalid masks and maximum channel error 1. `ci-native-ace9.log` SHA256 matches its receipt. Its preview/test hashes equal W59 input (`f609041d…`/`4d609ac7…`), **not** the current candidate. These remain historical native results, not current-source or physical-device evidence.

Root’s finalized Linux Swift 6.2.1 baseline ran ten methods: original nine passed; new pre-cancelled-begin witness failed two assertions (zero publications versus one; nil versus image 9). Corrected source passed all ten. Exact source/test hashes also match the temporary harness files. Logs: `../evidence/preview-cancelled-begin-original.log` and `../evidence/preview-cancelled-begin-corrected.log`; exact command/source receipts: `../evidence/preview-wave06-inputs.json`. The production publication seam executes; conditional SwiftUI/CoreGraphics code does not. Frontend parse success adds no native typechecking or SwiftUI scheduling evidence.

## Scope and remaining gate

W54 changes only paused presentation and two pre-cancellation guards. Inspection confirmed unchanged request identity, load/publication checks, 80 ms debounce, render call and image conversion. No W54 cache, pixel kernel, sample budget, dimensions or performance-bound delta warrants new timing measurements. This is unchanged-source reasoning, not a benchmark pass.

Minimum affected native verification: fresh Debug/Release app compilation; all ten `KeyAndFillTests/StudyPreviewPipelineTests` methods with finalized results; focused paused/no-frame and paused/stale-frame, active progress and foreground recovery UI evidence, including the changed caption at ordinary/largest text size. Candidate native status remains **UNRUN**. Earlier renderer changes and required current-source Metal evidence remain separate; ace9 does not close them.

W59 ran only `git rev-parse HEAD`, `git status --short`, `git diff --check`, targeted `git diff`, `git show ace9…:<source>`, searches and SHA256/byte comparisons. No tests/builds, source edits, commits, pushes or cleanup. All exact command receipts, full hashes, selected raw log lines and unexecuted native command templates are in [W59-platform-evidence.json](wave06-evidence/W59-platform-evidence.json). Token counter unavailable.
