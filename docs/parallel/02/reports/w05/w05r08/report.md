# W05 R08 — actionable target-lux errors

Candidate: `candidate.patch` changes only three error-description strings. `candidate-wording.md` supplies the wording and rationale.

Findings: `invalidLight` covers name, position, candela, kelvin and optics, so the candidate checks all five and gives the 80-character, 0–100,000 cd and 1,000–20,000 K limits. `unsupportedGeometry` also catches every failed scene validation before zero-target handling; the candidate includes scene/all-light checks and makes positioning/aim advice conditional on a positive target. It avoids claiming 0.05 m is sufficient for rectangles. `outputOutOfRange` includes upper-range, underflow and numerical-accuracy failures; the candidate offers a different positive target or geometry, plus 0 lux to turn off this light, rather than universally reducing lux.

Evidence: one bounded check, `python3 private-output/review_check.py`, passed. Original output is `check.log`; exact source excerpts are `source-evidence.txt`; SHA-256 and revision comparisons are `provenance.json`. Worktree HEAD: `928ca0eafa6330742114c2e0ac184789c2f17752`. Four reviewed production files exactly match module snapshot `1b286885cb803ba17e159713651515ab119e17f1` and production baseline `58b3ca43943e18d0fc7800189b08365f424d9c9e`. No Swift module was executed.

Static replacement verification preserves enum/signature, solver, 100,000 cd cap, 1e-9 target gate and 1%/5% quality gates. No user data interpolation or measured-output claim is added. `git diff --quiet HEAD` returned 0. Production is unchanged. No runtime, device, calibration or UI validation is claimed. Root owns integration.
