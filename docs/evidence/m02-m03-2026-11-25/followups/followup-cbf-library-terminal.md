# Cbf library/reference terminal evidence

The [library/reference job 139252380291](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873/job/139252380291) completed with failure at 14:22:47 UTC on 2026-11-25, testing source `cbf94cecb113c1f03b0b8c7287e763655c14ec11`. All 11 declared methods started once and terminated once: **8 passed, 3 failed, 0 skipped, 0 unfinished, 0 unrun**. The selected test step ran 13:59:23–14:21:54 (22 minutes 31 seconds), within its unchanged 32-minute bound. Finalized-result export and both evidence uploads succeeded.

Both full accessibility audits failed at AccessibilityAuditUITests.swift:76 with `com.apple.xcode.xctest.accessibilityAudit Code=-56`, “Audit failed to complete in time.” No issue-named attachment was exported. These are incomplete audits; they establish neither a clean audit nor a particular contrast or other accessibility defect.

The third failure was `testArchivedDeleteRequiresConfirmationAndPersistsOnlyThatRemoval`, at ProjectLibraryUITests.swift:130: the keyboard introduction did not meet its typing-key readiness predicate within the existing wait. This failure is distinct from the earlier library-enabled/status waits and does not establish persistence loss. The other eight library/reference functional methods passed.

The compact packet at [validation/cbf-library-terminal](../validation/cbf-library-terminal/) preserves terminal API metadata, all 11 unique method outcomes and durations, the exact three errors, selected raw native-log lines, environment, source hashes from the tested git revision, and artifact provenance. Full artifact 15031956986 is 141,943,904 bytes, verified against its advertised SHA256 `6493755e13076d65d88d754c858e744430ae683f763830e96c27a54be115aed5`. Original logs, finalized-result ZIP and genuine attachments remain outside git at `/dev/shm/keyfill-a100-library-cbf/`.

This receipt preserves the failed result. It does not mark APP1 accessibility, the full regression gate, M02 or M03 complete. Source and workflow changes require their own subsequent execution evidence.
