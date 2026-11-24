# Product, visual and accessibility review

## Scope and evidence boundary

This is an independent agent review of the product workflows, current source and two genuine historical simulator screenshots. It is not a photographer/customer interview, a human accessibility audit or physical-device verification. No quality score or release gate is promoted.

The source baseline is `0fce248b4e61bace88002b40f6c56fddedb19c8a` on main, with the pending integrated performance/history/visible-identity packet present. The review read `AGENTS.md`, the operating protocol, product/architecture/design/roadmap/quality contracts, current state/handoff and README. `agent_cycle.py check` passed and `next` retained M01 as the first unresolved milestone. These script results validate record structure and ordering, not product behavior.

The two images below were actually opened and visually inspected. Their manifest identifies an iPhone 17 Pro simulator in historical run [45346996294](https://github.com/mirzotipi-wq/APP1/actions/runs/45346996294), source `cab674175233249e8785797d283e414da23765fd`. They do not depict the current editable-copy, room-note, visible-name or guided-basis changes.

| Historical attachment | Actual observation | Limits |
| --- | --- | --- |
| `10EA14D5-89F9-4569-8A20-DCC37E726D97.png`, Reference comparison empty state | The title, Choose photo action and empty-reference explanation are visible. The reference and actual rendered sphere study are stacked on the compact viewport. The visible preview is explicitly labeled direct-light-only and uncalibrated. The beginning of the guided section lies below the preview. | No selected-photo, replacement, error, guided-basis or larger-text state is shown. The screenshot does not prove gesture reachability, screen-reader order, contrast conformance or current rendering. |
| `65585215-C578-4978-B7D3-5548FB9DD1FB.png`, Project library | Campaign, Editorial and Portrait setup labels are visible. Editorial has both a checkmark and the word Open, so its selected status is not conveyed only by color. Project options and New project appear in the list. | No full-capacity, archive deletion, import, invisible-name, dirty-save or recovery state is shown. No current layout or accessibility pass follows from this image. |

Image SHA-256 values are `0ee61647adc5d675cbb2415382ba29b2837be537a4007bbd89eaca004afcd8d0` and `62b5d8a1f667e613d47c3fe2cd9c5ffc2082fe939e2ef0fb19036a48d90db981`, respectively. The manifest associates them with the actual project create/duplicate/rename/relaunch and empty-reference UI tests. Historical evidence was supplied by the integration lead and its local image contents were inspected directly by this reviewer.

## Demonstrated correction needed: sub-micrometer numeric readouts

**P2 — a valid nonzero exact value can be displayed and announced as zero.** `StudioNumericInput.parse` accepts finer decimal input, and `PrecisionValueEditor` shows up to twelve decimals and correctly preserves untouched imported values. However, `StudioNumericInput.formattedValue` always uses at most six fractional digits. `PrecisionValueButton` and the camera/light/optics/meter slider accessibility values consume that helper.

A standalone Swift probe compiled the actual current helper, without modifying it or invoking the shared SwiftPM build lane. The observed output was:

```text
input=0.0000001 stored=1e-07 readout=0 m
input=-0.0000001 stored=-1e-07 readout=-0 m
input=1.23456789 stored=1.23456789 readout=1.234568 m
input=0.000001 stored=1e-06 readout=0.000001 m
```

The first two cases establish the defect without relying on a native-layout hypothesis. No stored value is lost, but the visible and spoken control value misrepresents its sign/magnitude at this boundary. Claims of exact spoken values must therefore remain bounded by the actual formatting behavior until corrected. A meter-scale coordinate this small is not a claim of physically achievable placement precision; the defect concerns faithful presentation of accepted numerical data.

Recommended correction: use one bounded, locale-aware representation that does not convert nonzero to zero, preserves sign, and has an explicit rule for values beyond ordinary decimal display. Preserve the existing strict input grammar and untouched-value protection. Verify positive/negative tiny inputs, normal exact decimals, zero, localized separators/digits, and extreme finite imported values. Do not produce an unbounded hundreds-of-digits label as a side effect of accepting arbitrary finite Doubles. Native VoiceOver pronunciation still needs a device check after a portable formatting correction.

The finding was sent to the integration lead before any source edit. This reviewer changed no production code. The helper source hash was `1e12c4d5b0a9ba73ee90b56bf3f7f263bdb9b97aa7e6a5be4b553f5d2de14cfd`; raw probe output hash was `7068bd723d4b4dfe7b7bbad449f917c5b720e7cfe3cd904c5eb4c670c7ee150b`. Scratch files are under `verification/product-accessibility/` in the active workspace.

Reproduction source:

```swift
import Foundation
@main struct NumericReadoutProbe {
    static func main() {
        let locale = Locale(identifier: "en_US")
        for text in ["0.0000001", "-0.0000001", "1.23456789", "0.000001"] {
            guard let value = StudioNumericInput.parse(text, in: -100...100) else {
                print("REJECTED \(text)")
                continue
            }
            print("input=\(text) stored=\(value) readout=\(StudioNumericInput.formattedValue(value, unit: "m", locale: locale))")
        }
    }
}
```

Compile with `swiftc Sources/LightingCore/StudioNumericInput.swift NumericReadoutProbe.swift -o numeric-probe`, then run `./numeric-probe`. Actual environment was Swift 6.4.3 on Debian 13 x86_64. These are four direct probe cases, not four XCTest methods or VoiceOver executions.

## Demonstrated wording inconsistency

**P3 — the README opening describes AR placement as a current capability.** Its first paragraph says the app lets users “place equipment in a real room using AR.” The next paragraph accurately says AR tracking is not implemented. The source has a manual measurement view, and the protected product contract places actual AR in the first-release target. A concise opening should describe the implemented manual measurement workflow, leaving AR as an explicitly planned capability. This is documentation consistency, not a request to weaken the product contract or mark M05 complete. The integration lead owns the README and was notified; no README edit was made by this reviewer.

## Current workflow review

| Workflow | Source-supported behavior | Remaining evidence or deficiency |
| --- | --- | --- |
| Editable project copy | The Export action captures name/scene into an immutable snapshot. The sheet distinguishes an editable file from an app-library save, names the omitted reference/room/history data, and reports success only through the exporter completion. It remains available for dirty edits and a full library. | System destination selection, cancellation, saved-file reopening and provider behavior need native execution. A prepared document or enabled button is not evidence of a successful external save. |
| Full-capacity recovery | The capacity sheet identifies a selected archived record and asks for destructive confirmation. It explains that capacity is checked again and no record is removed if a slot opened. With no archive, it directs the user to the editable-copy path. | Actual cancellation, candidate identity, external changes and relaunch need current native coverage. The file copy must remain reachable before any action that discards the current editor. |
| Import into Projects | The UI disables import while dirty/unavailable/full, names the 64-project bound and routes mutation through the existing save boundary. Successful import says it creates a new project. Existing project labels include short identity when their display is sanitized or truncated. | Actual Files picker lifecycle, cancellation, provider delay and conflict feedback need current native execution. Duplicate envelope-key handling is separately under corrective review. |
| Guided alternatives | Categorical observations are shown separately from unknown cues and chosen distance/angle/lux/K values. The view says these are manually guided starting rigs, not automatic analysis. Apply explicitly changes lights, offers Undo and does not promise an automatic save. | No held-out inverse-inference or practical reconstruction score exists. A real photographer must assess whether users can select cues and refine a useful arrangement. |
| Reference privacy and retention | Source wording now says the reduced copy omits original photo metadata, acknowledges possible system iCloud retrieval and describes session-only retention. Replacement cancellation retains the prior comparison state. | Actual Photos/Files permissions, network behavior, app-switcher concealment and deletion need native/device evidence; releasing references is not secure-zeroing proof. |
| Manual room notes | The layout summary appears before editable fields. Notes capture the committed plan, state that Set is required for drafts, and share exactly the reviewable snapshot. The view discloses session-only room settings and limits checks to centers/projected emitting faces. | Current resizing/share UI and actual exported text need native review. Physical accuracy, real housing/stand clearance and AR are not established. |
| Visible legacy identities | The pending correction supplies Unnamed project or numbered Light labels in active studio, backup, import confirmation, room and report contexts. Persisted names and editable-document data stay intact. | The earlier empty-label defect has a narrow source correction and portable regressions, but current VoiceOver, PDF layout and long-name rendering remain unverified. |
| Exact editing and history | Numeric entry has explicit Apply/Cancel, validity checking and an untouched-input guard. History now captures project/control ownership and force-closes at documented lifecycle boundaries. | Numeric readout defect above remains until separately corrected. Same-control overlapping event generations and actual interrupted native gestures need execution. |

## Design and accessibility assessment

The historical screenshots show a readable native list/reference hierarchy at one captured size, with useful empty states and visible selection text. Current source extends that approach through named loading/error states, minimum-height action targets, selection traits, explicit units, contextual labels and review-before-share flows. These are inspectable implementation choices, not a complete accessibility pass.

The highest-value outstanding checks are the actual reading order and target reachability at accessibility text sizes, especially the Reference photo action row, nested sheets and project archive/recovery controls; clear focus after invalid exact entry and after returning from system pickers; and spoken pronunciation of precise localized values. The source's compact HStack arrangements warrant testing, but no clipping or minimum-target failure is asserted without a corresponding native observation.

For a paying photographer, the major product limits remain calibrated portrait/material rendering, a real equipment model, robust on-device reference workflow validation, useful held-out reconstruction evaluation, physical AR, durable room workflow expectations, complete StoreKit behavior and customer testing. No source-count, simulator screenshot or numeric probe supports awarding the aspirational 95/100 score. Preserve all protected gates, the pre-alpha status and explicit human/device review requirements.

## Review result

One reproducible numerical readout defect and one concrete documentation inconsistency were sent to the lead for correction. No additional source-demonstrated P0/P1 defect was established in the reviewed new workflows. Historical visuals were inspected, current source paths were reviewed, and the small numerical reproduction was actually executed. Native interaction, physical accessibility, customer desirability, calibrated rendering and release readiness remain unverified.
