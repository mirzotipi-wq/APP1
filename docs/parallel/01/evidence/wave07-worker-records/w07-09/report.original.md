# W07-09 platform and performance review — original

## Conclusion

Accept the narrow navigation change for source integration. No CI/lane19 inclusion request is needed: the new method lives in the existing StudioSmokeTests class, and project.yml includes the UITests directory in KeyAndFillUITests. The existing studio-export selector explicitly includes the whole class. Native compilation and execution remain unverified.

## Source and exact inventory

Read-only worktree HEAD is 46a161cb01d0aee2e91940dbd06d82cfe2df5821. Product changes reviewed are 5decbb0bacb20a1b55f9c346fa954d5e76ebbff3 (App/StudioView.swift) and 08e80c756cb7c8aa4eaf11f27932c8f701000be1 (UITests/StudioSmokeTests.swift). This worker changed no source and created no commit.

scripts/native_test_shards.py discovers testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable in StudioSmokeTests. The workflow obtains selectors from that script, passes the resulting array to xcodebuild test-without-building, and verifies dynamically discovered methods afterward. Static inventory is 189 native methods in 23 classes; 36 required UI methods across room-precision 5, library-reference 9, studio-export 11, studio-optics 10 and app-accessibility 1; two separate opt-in platform-audit methods. All nine UI classes are assigned exactly once. This is discovery evidence, not generated-project or execution evidence.

## Runtime cost

The utility change adds a UUID generation capture, per-item Boolean disabled predicates, and a Subject position admission guard. allowsMutation reads loaded/saveBlocked and checks pending-operation state plus UUID identity. No new renderer, scene traversal, task, timer, I/O, or eager feature instantiation is introduced by this diff. Existing featureAction closures retain their guarded lazy opening behavior. The parent menu still blocks active editing. No measured speedup, device timing, or memory claim is made.

## Evidence reconciliation

The raw CI log has 471,293 bytes and SHA256 00323fc554ab439fd44077bbd8535368b39fce4181080383d67a243c41af93aa. It identifies source 5ccfbaae821a32d88c12ed8b3abf1600aef25753 and Swift 6.4.2. Parsing configuration command markers and every Test Case event yields 431 unique cases with exactly ordered started/passed events per Debug and Release: 862 passes, no failures, skips, duplicate or unassigned events. Both inventories hash to 388f38e9005f3890fc0376d92ab280f9a7d372abfa3d83567c012a5394128e6d when sorted, newline-delimited, and newline-terminated.

Both 175-input manifests match the named Git revisions. The later 08e80c7 manifest also matches every disk file; only StudioView.swift and StudioSmokeTests.swift differ from the passing CI inputs. The later receipt records 82 syntax-only Swift inputs, exit zero, and an empty syntax log. It establishes no Apple typecheck or UI execution.

The targeted boundary log independently contains 12 unique ordered passes and matches its retained hash. Its test source matches 73a829dc, published 5ccfbaa, and the current worktree. The earlier 45842239860 failed lexer log remains a failure. Initial audit-helper assertions required correcting newline termination and removing ANSI coloring for text matching; both failed helper attempts are preserved in receipt.json, and do not represent product/test failures.

## Checks and limits

agent_cycle.py check and next passed; next retains M03 with editing/accessibility/persistence outstanding. Shard validation and studio-export selector emission passed. Git status and diff checks are clean. Required startup documents were read; their earlier canonical state and wave5/wave6 history are not treated as fresh evidence. Full commands, hashes, parser results, and helper corrections are recorded in receipt.json.

No build, Swift rerun, Apple runtime, purchase/restore, camera/photo access, external action, CI edit, or nested worker occurred. Reference/Arrangement/Lux Void callbacks still cannot preserve rejected native drafts. Root alone integrates/pushes; manager may remove this clean worker tree only after preserving and verifying these artifacts.

