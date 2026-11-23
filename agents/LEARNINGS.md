# Development learnings

Append evidence-backed lessons only. Template: date / task / observed failure or opportunity / reproduction / root cause / proposed process or test change / reviewer and validation / follow-up.

Initial design decision (not a measured result): single-image lighting reconstruction is underdetermined; keep the solver output editable, communicate confidence, and validate against held-out scenes rather than claim exact inverse rendering. Treat this as a hypothesis to evaluate in M04.

2026-11-23 / M01: The local environment has Swift but no Xcode and cannot resolve github.com. Reconstruct the portable package only from fetched source, verify every Git blob SHA before attributing the result to a commit, and leave simulator gates to the macOS workflow. The full domain suite passed 11/11; review is self-review, not independent device verification.
