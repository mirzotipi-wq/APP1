# 8fa native simulator terminal verification

Exact source `8fa4399f50554836ce70ec2929a28534f70ba4b0`, primary run 45649843650, native job 139341046225: **success**. I independently parsed the complete decoded terminal job log and compared method identities against the 110-method inventory read from that exact Git revision.

All **110 distinct native methods started and passed once**. There are zero failed or skipped methods, no duplicate starts or terminal outcomes, no missing/unexpected methods, and no interrupted method. XCTest reports 36.576 seconds of test time and 38.329 seconds wall time. The separate macOS portable package run reports 319 tests with zero failures in 29.698 seconds (29.810 wall).

The three required Metal tests actually passed: CPU parity 5.468 seconds, near-field routing 1.696 seconds, and retry after cancelled initial parity validation 1.930 seconds. Six logged parity fixtures—hard, soft, warm-rotated, dark, near-field and translated—each report invalid-match=true and zero outliers; maximum channel error is 0 or 1. The workflow's native result check also explicitly reports that the required Metal methods passed and no native methods were skipped.

The Debug app/native bundle build completed at 16:25:19.727134 UTC; the unsigned Release app build completed at 16:27:42.640631. The first native method starts at 16:35:20.303061 and the last passes at 16:35:58.315957. The command reports TEST EXECUTE SUCCEEDED at 16:39:28.743785. Job metadata records successful uploads for both apps, native full/compact evidence, and the macOS atomic-write evidence; result export also succeeded. No GitHub error annotation appears in the terminal log.

The checkout log prints the exact 8fa revision. The five retained native/build/atomic artifact records independently identify the same workflow source. The observed environment is standard Intel macOS, Xcode 26.6 build 17F113, with iPhone 17 Pro on the selected iOS 26.5 simulator. This establishes Intel simulator execution; it does not establish ARM RealityKit runtime behavior, physical-device behavior, or the remaining UI shard outcomes.

Files in this directory retain the complete decoded job log, selected exact outcome lines, every parsed method event, source inventory and hashes, terminal job metadata, and relevant artifact metadata. The artifact ZIPs were not downloaded in this review: their sizes and digests are GitHub-reported metadata, not fresh byte verification. `receipt-sha256.json` records hashes of the actual local text receipts. The macOS atomic probe step succeeded, but its individual archive contents were not separately re-reviewed here.

No source, workflow, deadlines, retries, or required test assertions were changed during this read-only verification.
