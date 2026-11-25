# f6 studio/export terminal failure evidence

Run 45604744523; job 139182923449; tested revision f6f43dde19be7a554bc5c6924e3239c18b34d1be. Actual partial counts: 14 passed, one failed after relaunch, one interrupted by the 40-minute deadline, four not started. Nine optics workflows passed; repeat 10 failed. No complete-suite pass is claimed.

`terminal-excerpts.log` contains 84 exact selected lines of the decoded GitHub job log, including all 16 starts and 15 terminal outcomes, the full relevant save/relaunch/failure context, deadline error and missing finalized result. It is not the complete log. `terminal-summary.json` is derived from the complete decoded job log and cross-checked against the separately downloaded native-tests.log. `trace-last-optics-and-relaunch-excerpts.log` retains exact selected rows from the last optics process and its relaunched successor. Both complete logs remain in the owned temporary evidence directory and are bound by SHA256 receipts.

Both full and compact ZIP downloads matched GitHub digests and passed CRC validation. Their inventories are retained; no ZIP or complete build/test/trace log is copied here. The compact archive contains only the three slider-trace text files; no finalized xcresult or UI hierarchy/screenshot attachment was available. The original collector status is preserved unchanged, including its non-authoritative test_exit_code=0 after the external timeout. Actual assertion/step/job outcomes govern this receipt.

`expected-source-methods.json` is the preterminal expectation snapshot: its pending-runtime label is historical, not the final outcome. It binds all 20 required methods and the two committed f6 test-source hashes. The actual final partial outcomes appear in terminal-summary.json. Report and every copied file are hashed in copy-manifest.json. No missing signal or process exit code has been invented.

See ../../followups/followup-f6-studio-terminal.md for findings and diagnostic limits.
