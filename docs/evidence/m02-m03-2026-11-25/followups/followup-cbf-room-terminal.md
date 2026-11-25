# cbf room/precision terminal pass and actual host captures

Run [45623581873](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873), job [139252380171](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873/job/139252380171), tested commit `cbf94cecb113c1f03b0b8c7287e763655c14ec11`: **terminal success; all five unique required methods passed, zero failures, zero skips**. The full decoded log reports 1,120.996 seconds of tests (1,121.101 wall). `TEST EXECUTE SUCCEEDED` appears at 14:22:53.411236 UTC on 2026-11-25; the UI bundle build succeeded at 13:54:35.790011 UTC.

| Method | Result | Seconds |
| --- | --- | ---: |
| Manual room bounds and room edit | passed | 182.503 |
| Room resize with explicit move and signed coordinates | passed | 495.892 |
| Exact camera focal length, undo/redo and reopen | passed | 115.594 |
| Exact light intensity, validation, undo/redo and reopen | passed | 125.744 |
| Exact modifier width and room crossing | passed | 201.263 |

## First actual verification of the bounded host logs

The full evidence ZIP was downloaded: artifact ID 15031319205, exactly 5,674,653 bytes, SHA256 `86867e430236351f264f2ae6c3f7878282eaf35f72b1625740dcf7a317ae08d9`. The byte count and digest match GitHub metadata bound to cbf; every ZIP entry passed CRC verification. Only the two owned host-log entries were extracted.

The before snapshot is timestamped 13:59:44.072895 UTC; the after snapshot is 14:22:56.064937 UTC and records `github_test_step_outcome=success`. All four commands succeeded in both snapshots, each within its five-second bound. The process list explicitly reports truncation; virtual memory, swap/memory and disk output are untruncated. Both snapshots show 15,032,385,536 bytes of physical memory (14 GiB) and zero swap used. These are two bounded snapshots, not time-series measurements or evidence of a causal explanation for test duration or accessibility failures.

## Retained evidence and hashes

Repository packet: [validation/cbf-room-terminal](../validation/cbf-room-terminal/README.md). Original scratch directory: `/var/tmp/keyfill-c0abc39c4f18/cbf-ui-terminal-triage/room-precision/`. The complete decoded log and ZIP remain outside the repository; the other bounded text/JSON receipts below are copied exactly.

- `complete-terminal-decoded.log`: full decoded UTF-8 connector text, 505,164 bytes, SHA256 `cd75c004302a455a33d99b2fd2d95a31c009fe38ec5dbf84816f356abfe01793`.
- `terminal-excerpts.log`: 13 exact selected lines, 1,532 bytes, SHA256 `5a49d2a1ea09306a11857460f9c103d2dbde72d8e73129f15684df6ee60b79a3`. Each line was checked against the full log.
- `ui-host-before-tests.log`: original archive bytes, 68,025 bytes, SHA256 `0552edceedf31b96047e0dd9275b193bab99602058b45e8d0a552b9c6e224dfa`.
- `ui-host-after-tests.log`: original archive bytes, 68,057 bytes, SHA256 `87ef92e0e0856efb5a4116c0d4a2fbd2dfe5418aeddc5b2259862b447b5d40ab`.
- JSON receipts retain all five outcomes, final step status, source-linked artifact metadata, archive verification, normalized host-capture results and file checksums.

Compact artifact ID 15031517483 is 1,277,695 bytes with GitHub digest `19a257efc8b88fb4e0441a4536517a5772b3a224cb7956ea0b4025446bbbabd8`; only its metadata was inspected. The full ZIP remains in scratch and no binary archive was added to the repository.

This is actual Intel simulator room/precision evidence. It does not establish the library audits, studio result, ARM RealityKit behavior, physical-device acceptance, or a later commit's result. No source change, rerun, cancellation, gate waiver or deadline relaxation was made for this room receipt. This repository edition adds relative provenance links only; its new hash and the original report hash are in the [copy manifest](../validation/cbf-room-terminal/copy-manifest.json).
