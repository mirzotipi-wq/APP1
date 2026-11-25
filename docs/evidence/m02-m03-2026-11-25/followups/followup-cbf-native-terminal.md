# cbf native terminal pass

Run [45623581873](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873), job [139252380108](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873/job/139252380108), tested commit `cbf94cecb113c1f03b0b8c7287e763655c14ec11`: **terminal success; 110 unique native methods passed, 0 failed, 0 skipped**. The complete decoded log reports 20.311 seconds (22.130 wall). These counts come from actual Intel simulator method outcomes.

The required Metal methods passed separately: `testMetalMatchesCPUOnAvailableDevice` in 3.748 seconds, `testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal` in 1.023 seconds, and `testCancelledInitialParityValidationCanRetryMetalOnSameEngine` in 1.108 seconds. All six parity rows report matching invalid-pixel counts and zero outlier fraction; maximum channel differences are 0 or 1. The portable macOS package also passed 319 tests with 0 failures in 40.875 seconds (41.045 wall).

The log records Debug `TEST BUILD SUCCEEDED` at 13:58:37.341500 UTC, Release `BUILD SUCCEEDED` at 14:01:38.175373 UTC, and `TEST EXECUTE SUCCEEDED` at 14:07:33.879893 UTC on 2026-11-25. Finalized native result export, both native evidence uploads and both unsigned app uploads succeeded. The macOS persistence step and its evidence upload were also step-success; this receipt does not independently reopen that persistence archive.

## Evidence

All files remain outside the repository at `/var/tmp/keyfill-c0abc39c4f18/cbf-native-terminal-triage/`:

- Complete decoded UTF-8 connector log: 852,303 bytes, SHA256 `536013b6b8cfa31bbdca004355fcf34a0127622280b3dc29de1e60e93e04e33f`.
- Selected 128 exact lines: 20,119 bytes, SHA256 `f78abe1f5f950cf82c601b288238d9343892936e677648bc4209ccf1048789f1`. Each selected line was checked against the complete log.
- `terminal-summary.json` retains all 110 outcomes, actual Metal/parity rows, durations and scope. `terminal-job.json`, `artifact-metadata.json` and `receipt-sha256.json` retain source-linked job/artifact metadata and file checksums.

Four artifact metadata records bind to cbf:

| Artifact | ID | Bytes | GitHub SHA256 |
| --- | ---: | ---: | --- |
| Debug app | 15030400978 | 10,316,455 | `174aad1d86897ac5a3e079734aba544296d84abcb29c037ce97f254f8cff16be` |
| Release app | 15030565422 | 4,162,845 | `cb0ce7d5420102bdf50f555738f12b321cfe85bdb640a1fdef852cfa1dbee117` |
| Full native evidence | 15029819462 | 64,748,486 | `f2bfca92dc452693bc27342ea6fa194597d82cd131c33adb4b391fa0e1d88ffe` |
| Compact evidence | 15030154042 | 332,368 | `986efba2ca47ba4b49cabb6c7e287a73101c4258cf7fa0d33bfad5422c1c0b23` |

ZIP bytes were not downloaded for this repeat receipt; no independent archive verification is claimed. No source edit, rerun, cancellation, deadline change or skip was introduced. This result does not establish either UI accessibility audit, the ARM RealityKit path, physical-device behavior, or success of a later commit. The three UI shards remained running when this receipt was written.
