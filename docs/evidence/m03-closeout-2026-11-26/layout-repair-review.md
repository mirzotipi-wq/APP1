# Reviewed layout and fixture repair

This follow-up responds to actual source `9faebc529ff434feef8995d0a565d2ee04e98c13` evidence in [run 45796521392](https://github.com/mirzotipi-wq/APP1/actions/runs/45796521392). The five-file change is published as [`f150f98`](https://github.com/mirzotipi-wq/APP1/commit/f150f98e35dd735927075aac4d2f8b02295c6a67) and is executing in [run 45805136256](https://github.com/mirzotipi-wq/APP1/actions/runs/45805136256); fresh Apple execution and original screenshot review remain required.

## Observed failures and decisions

- The native hosted probe passed exact physical-pixel equivalence, font fit, adjacent representable widths, Dynamic Type growth, undersized-text rejection and the one-pixel-short negative control. One Default raw rectangle started at `19.999999999999996` while its control began at `20`, failing strict containment. The fixture now adds one point of padding **after both actual Text observers**, before the unchanged 300 × 100 control frame. No recorded Text size or containment/pixel assertion is inflated or relaxed. Worker 005 independently approved the actual diff.
- The actual largest-size Plan screenshot shows Scene and Meter compressed into fragmented vertical text columns. The header now places Scene above its actions at accessibility sizes. The actions use a horizontal row when it fits and a vertical fallback otherwise. Existing labels, actions, enablement and 44-point targets remain intact. Worker 002 implemented the change; worker 093 independently reviewed it.
- The largest-size selected-light caption measured 460 physical pixels against the independent minimum of 462. Its original screenshot shows all words, so it does not prove glyph clipping. One point of actual interline spacing is added to that Text, retaining the original font, width-constrained minimum fit and physical-pixel rule.
- The longer body-semibold Save project name title has only Default runtime evidence so far. Its largest-size wrapping is an inferred exposure, not an observed failure. Native evidence measures the complete largest body line at 63.248046875 points. Apple's [typography specifications](https://developer.apple.com/design/human-interface-guidelines/typography) give the largest body style a 53-point size and 62-point baseline spacing. Two points of actual interline spacing are added to this title before its intrinsic probe. The shared minimum-fit oracle is unchanged.

## New checks retain existing acceptance

The required two-size workflow observes the whole header, actual Scene text, actual Meter Text, their semantic controls and reachability. Both titles join the existing growth checks. The new upper-height assertion measures a one-line NSString rectangle at unconstrained width with the matching font style and weight, excluding optional font leading. This avoids conflating baseline spacing with a complete single-line glyph box. The separate width-constrained minimum-fit checks remain unchanged.

The Meter probe is attached to the Text before surrounding Label padding and button expansion. Its visible title remains Meter; its independently checked accessibility label remains Open light meter and test card. Existing callers of the measurement helper retain their previous behavior.

The workflow preserves all 26 existing original captures and adds Default-Workspace-header and AXXXL-Workspace-header: **28 total**. Native and required UI inventories remain **154 and 35**. No test, numerical threshold, negative control, growth requirement or old screenshot is removed. The two optional platform diagnostics remain separate.

## Validation and limits

[Local checks](layout-repair-local-checks.json) record successful Swift syntax parsing, YAML parsing, exact inventory/capture agreement and clean diff formatting. These checks do not type-check Apple SDK APIs or establish runtime layout. Existing worker 001 also verified 109 portable inputs and the renderer integration remain unchanged, supporting continued M02 acceptance while new native/UI evidence is collected. Save's added spacing is proactive; the caption and header findings are observed. Final acceptance requires the complete commands, exact method accounting, original screenshot bytes and actual image review on the newly published source.
