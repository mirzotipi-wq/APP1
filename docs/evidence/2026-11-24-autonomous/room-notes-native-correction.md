# Native room-note accessibility correction

## Observed failure

At source `ff8b683098a720b4c7abdddf212f85a79f3cfd39`, [workflow 45363578829, room/precision job 138342789450](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138342789450) completed with four of five UI tests passing. All three precision scenarios passed. The room resize scenario failed at `ManualRoomPlacementUITests.swift:67` when the `roomNotesText` label did not satisfy `CONTAINS "Room width: 6.00 m"` within its existing ten-second assertion. The notes sheet had opened, and earlier assertions proved rejected width 2 preserved committed width 6 and subject X 3.

## Retrieved evidence

- [Compact artifact 14908750270](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14908750270), ZIP SHA-256 `c247e1edfc6aceeaf4dbe668960770e64216e22c0fe2555b4319da064e8307df`: downloaded and verified. Its three PNGs show successful room/precision flows; the failure recording and snapshots are listed in its manifest but omitted from the compact ZIP.
- [Full artifact 14908530980](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14908530980), ZIP SHA-256 `6e72f941b18504d78bd19e193f01ae3eb6da6d29d3232af277fcb19f19a5e255`: downloaded and verified.
- Failure recording `artifacts/native-attachments/35D59427-F6C2-45BD-9FE6-382CC6F655DD.mp4` belongs to `ManualRoomPlacementUITests/testRoomResizeRequiresExplicitSubjectMoveAndPreservesSignedCoordinates()`, iPhone 17 Pro simulator. The manifest records start timestamp 1795512888.098; the log starts that test at 09:34:48 UTC.
- A frame extracted at 128 seconds visibly displays **`Room width: 6.00 m`**, depth 7.00 m, subject X 3.00 m / Z 2.00 m, rotation 0°, and zero of five centers outside. Spaces and punctuation in the rendered width line match the asserted text. The actual visible snapshot is correct; there is no evidence that the rejected draft replaced committed measurements.
- Automatic AX snapshots `C1AC34A2-6146-4760-BF3E-BC8AB5CB7B0B` (09:37:00) and `79C1A4E0-526D-4E1D-881A-650BD0CDA29E` (09:36:46) are binary NSKeyedArchiver plists. Both contain only an application root with no child snapshots. They do not reveal the notes element's actual label, value or type. The framework-internal reason for the label mismatch is therefore **unobserved**; it is not claimed as a proven selectable-text platform behavior.

Frame reproduction from the extracted recording:

```sh
ffmpeg -v error -ss 128 -i 35D59427-F6C2-45BD-9FE6-382CC6F655DD.mp4 -frames:v 1 notes-at-failure.png
```

## Focused correction

`RoomPlacementNotesView` now explicitly supplies `accessibilityLabel(Text(verbatim: text))` from the same immutable string used for visible selectable text and the share item. This establishes an explicit content contract rather than relying on an inferred accessibility description. It does not change notes generation, number formatting, committed room values, selectable text, sharing or persistence.

The UI test keeps its exact committed-width, rejected-draft exclusion, signed-coordinate, reopened-sheet, unchanged-room and unchanged-studio assertions. Timeouts are unchanged. Every notes observation records actual element type, label and value; on failure it additionally retains a screenshot and app hierarchy. A future failure can therefore be diagnosed from actual accessibility content instead of inferring it from an empty automatic snapshot.

Apple documents explicit accessibility labels/values as available view modifiers and text selection as a separate copying interaction: [Accessibility modifiers](https://developer.apple.com/documentation/SwiftUI/View-Accessibility), [textSelection](https://developer.apple.com/documentation/swiftui/view/textselection(_:)). These references justify the explicit API usage, not a claim about the missing historical AX values.

## Verification and limits

Both edited Swift files passed `swiftc -frontend -parse`; scoped `git diff --check` passed. No current Apple SDK compilation or native rerun was available to this worker. The original UI failure remains failed evidence until a new native run proves the correction. No full-suite, sharing-provider, physical-device or VoiceOver pass is claimed.

## File provenance

Recording SHA-256 `2a6695c4995e6576da362b68b65280f69eb1c42e101d4bc5438faa90e8368bff`.

Extracted 128-second PNG SHA-256 `0f797558c45ef35d2400d0efe1dcfa4b6cb6b402d24d8db25c75403d1c99ba29`.

- `App/ManualRoomPlacementView.swift`: SHA-256 `482ab39b9831358e1f8f5752ac2b51238f3ddbc60d5acbda38bd82583c61b6b4`.
- `UITests/ManualRoomPlacementUITests.swift`: SHA-256 `4219598954145211dfbdaeb0326e3524d3db25056296cac802dbb4897e58c16e`.
