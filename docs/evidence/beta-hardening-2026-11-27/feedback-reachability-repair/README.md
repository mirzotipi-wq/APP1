# A086 — targeted Settings feedback reachability

The historical `2fc7647` beta workflow failed to reveal `openBetaFeedback` even though its original screenshot shows the complete button at the end of Settings. A084 independently verified the downloaded archive. A086 also viewed that original image and read the original hierarchy.

The button frame is `(16, 768, 370, 52)`. The old generic reveal mode checks its center `(201, 794)` against an application rectangle inset by 100 points vertically, whose bottom is 774. Continued downward dragging cannot make this final row satisfy that arbitrary inset at the scroll limit.

Only `UITests/BetaWorkflowUITests.swift` changed: `openFeedbackFromSettings` now passes `avoidingKeyboard: true` to its existing `tapContent` helper. This selects the existing `fullyVisible` reveal mode. That mode derives the viewport from the actual scroll ancestry, navigation owner, keyboard and fixed controls, and requires the entire target frame inside it. The wait for an enabled control, live hittability assertion, tap, exact feedback content/privacy assertions, twelve-attempt limit and all deadlines are unchanged.

The actual unchanged `StudioViewportGeometry` implementation was compiled on Linux against A084's 257-node transcription of the original hierarchy. It returns `(0, 132, 402, 742)`, containing the entire button. The replay also rejects keyboard, navigation, bottom and horizontal clipping, and preserves navigation ownership for a covered undo control. The root application frame is inferred from the original Main Window and 3x image, not a fresh live query.

Both DEBUG and Release syntax parses, the targeted whitespace check and an exact-diff check passed. These are not Apple compilation or runtime acceptance. The live tap, sheet transition and remainder of the feedback workflow still need fresh native execution.

Retain `receipt.json`, `change.patch`, `main.swift`, `feedback-geometry-nodes.json` and `probe.log`. The compiled `probe` is reproducible scratch output and should not be committed. Original PNG and hierarchy references remain in A084's packet.
