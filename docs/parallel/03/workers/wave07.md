# Wave 07 — CPU and consumer contracts

**Complete: ten actual workers, W61–W70.** Nine fresh specialists plus W61; root and precreated trees are not counted. Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. Documentation checkpoint: `8ce5e464253144deccb39d838faef70f05e0c38c`.

Retain lane03 CPU source. Sources/Tests/scripts and all 31 CPU manifest inputs match db7. No production edits, builds, new renderer/kernel tests or benchmarks.

- Byte checks verified six parity fixtures, all 84 near-field positions and 136,320 zero bytes across twelve final masks. [Exact CSV](wave07-evidence/W62-near-field-invalid-indices.csv); [audit metadata](wave07-evidence/W62-fixture-metadata.json).
- Fourteen fixture/four source hashes and retained six-plus-eight host pass logs match. This excludes lane04's changed kernel.
- Packed 6/3/3 rows and public consumers remain compatible. **Integrate lane04 engine and width-aware helper together**, preserving lane03's tiny-output fix.
- **Positive per-cell Float subnormal/zero policy remains open with02/04.** Source ordering falsifies only the proposed guard-skipping explanation. No optional probe was authored or run.
- Preserve actual Swift width24 **FAIL**: fraction(error>4)=0.00520833>0.005. Latest04 guard/native assertions were inspected, not executed. W70 found no bounded-evidence contradiction.

## Actual runtime IDs

| Worker | Canonical ID |
|---|---|
| W61 | `/root/wave07` |
| W62 | `/root/wave07/w62_geometry` |
| W63 | `/root/wave07/w63_api` |
| W64 | `/root/wave07/w64_implementation` |
| W65 | `/root/wave07/w65_concurrency` |
| W66 | `/root/wave07/w66_resource` |
| W67 | `/root/wave07/w67_consumer` |
| W68 | `/root/wave07/w68_accessibility_privacy` |
| W69 | `/root/wave07/w69_platform_performance` |
| W70 | `/root/wave07/w70_independent_review` |

Assignments, hashes, actual checks, reports and limits: [wave07.json](wave07.json). Immutable owner requests: [analysis](wave07-evidence/W61-owner-request-analysis.md). W61–W70 reports are in this folder; raw receipts are in wave07-evidence. Four prior resets remain recorded; no new wave07 reset observed. Token counter unavailable. Native/device/AX acceptance and global promotion are not claimed. Root alone commits/pushes and verifies preservation before cleanup.
