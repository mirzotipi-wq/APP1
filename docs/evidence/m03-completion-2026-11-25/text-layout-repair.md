# Leaf-button text-layout repair

## Observed failure

Required source `75e827f2ee3f99798d619aff62f3a5188b509428` failed its app accessibility workflow in [run 45751931160](https://github.com/mirzotipi-wq/APP1/actions/runs/45751931160). The original full hierarchy shows Save, Cancel and Done as leaf accessibility Buttons. Their visible text is part of each Button's label; there is no child StaticText element for the previous query to measure. Save's label, enabled state, hittability, minimum 44-point bounds and viewport containment had already passed.

The original failed outcome, eleven PNGs, two hierarchy attachments, full logs and independent archive receipts remain in [the source-specific packet](validation/source-75e827f/app-accessibility/original-review.json). This repair does not reinterpret that execution as a pass.

## Source changes

`StudioTextLayoutDiagnostics.swift` records the real intrinsic SwiftUI Text rectangle through an invisible, noninteractive GeometryReader background and PreferenceKey. The probe is applied after the actual font and fixed-size modifiers and before expanding frames or padding. The owning Button carries the result as an explicitly tagged `DEBUG_UI_TEXT_LAYOUT_V1:` JSON diagnostic value. It does not create a synthetic accessibility text child or derive a rectangle from the expected font.

Instrumentation requires a Debug build, `-ui-testing`, and `KEYFILL_UI_TEXT_LAYOUT_PROBES=1`. Only the required app accessibility workflow enables that flag. Ordinary launches, other functional UI methods, opt-in platform audits and Release builds preserve normal values and grouping.

The UI consumer checks the actual control label, enabled/hittable state, 44-point minimum, owner and viewport containment. It separately checks the recorded Text rectangle against its owner and viewport and applies the same UIFont line-box minimum at physical-pixel precision. The existing StaticText helper, control helper, viewport calculations and twelve captures per text size are unchanged. Done retains the 1.25 text-height growth requirement; Save and Cancel gain the same requirement.

## New native regressions

Three methods bring the prospective required native inventory from 134 to 137. The required UI inventory remains 35.

- Exact launch gating, fractional geometry round trip, and malformed/mismatched/pending record rejection.
- A foreground-hosted Default/AXXXL fixture comparing the actual SwiftUI Text rectangle against independent UIKit screen conversion. An 8-point title inside a 300-by-100-point Button must fail text metrics even though the parent would pass.
- A foreground-hosted baseline versus disabled-probe comparison requiring a real single accessible Button with unchanged label, value, traits and text geometry. An empty accessibility traversal fails.

## Validation status at integration

The implementation and independent source reviews found no concrete source blocker. No compiler, native runtime, UI workflow or new screenshot result was available at integration. Real sheet coordinate alignment, preference propagation and native accessibility enumeration remain requirements for actual execution.

Full CI must execute the 137 native methods, all 35 required UI methods, the unchanged portable/core/tooling/build/Metal/persistence checks, and all 24 original Default/AXXXL captures. The separate large-library relaunch and studio/export failures also remain required. M03 stays active until those checks pass. M04–M07 are unchanged and pending.
