# Project metadata caption correction

## Observed evidence

The independent [current UI visual review](current-ui-visual-review.md) inspected the genuine Projects screenshot from source `ff8b683098a720b4c7abdddf212f85a79f3cfd39`, [compact artifact 14908135270](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14908135270). This correction worker also opened that original PNG. No replacement screenshot was generated or edited.

The unopened Campaign and Portrait setup light-count captions were captured as sRGB `(127,195,255)` against white, measured by the audit at **1.8829946782589502:1**. The active Editorial count/Open caption was `(127,127,127)`, measured at **4.0041069566148515:1**. The audit records exact glyph rectangles, the calculation and its raster-evidence limits. The source used hierarchical `.foregroundStyle(.secondary)` inside tinted project buttons, consistent with the observed pale-blue metadata.

PNG: `FA9B5BFF-C02F-4867-89AD-B422B48A4635.png`; SHA-256 `cf37ab71e18850f8e23c78e634901161557e595fa5f41197037dc49cf04366a7`. It is a 1206×2622 iPhone 17 Pro simulator capture of one appearance, not a device accessibility audit.

## Narrow source correction

Within `App/ProjectLibraryView.swift`'s `projectRowLabel`, the light-count/Open caption and conditional short project-ID caption now use explicit `.foregroundStyle(Color.primary)`. This chooses the semantic primary text color rather than a secondary level of the enclosing button's tint. [Apple documents `Color.primary` for primary content](https://developer.apple.com/documentation/swiftui/color/primary).

Only these two foreground-style expressions changed. Project titles and action tint, text sizes, selected status, accessibility labels/identifiers and behavior retain their previous source. Semantic color is retained instead of hardcoding a light-mode RGB value.

## Validation and remaining proof

- Swift 6.4.3 Linux syntax parsing of `App/ProjectLibraryView.swift` passed.
- The source `git diff --check` passed.
- Exact comparison with `HEAD:App/ProjectLibraryView.swift` confirmed that the complete diff consists of the two authorized metadata foreground styles within `projectRowLabel`.
- Corrected source SHA-256: `5ab206ae414aa7e861944baf69a804a56ad05548755a3d6a7907b3b7a8016d6d`.

No mirror test was added for the style expression. A new native rendering must verify the corrected caption colors and readability in light/dark appearances and accessibility settings. No new contrast ratio, native visual pass or accessibility-gate promotion is claimed. The original low-contrast screenshot and failed UI shard remain evidence.

Frozen files: `App/ProjectLibraryView.swift` and this report. No staging or commits were performed by this specialist follow-up.
