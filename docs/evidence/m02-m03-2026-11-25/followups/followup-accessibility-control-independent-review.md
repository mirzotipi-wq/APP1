# Independent accessibility control review

Reviewed by reused worker a097 against published base `cbf94cecb113c1f03b0b8c7287e763655c14ec11`. **Scoped source approval: no remaining blocking code finding.** This is a read-only review of five new diagnostic files, not Apple typechecking or execution. No primary source/workflow, required gate, test selector, deadline, or assertion was changed by this reviewer.

## Reviewed final bytes

| File | SHA256 |
| --- | --- |
| `.github/workflows/accessibility-control.yml` | `e9241d0ef66cc09e33ef0043975b82114a1ea841f7953de89e5da49241f0cf8f` |
| `scripts/diagnostics/accessibility-control/App.swift` | `674d7d39e33f4a05867367f2353b050974f5f0cfe81bdf4b4b8e6a03ce2917bb` |
| `scripts/diagnostics/accessibility-control/UITests.swift` | `d85161094014db74c5836e25def9a595cc72792bfe7e04d03fa2c3ca3556d6a3` |
| `scripts/diagnostics/accessibility-control/project.yml` | `15b1eceac0e8a3533cbdb70846d3b87ee210076c21a6c11c9cd9ca72eb71ae8e` |
| `scripts/diagnostics/accessibility-control/README.md` | `11e7fbba52cc9f429b9ebff4ea892d47524ace5c3a2ccab699ee79c8b6b61425` |

All five were rehashed from the restored checkout. The workflow/README delta against the retained first-reviewed version was inspected directly. App, test, and project bytes remained identical. The tracked diff for App, Sources, NativeTests, UITests, and the main iOS workflow was empty.

## Audit and verdict preservation

The generated project includes only the two new Swift files. One exact selector targets the sole control test. The static SwiftUI screen is verified ready with an enabled/hittable button and a kept screenshot before one `performAccessibilityAudit(for: .all)` call. Every issue handler returns false, including issues beyond the 32-description logging bound. The temporary continue-after-failure setting allows reporting issues without waiving them. Thrown errors retain NSError domain/code and are rethrown. No alternate audit, fallback selector, retry, sleep, or idle override appears.

Direct JSON log writes distinguish launch/readiness, audit begin, returned issue count, and thrown error with monotonic uptime. Description truncation preserves valid UTF-8 and the 4,096-byte bound. The workflow saves both native pipeline exit statuses and separately uses GitHub's authoritative audit-step outcome. A timeout can leave command-exit.json missing; that absence fails verification instead of fabricating a code.

Pass requires exactly one expected start and pass, exactly one audit begin/zero-issue return, no thrown marker, both command exits zero, a successful test-step outcome, unchanged source hashes, and finalized native summary counts of one passed/zero failed/zero skipped. Raw audit/result evidence remains separate from export failures. The evidence upload runs under always(), retaining any partial bundle and logs when the runner remains available.

## Provenance, scope and deadlines

The workflow fixes the standard Intel pool, Xcode26.6 build17F113, iOS26.5 SDK/runtime, and iPhone17Pro; it records source revision, selected runtime/device, compiler/toolchain output, image metadata, original source copies, and pre/post SHA256s. Commit/file contents are checked before building. Its own path-filtered trigger and distinct concurrency group neither cancel nor depend on the main workflow. Permissions remain contents:read, with checkout credentials not persisted.

The first reviewed workflow copied its own source under evidence/source/.github, which artifact upload omits by default according to the [official upload-artifact documentation](https://github.com/actions/upload-artifact#uploading-hidden-files). The final visible workflow-copy filename and explicit original-to-copy mapping resolve this finding without enabling broad hidden-file upload.

The new control's boot bound is10minutes and overall job32minutes; individual step maxima sum30minutes. The audit bound remains6minutes. This matches the primary boot allowance while preserving all primary limits. Host loss or entire-job termination can still prevent upload; the source does not establish guaranteed artifact recovery.

Owner's inspected receipts report two YAML parses, seven shell parses, six Python parses, and synthetic result checks rejecting zero tests, reported issues, Code-56, interruption, skips, wrong selection, and zero native counts while preserving native exit65. These are synthetic/Linux checks, not an actual Apple audit. The prior Linux Swift syntax parse also is not Apple typechecking. Actual compile, simulator execution, native-count schema, screenshot, and audit result remain pending.

Interpretation distinguishes phases: only an audit-phase deadline after audit_begin establishes that the audit did not finish; an actual audit_threw Code-56 records that specific error. A build, boot, launch, or readiness timeout does not reproduce an audit-service timeout. The owner clarified the final README accordingly, and the reviewer re-read and rehashed that correction. A successful control would not establish full-app accessibility or replace either required full-app audit. No product root cause or resource-pressure claim is made.
