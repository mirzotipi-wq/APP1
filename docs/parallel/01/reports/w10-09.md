# W10-09 — final platform evidence

Reviewed source `ce9f7aabd2de935c933468a00f007604ed7ea6ca`, tree `7e02b41c9df248f84207afb5599cb2cdf76ded7d`. Isolated adffee baseline remains clean. Same context 99; no added worker, build, commit, push or source change.

All 183 selected manifest inputs match Git; 182 present disk files match, with the privacy manifest sparse-excluded. This is not full CI dependency closure. `1f14d48` is source-equivalent; `4a5ae38` changes only integration-request documentation. Structural check/next passed, establishing structure only.

Final CI run 45870276318, core job 140083931415, succeeded at exact ce9 on Swift 6.4.2 Linux. Independently reconciled 433 default Debug and 433 default Release cases: every start has its matching pass, zero failures/skips, identical inventories. Log hash, source checkout and standard commands match the receipt; no per-file override appears.

Separate local Swift 6.0.3 runs pass 433 normal Debug/433 per-file Release; the latter explicitly disables WMO. All 86 current native Swift inputs match the successful syntax receipt. Parsing establishes no Apple SDK/runtime pass.

Counted 195 static native methods. Three Darwin Observation methods and one hosted layout method remain unexecuted. The forced Observation probe linked unsuccessfully and executed zero cases.

Prior adffee Apple job 140067450161 failed UITest line 95 (`greatestFiniteMagnitude`), with zero native case events and no previous accessor diagnostics. Six final Apple jobs were queued at 17:51:03 UTC; whole native acceptance remains unverified.

Optimized host evidence contains eight frame/four visibility workloads, seven samples each, and twelve observed cancellations; independently recomputed p50/p95 match. This establishes no device-performance or UI-speedup claim.

Earlier report/receipt are preserved; updated commands/hashes are in `receipt.json`. `source.patch` remains empty.
