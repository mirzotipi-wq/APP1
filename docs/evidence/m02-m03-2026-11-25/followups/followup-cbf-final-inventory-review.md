# Independent cbf terminal inventory review

Source: `cbf94cecb113c1f03b0b8c7287e763655c14ec11`; run 45623581873. Read-only review found no count or source-attribution discrepancy.

The root's compact core receipt matches the retained 328,562-byte raw terminal log, SHA256 `36843eea142bbd1a58154f8252940427e5c12d6d4da7b7e2c9d001a9136169fe`. All 33 retained excerpt lines occur verbatim. Debug and Release each have exactly one start and one pass for every one of the 319 source-declared portable methods. Durations are 13.301 and 5.652 seconds. Python records 35 progress dots, Ran 35 / OK in 0.397 seconds. Six unique shared-kernel and eight unique strict-precision fixtures report PASS.

The native job has 110 source-matched KeyAndFillTests starts and passes, zero skips/failures/interruption; all three required Metal methods passed. Its separate 319 LightingCoreTests events are not counted again as native methods.

All 36 source-declared UI methods started exactly once. Room: 5 passed. Library/reference: 8 passed, 3 failed. Studio/export: 19 passed, no failed or skipped terminal method, and one started method interrupted by the recorded 40-minute shard timeout: `StudioSmokeTests.testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene`. Aggregate: **32 passed, 3 failed, 1 interrupted, 0 skipped, 0 not started**. All ten optics workflows passed. Studio also has a distinct one-minute before-host-snapshot timeout; neither is silently counted as a test pass.

The independently derived method mapping, raw-log hashes, fixture rows and counts are in `cbf-final-inventory-review-a100.json` (SHA256 `e106bfdc481f4125608729f5ee964af6d355f733028e8b86b66efb23e999180a`). This review establishes the stated cbf results only. New keyboard, sharding and runtime candidates remain unrun; failed/incomplete full audits, regression and physical/manual gates remain unresolved.
