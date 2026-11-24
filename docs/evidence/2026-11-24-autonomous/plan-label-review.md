# KF-036 plan-caption candidate — independent integration review

**Decision: approve the corrected, frozen candidate for root integration and subsequent native verification.** No remaining concrete source blocker was found. This is approval of the scoped implementation, not closure of KF-036 or a native accessibility/visual gate. The integrated recovery screenshot, native text metrics, large-text/narrow-view states, touch targets and VoiceOver behavior remain to be verified.

Reviewed on 2026-11-24 by the reused `/root/w09_ios_critical_review` specialist. The review was read-only except for this document. No source changes, tests, compilation, benchmarks, staging, commits or new agents were performed by the reviewer. The author is the existing `/root/w01_native_design_audit`; root made the single copy correction described below.

## Source boundary and exact hashes

Candidate base: **`5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`**. The live `App/StudioView.swift` still has SHA-256 **`bda97eb61f0525607f5c94a819dd4d5b28b4cd5b1f67f0d85728bff7e7e2da36`** and exactly matches that base. All three new candidate files remain absent from the live tree at review completion. The [narrow patch](plan-label-studio-view.patch) has four hunks, and its body was independently compared with the exact current-live-to-candidate diff; they match. It contains no library-operation, storage, history, scene-adoption or slider edits.

| Frozen candidate file | SHA-256 |
| --- | --- |
| [App/StudioView.swift](../../../App/StudioView.swift) | `525dafe2362dc8d43232082a4e93b6a85d8e9b7901cda75c00459f79bd2594a6` |
| [App/StudioPlanMarkers.swift](../../../App/StudioPlanMarkers.swift) | `13829b9599d23e01dd40dc720e504dc991a58167c4710b7c61114cbf655fd51f` |
| [Sources/LightingCore/StudioPlanLabelLayout.swift](../../../Sources/LightingCore/StudioPlanLabelLayout.swift) | `3b77ad53e9f0e9d7621267fd3a1466a4abc852a18e5591c0b9b18ffea268c2ae` |
| [Tests/LightingCoreTests/StudioPlanLabelLayoutTests.swift](../../../Tests/LightingCoreTests/StudioPlanLabelLayoutTests.swift) | `892179fcddbf1e6523295f053243a8699fcd59842dacfff47f3d25d16f7118c1` |

The corrected [manifest](plan-label-manifest.json) hash is **`5c1e5672a3dc8bf74c76226321cc751ed828ab0f27d97651f6aa925db091fbac`**. Patch hash: **`52ae546e0fd90c00e6dc8c5eae1204c4ac29ed6b2458fc536cd1cae096024b8e`**. All four source hashes were independently verified after root's correction. Integration should retain this exact source boundary; a changed live StudioView requires applying/reviewing the narrow hunks rather than overwriting later work.

## Finding corrected during review

The initial notice promised that the light list would supply “full names.” The existing rack also calls `lightDisplayName`, which applies `StudioDisplayName`'s 80-character, 320-scalar and 1,280-byte bounds. An overlong legacy name therefore remains bounded/truncated in that list; it is not a raw-name escape hatch.

Root corrected the candidate notice to **“Use the light list below to select lights in crowded positions.”** The selected bounded name still wraps below the viewport, and a short light ID appears when that safe display label differs from the retained stored name. This is accurate fallback behavior without rendering unbounded legacy text or renaming data. The focused tests predate this copy-only correction; no additional execution is claimed. Any “full-name fallback” wording in author evidence means this bounded selected-name display, not arbitrary retained raw text.

## Layout and interaction review

**Projected centers and touch regions.** The existing world bounds, overhead fit, `point` projection, camera cone, modifier footprints and aim lines are unchanged. The new 34-point symbol is centered within a fixed 44 × 44-point control, and that control is positioned at the original projected anchor. Captions are separate siblings, so caption height no longer moves the equipment icon away from its world coordinate. The pure helper independently exposes 44-point marker rectangles with the same centers. Ordinary viewport padding keeps these controls inside the current plan; the tiny-canvas test only proves finite geometry and omission, not that a one-point canvas can expose a 44-point hit target.

**Collision and fallback behavior.** The helper accepts at most fourteen markers, matching subject, camera and the scene's twelve-light limit. It tries eight nearby positions and a fixed 9 × 7 search, with deterministic distance ties. Every accepted caption stays inside the margins/header reserve and avoids every marker rectangle and previously placed caption by four points. Selected captions receive priority. If a caption cannot fit, it remains absent and triggers the notice; no equipment center is moved to manufacture room. Coincident controls remain coincident, the selected symbol draws above the others, and the existing light list supplies selection of crowded lights. This is bounded greedy placement, not a proof of optimal packing.

**Leaders and drawing order.** Leader lines connect each anchor to its caption rectangle, beneath caption backgrounds and marker controls. Their endpoints identify the actual equipment position; they do not mutate scene geometry. The implementation does not route leaders around all other geometry, and the tests do not establish ideal leader-line legibility in every dense scene. Actual native images must assess that remaining visual question.

