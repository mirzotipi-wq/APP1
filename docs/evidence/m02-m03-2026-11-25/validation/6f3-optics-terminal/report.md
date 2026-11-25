# 6f3 studio-optics terminal execution

Run 45641483928, job 139303177603, source `6f3da3341f350084eac4a05b35a5bfd408d50193`. Observed 2026-11-25 16:17:24 UTC. Job conclusion: **failure**.

Expected ten methods in the new StudioOpticsUITests class; observed 10 unique starts and 10 unique terminal outcomes: 9 passed, 1 failed, 0 skipped. Interrupted: 0; not started: 0. Declared/executed sets match: True. Duplicate starts/outcomes and unexpected methods are separately recorded in terminal-summary.json.

Aggregate 1357.695 s test / 1357.812 s wall where a finalized ten-test summary exists. The published optics source SHA256 `371c45eb3fa6abbfdbfed941144203b72317a548cf3d4e3ee70409a569518c63` matches the reviewed extraction; all original exact-value, undo/redo, save and relaunch assertions remain unchanged. Actual execution is tied to 6f3, not a later candidate.

The selected excerpt is an exact ordered subset of the full decoded log retained in this scratch packet. Artifact metadata is source-bound; archive bytes were not downloaded. No library, full-CI, physical, calibrated or manual-accessibility acceptance is inferred.

## Failing phase and limits

The first method failed at `UITests/StudioOpticsUITests.swift:148`, after a successful initial save and relaunch, on the original ten-second `Saved locally` status wait. The relaunch log first reports a sixty-second missing event-loop idle notification, then delayed `projectStatus` existence resolution. The failure-only snapshot subsequently records `projectStatus` with label `Saved locally`, a normal frame and enabled state. That later snapshot does not prove the original predicate was true during the wait or distinguish delayed app readiness from delayed accessibility resolution.

Repeatability02–10 passed. The first method did not reach its final emitter/width equality checks. No wrong restored value or data-loss cause is established. The job failed with xcodebuild exit 65; all ten methods finished and finalized-result export succeeded, with no 32-minute test-step timeout. No optics product/test patch or deadline change is justified by this log alone. `failure-phase.json` and the exact contiguous `post-relaunch-failure-excerpts.log` preserve the observation and source range.
