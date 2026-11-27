# Current published core CI verification

Source `135d3b4755d97bbb8fcff993d8dfd532a8d48b93`; run [46031166740](https://github.com/mirzotipi-wq/APP1/actions/runs/46031166740), core job `140615033235`, terminal success.

Original downloaded test logs contain exactly 594 distinct methods starting and passing once in each of Debug and Release (86 composition + 508 LightingCore), with zero failures, skips or duplicates. Both configurations have the same method identities. Tooling ran 120 tests successfully. Source syntax, shard, icon and privacy checks passed; syntax is not Apple API type checking.

All three original artifact ZIP SHA-256 values were independently checked against GitHub declarations before bounded extraction. The actual Linux receipts pass EFBIG, before/after-rename interruption, rename-EIO, and two recovery failure/retry scenarios. These are ext4 host probes, not physical storage or iOS evidence.

All 12 rendered fixtures passed with zero unsupported pixels. All 12 original PPM byte hashes match the emitted manifest. Six shared-kernel parity fixtures passed (maximum channel error 1); eight selected strict precision fixtures passed (maximum 0, required limit 1). The preparation tool created 33 precision fixtures, but this command selected eight; no pass is claimed for the other 25. The optimized benchmark contains eight frame workloads, twelve observed cancellations and four visibility workloads, with seven samples each for timed workloads; nearest-rank p50/p95 recompute exactly. Host measurements make no physical device, GPU, memory or thermal claim.

See `receipt.json`, `method-accounting.json`, `job-final.json`, `core-job-excerpts.log` and `artifact-verification.json`. The three ZIPs retain originals; extracted directories are reproducible private analysis. No product source, gates or ledger was changed; no Apple runtime result or beta acceptance is inferred. The prior published33171 core failure remains separate.