**Text measurement and padding.** A single `@ScaledMetric(relativeTo: .caption2)` point size feeds both UIFont measurement and explicit SwiftUI system-font rendering. Caption weight is semibold on both paths; the header uses the same scaled size and monospaced medium weight on both paths. Measurement rounds up to display pixels, adds eight horizontal and four vertical points, and caps the total single-line caption width at 128 points or the available viewport width. Drawing subtracts exactly those amounts before reapplying padding, so the rectangle supplied to the collision helper is also the intended capsule frame. No source-level double application of Dynamic Type or padding mismatch was found.

The header's measured height plus padding is reserved for captions. That does not move projected equipment away from the header. Large-text/header/marker interaction and actual UIFont-versus-SwiftUI line heights or fallback glyphs remain native inspection requirements. The portable tests supply dimensions; they do not measure Apple fonts or establish their rendered bounds. No native metric equivalence is claimed by this review.

**Bounded names and selected identity.** All light names supplied to native text measurement and drawing come from the existing bounded `lightDisplayName` function; subject and camera names are fixed strings. Stored names are untouched. Long single-line captions can truncate, but the selected safe display name wraps outside the viewport instead of squeezing the control or shifting its center. Contextual fallback labels continue to handle names with no visible content. A changed legacy display label also exposes the short light ID. The fallback remains bounded by design.

**Selection, accessibility and ownership.** Captions and leader Canvas are noninteractive and accessibility-hidden. Each light retains its “Select … on plan” button label and selected trait; selection invokes the unchanged generation-aware `sceneAction` wrapper. The camera button retains its action and `editCamera` identifier. The subject remains labeled. The 44-point content shape belongs to the control rather than to a displaced caption. Existing light-list actions and identifiers remain intact. These are source facts; actual VoiceOver ordering, focus, frame exposure and touch delivery require native execution.

The new preference/state value only controls explanatory UI below the plan. It does not alter the scene, selection, library receipt, edit generation or history. The exact StudioView diff leaves the async persistence guards and scene callbacks intact. No stale-owner or cross-project mutation path was introduced by these four hunks.

## Actual verification inspected

The reviewer read both raw logs, all six focused test methods, the four source files, author report, manifest and patch. No tests were rerun because no remaining algorithmic counterexample was identified.

| Evidence | Actual result | Limit |
| --- | --- | --- |
| [layout-debug.log](plan-label-debug.log) | 6 XCTest methods passed, zero failures | Isolated minimal package containing the layout helper/tests |
| [layout-release.log](plan-label-release.log) | 6 XCTest methods passed, zero failures | Same focused package; not the full application suite |
| [native-parse.log](plan-label-native-parse.log) and [author command record](plan-label-author.md) | Parser success reported; raw output is empty | Linux syntax parsing is not Apple SDK type checking or native execution |
| Current source/manifest/patch comparison | All source hashes and exact diff match | Read-only integrity verification, not an integrated build |

Debug log SHA-256: **`d0cc3a9c1a5f1a030f9951d292adea9b0a917c2a5496dc614469405ae52d3617`**. Release log SHA-256: **`584bcd7674ad1a1adccfd1813175594edc702ba46c7f884de920a22c6beaa8eb`**.

The recovery regression uses the actual four-light positions and 342 × 280-point viewport with conservative supplied text dimensions. It demonstrates the old caption/icon intersection under those dimensions, then requires no omitted captions and preserves all anchors in the new layout. It does not claim UIKit measurement of the earlier screenshot. Additional tests cover sixteen narrow/large-dimension combinations, deterministic results, fourteen coincident markers with selected-caption priority, oversize-caption omission, malformed/count-bounded inputs, and tiny/empty canvases. Their geometry assertions are useful and materially exercise collision behavior; they do not certify native hit testing or Dynamic Type.

## Integration acceptance and pending evidence

Root may integrate this exact corrected packet, then run the normal integrated portable suite and actual Apple SDK checks. The project already includes the App directory and LightingCore target sources, so the new files have a defined integration path. Preserve existing selection, camera and recovery assertions.

Keep KF-036 open until genuine native output demonstrates the correction on the previously captured four-light recovery case and on narrow/large-text states. Inspect caption/marker separation, the selected-name fallback, header/leader legibility, camera and light selection, and VoiceOver access to the controls. UIKit/SwiftUI compilation, actual font metrics, native frames and physical-device accessibility remain unverified for this candidate. The source review approves integration; it does not turn those missing observations into passes.

## Evidence relocation

Root copied this review into the repository after approval and adjusted relative links only. The original frozen review SHA-256 was 49eecd7c5f40e97a02ff01b85cb04c47e2418517ef48a9a9e6af80f6e2d6182d. The reviewed source hashes above are unchanged.
