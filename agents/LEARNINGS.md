# Development learnings

Append evidence-backed lessons only. Template: date / task / observed failure or opportunity / reproduction / root cause / proposed process or test change / reviewer and validation / follow-up.

Initial design decision (not a measured result): single-image lighting reconstruction is underdetermined; keep the solver output editable, communicate confidence, and validate against held-out scenes rather than claim exact inverse rendering. Treat this as a hypothesis to evaluate in M04.

2026-11-23 / M01: The local environment has Swift but no Xcode and cannot resolve github.com. Reconstruct the portable package only from fetched source, verify every Git blob SHA before attributing the result to a commit, and leave simulator gates to the macOS workflow. The full domain suite passed 11/11; review is self-review, not independent device verification.

2026-11-23 / M01: fileExists plus a metadata-only size check was an insufficient read contract: missing and unreadable must differ and actual bytes must stay bounded even if the file changes size. Replaced with explicit metadata error classification, regular-file validation and bounded reads; five regression tests pass. A UUID-scoped debug test namespace prevents stale fixtures across repeat runs. Simulator behavior is still unverified; use the actual native runner to close the gate. The private app storage model does not promise protection against concurrent external filesystem mutation.

2026-11-23 / independent M02 math: use a distinct normalized direction type and declared minimum emitter-plane distance; compare quadrature against both a closed-form parallel rectangle and a separately coded Simpson integral. Initial local compilation caught a missing try in an invalid-geometry test; corrected and reran the complete suite. No gate changes or weakening; retain raw fixture results and never extrapolate them to calibrated photographic realism.

2026-11-23 / independent M02: Versioned source optics and camera lens settings must preserve legacy scenes, including nil defaults, and reject future/invalid schemas. Eight optics and seven camera tests passed alongside all prior tests (37/37). Keep camera-forward and emitter-normal bases distinct, and treat degenerate aim and near-field as unavailable rather than silently substituting a valid geometry. Native rendering remains illustrative and unverified.

2026-11-23 / M01 CI: run 45254550467 concluded failure after both jobs were canceled before steps and log downloads returned 404 BlobNotFound. Later runs queued. Inspect job-level state, not just workflow conclusion; distinguish canceled runner from compile/test failures, and verify the exact tested source hashes locally when macOS is unavailable. No quality gate changed.
