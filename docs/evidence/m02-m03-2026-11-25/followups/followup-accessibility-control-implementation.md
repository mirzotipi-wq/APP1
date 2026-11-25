# Independent accessibility control: frozen implementation

Existing worker a100; based on main cbf94cecb113c1f03b0b8c7287e763655c14ec11. Only five new repository files are owned by this change: the separate accessibility-control workflow and App.swift, UITests.swift, project.yml, and README.md under scripts/diagnostics/accessibility-control. No production source, original tests, shard selector, primary workflow, acceptance threshold, or original deadline changed.

## Behavior

The tiny native SwiftUI screen has default system text and a real in-memory button action. One explicitly selected XCTest verifies its initial label and enabled/hittable button, retains one before-audit screenshot, and invokes the full .all accessibility audit once. Every callback returns false. There are no issue-element snapshots, idle overrides, retries, sleeps, network calls, project persistence, or custom renderers.

Unbuffered JSON lines carry monotonic uptime markers. Audit return with issue count is distinct from audit throw; the latter preserves NSError domain/code and a UTF-8-safe bounded description, then rethrows the original error. Diagnostic text stops after 32 issue-detail records but every issue remains an original XCTest failure. One returned audit with zero issues is required for a clean diagnostic pass.

## Workflow and provenance

The standalone workflow uses standard macos-26-intel, explicit Xcode26.6/17F113, iOS26.5 SDK/runtime and iPhone17Pro. It records the executed environment, checks source bytes against the committed revision, retains exact copies with original-path mappings, and checks source hashes again after execution. The workflow source copy has a visible filename so upload-artifact does not omit a hidden .github directory.

Build precedes explicit boot. The boot bound is ten minutes, matching the existing primary workflow and observed hosted startup timings. All step bounds total30 minutes; the new diagnostic job bound is32 minutes, leaving setup/cleanup margin. The full audit step remains six minutes. Its concurrency group and restricted push paths are independent of iOS Prototype. The unchanged general workflow still responds to pushes according to its own triggers.

Native exit status is preserved. An independent result check rejects missing/wrong/duplicate test execution, a skip, missing audit completion, returned issues, or a thrown audit error. Finalized native summary counts must corroborate one passed test and zero failed/skipped tests. Raw native summary/help, audit log, exit status, source receipts, screenshot attachments, and any finalized or partial result bundle are uploaded even when earlier steps fail. Export failures remain separately visible.

## Actual local validation and review

- Both YAML files parsed; seven shell blocks passed bash -n; six inline Python blocks parsed.
- Both unchanged Swift control sources passed Linux Swift frontend syntax parsing after the executor was restored. This is not Apple typechecking.
- Ten focused synthetic Python result-flow checks passed: valid exact execution; rejection of empty, skipped, wrong-test, interrupted, returned-issues and Code=-56 cases; native exit65 preservation; acceptance of one-test native counts and rejection of zero-test counts.
- The original production/native/UI paths and main workflow have no change from this work.
- a097 independently reviewed the final five files and closed with no blocker. Its hidden-source-copy finding and README audit-phase wording finding are resolved.

The executor reset erased the first uncommitted checkout. All five last-validated files were reconstructed to exactly match their earlier SHA256 hashes, and all final intended files were restored and rehashed after root cloned main. Final source/validation artifacts exist again on disk.

## Final source hashes

- Workflow: e9241d0ef66cc09e33ef0043975b82114a1ea841f7953de89e5da49241f0cf8f
- App.swift: 674d7d39e33f4a05867367f2353b050974f5f0cfe81bdf4b4b8e6a03ce2917bb
- UITests.swift: d85161094014db74c5836e25def9a595cc72792bfe7e04d03fa2c3ca3556d6a3
- project.yml: 15b1eceac0e8a3533cbdb70846d3b87ee210076c21a6c11c9cd9ca72eb71ae8e
- README.md: 11e7fbba52cc9f429b9ebff4ea892d47524ace5c3a2ccab699ee79c8b6b61425

Receipts: ../accessibility-control-validation/structural.json and synthetic-result-checks.json. The independent review is followup-accessibility-control-independent-review.md. Recovery copies and the historical interruption receipt are in ../accessibility-control-recovery/.

No Apple build or actual control audit has run as part of this local validation. Build/boot/launch failures must not be labelled audit timeouts. An audit-phase timeout or exact captured Code=-56 would establish an independent control occurrence, not a universal platform cause. A clean control would not establish APP1 accessibility or close M02/M03/manual/physical gates. Publication and actual CI remain root-owned.

