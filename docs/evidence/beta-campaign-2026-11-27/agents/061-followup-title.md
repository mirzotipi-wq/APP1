# Worker 061 follow-up — observed welcome-title measurement failure

- **Identity:** `/root/a061_beta_largest_text`, continuing worker 061; no descendants.
- **Input:** `f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5`, detached `worktrees/061`. Original `061.md` remains unchanged.
- **Owned changes:** `App/StudioWelcomeView.swift` and `UITests/BetaAccessibilityUITests.swift` only.
- **Commit:** `84ade7af5f8563d43d31b1e83931f58af4644821` — `Measure welcome title from recorded SwiftUI text layout`.

## Actual failure and evidence

Run **46004241191**, export job **140527590003**, failed this method at its original line 194: **587 observed pixels < 591 required pixels**. This remains a failed run; no supplemental welcome PNG was reached.

Worker 098 recovered the exact original observation at `campaign/evidence/098/studio-export/recovered-data/original-062.txt`: category `UICTContentSizeCategoryAccessibilityXXXL`; expected UIFont size **55.0**; AX frame **(30.0, 454.99751790364644, 253.0, 195.66666666666663)**; NSString required height at that width **196.904296875**; display scale **3.0**. The source title is exactly **“Start your first portrait”**, `.title3.weight(.semibold)`, vertically fixed to its ideal size, with no fixed height or line limit. The arithmetic independently reproduces 587 and 591.

098 also recovered the original 1,753,321-byte screen recording, SHA-256 `55348a673f5ac47d4fdc47e2f2889ec186d788f8673b33c34983b001006a047f`. I decoded/viewed its final frame at source timestamp 112.58 seconds. The entire title is visible on three lines—“Start your” / “first” / “portrait”—without ellipsis or visibly cut glyphs. This is **video-derived evidence, not an original XCTest screenshot attachment**. Receipt, derivation command, hashes and image are retained under `campaign/evidence/061/followup-title/`.

## Cause assessment and narrow candidate

The original helper assumed the AX StaticText rectangle was the actual SwiftUI Text layout and compared it to NSString line-layout metrics. Unlike the existing recorded-Text path, it never observed the intrinsic Text rectangle. The raw numeric result plus complete visible title support an observer mismatch hypothesis; **they do not establish the exact intrinsic-height difference or a proven product fix**. No padding, font or line-spacing change is justified by the available evidence.

The candidate attaches the existing gated `studioTextLayoutProbe` immediately after font/fixedSize and before expanding frame, plus its tagged value transport. Release and ordinary launches retain the existing no-op gating. The test opts in, requires a valid current tagged frame, retains semantic/viewport assertions, and applies the **same** `round(observedHeight × scale) >= ceil(requiredHeight × scale)` rule using actual Text width/height. Both AX and intrinsic observations, expected font identity/metrics and pixel operands are logged and retained. Missing probe data fails closed; there is no fallback, added tolerance or parent-card measurement.

The same eight supplemental capture names remain exactly once. Welcome capture now occurs after reaching/checking the title but before the fit assertion, and observations also print to stdout. Per root request, both fixture launches additionally enable `KEYFILL_UI_TEXT_INPUT_TRACE=1` for worker 096's incoming bounded DEBUG callback diagnostics.

## Verification / recommendation

Swift 6.4.3 `swiftc -frontend -parse App/StudioWelcomeView.swift UITests/BetaAccessibilityUITests.swift` and `git diff --check` passed. Source assertions verify unchanged welcome visuals after removing the two gated modifiers, unchanged pixel inequality, method inventory, eight captures, shared probe implementation and original 28-capture workflow. Worktree is clean.

No Apple typecheck/build/UI rerun occurred here. Recommend integrating with root's recovery identifier/shard repairs and 096's trace, then executing the fresh Apple candidate. Compare both recorded rectangles and inspect the newly retained original image before deciding whether any actual layout repair is needed. All original failure evidence remains retained; no push or main edits.
