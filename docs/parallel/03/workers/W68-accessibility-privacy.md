# W68 — Accessibility/privacy wording review

**Status:** Completed bounded source review; no new scoped contract conflict observed. This is not an executed accessibility or privacy pass.

- **Worker:** `/root/wave07/w68_accessibility_privacy`; lane03, wave07, accessibility/privacy.
- **Input:** `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; private tree `/tmp/keyfill03-7f4b/workers/W68-accessibility-privacy`, clean and unchanged.
- **Assignment:** Inspect unsupported/supported-black distinctions, neutral-model limits and the selected-reference-photo boundary. No source changes.

## Findings

`ReferenceStudyPreview.swift` shows the unsupported count in text with a warning icon when the current image has unsupported pixels. CPU renderers mark invalid surfaces in a separate mask and magenta RGB; successful zero/very-small signals can quantize to black without changing that mask. `StudyImage.fromComputeRGBA` likewise uses the alpha flag, not RGB darkness. Black pixels therefore do not imply unavailable or unsupported output. `NUMERICS.md` explicitly preserves this distinction.

Missing images receive “Study unavailable” plus an explanation and Retry; named loading, paused and previous-render wording remains separate. This limited consistency check found no new conflict with the previously reviewed state contract.

Accessible image labels identify a neutral sphere/panel or mannequin bust. The Studio captions, guide, reference caption and README describe a direct-light relative diagnostic, with explicit limits on calibrated exposure/skin and person reconstruction. These inspected strings make no native-accessibility or device-validation claim.

Reference selection uses `PhotosPicker`, `loadTransferable(ReferencePhoto.self)`, a bounded temporary-file reader and a metadata-stripped derivative. Visible privacy wording says session memory and discloses possible system iCloud retrieval; it does not promise an entirely offline provider. This is source-boundary consistency only.

## Evidence and limits

Executed read/search inspection, HEAD/clean-tree checks and SHA-256 hashing; checks and hashes are in `wave07-evidence/W68-accessibility-privacy.json`. One oversized tool response was truncated; targeted follow-up reads recovered the relevant source sections. No new execution failure occurred.

No tests, builds, native UI/AX, VoiceOver, photo import, network observation, physical calibration or device checks ran. W62/W64 findings were supplied context, not rerun evidence. Token counter unavailable; the 12k target and 60% checkpoint cannot be measured here. No follow-up expansion recommended from this bounded review.
