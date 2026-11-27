# A094 — final-source core CI reconciliation

Exact source: `af6b7e56bb5d2b550ebefcc5fd7bb2afc4c20867`.
[Run46033956426 / core job140624526340](https://github.com/mirzotipi-wq/APP1/actions/runs/46033956426/job/140624526340) completed successfully at **2026-11-27 16:36:32 UTC**. This packet contains fresh results from that source, not transferred results from135d.

## Actual verification

- **594 distinct methods** started and passed exactly once in Debug, and the same594 in Release; zero failures, skipped methods, duplicates or unrecognized test events. Swift6.4 emitted two All tests suite totals,86 and508, which sum to594; using only the final508 footer would undercount the package.
- **120 tooling tests** passed in26.960 seconds. Agent-state/shard/source-icon/privacy checks and Apple-source syntax passed. Syntax is not Apple SDK compilation.
- Real host persistence probes passed synthetic EFBIG, before/after-rename interruption, injected rename-EIO, and both recovery failure/fresh-confirmation retry cases. Original JSON receipts report every scenario check true and retain source/record/archive identities.
- **12 render fixtures** had zero unsupported pixels. All12 actual PPM hashes independently match the emitted checksum manifest. Images were not visually inspected by A094.
- **Six shared-kernel parity cases** passed, maximum observed channel error1 and exact invalid masks. **Eight selected strict-precision cases** passed at maximum error0 against required limit1. No execution claim is made for unselected prepared fixtures.
- Optimized benchmark output contains **eight frame,12 cancellation and four visibility workloads**. Each timed workload has seven raw samples; p50 and p95 were independently recomputed exactly using nearest rank. CPU: AMD EPYC7763; Ubuntu24.04.5 x86_64, Swift6.4.3, Python3.12.3.

## Original artifacts

All three original ZIPs were downloaded from the connected GitHub artifact endpoint, independently SHA-256 verified against declared artifact metadata, then extracted with path/symlink/size bounds. Full hashes and member hashes are in `artifact-verification.json`.

| Artifact | ID | ZIP bytes |
|---|---:|---:|
| Core |15215483854|116093|
| Atomic write |15214929661|157176|
| Recovery |15216620698|52429|

For integration retain `receipt.json`, `README.md`, `independent-checks.json`, `method-accounting.json`, `job-final.json`, `core-job-excerpts.log`, `artifact-verification.json`, `log-transport-counts.json`, `reconcile.py`, and the three original ZIPs. The full decoded job log and reproducible extracted directories can remain private scratch analysis; no live signed download URL is retained.

## Limits

No repository files or gates changed, no workflow was retried, and this worker ran no Swift builds/tests. The independent Python reconciliation checked original CI evidence. These are portable/core results, not Apple compilation/native/UI/actual Metal, physical-device performance, power-loss durability, signing, distribution or beta acceptance. The full Actions run may still have Apple jobs in progress; **core success is not whole-run success**.
