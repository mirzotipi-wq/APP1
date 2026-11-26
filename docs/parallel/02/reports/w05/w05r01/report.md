# W05R01 — target-lux acceptance guards

**PASS, static source review.** The actual solver preserves its finite, positive forward-result requirement and `abs(achievedLux / targetLux - 1) <= 1e-9` acceptance gate. Maximum output remains 100,000 cd, enforced both by `StudioLight.isValid` and the solver's separately validated maximum forward-model candidate. Requests must not exceed that maximum's actual lux.

Eight exact source guard assertions and two validation-order assertions passed. The already-exact fast path requires a valid source, a positive output, exact equality to the requested forward result, and the maximum-lux check first. Zero returns the already-validated source with candela set to zero. The quality contract retains the 1% point and 5% area gates.

Command: `python3 private-output/acceptance_audit.py > private-output/audit.log` (exit 0). Evidence: `acceptance_audit.py`, `audit.log`, `raw-results.json`, and `commands.txt` in this directory.

Provenance: worktree HEAD `928ca0eafa6330742114c2e0ac184789c2f17752`; frozen probe module revision `1b286885cb803ba17e159713651515ab119e17f1`; production baseline `58b3ca43943e18d0fc7800189b08365f424d9c9e`. Solver and model bytes match both earlier revisions; SHA-256 hashes are in raw results.

This role performed a bounded static check, without a runtime probe or package build. Independent wave roles provide runtime evidence. No production edits, threshold changes, device or calibration claim.
