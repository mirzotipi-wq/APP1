# Source 9 room and precision: actual visual and accessibility evidence

Reviewed by the integration lead during the 2026-11-24 session. Exact source is `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`, [workflow 45377378521](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521), room/precision job `138390492826`. Its completed **5/5 UI scenarios, zero failures**, are recorded independently in [the complete job log](3b2a4ce-room-job.log). This review concerns three actual screenshots and two text attachments, not every screen or interaction.

## Provenance

The lead downloaded compact artifact **14914553792**, checked its **1,616,532-byte** size and SHA-256 `fb64d2ec9d8f3a23a95218425e3f3e246410dc7e08ab6e8300121c2f2f4a4b3f`, and verified ZIP CRCs. Its original manifest associates the retained attachments with the actual room/precision methods on **iPhone 17 Pro**. The selected PNGs and text files are retained byte-for-byte, with readable filenames. [Provenance and original-to-retained mapping](source9-room-visual/provenance.json), [original manifest](source9-room-visual/original-manifest.json).

The original compact artifact also contains two screenshots not visually assessed in this report. They are not represented as reviewed. No synthetic image, redraw, crop, altered screenshot or reconstructed accessibility hierarchy is used.

## Observed results

| Actual attachment | Observation | Limit |
| --- | --- | --- |
| [Room notes](source9-room-visual/room-notes.png) | The visible note records the committed **2.00 m** width, **7.00 m** depth, subject X **1.4999 m**, Z **2.00 m**, rotation **0°**, and **3 of 5** centers outside. Text wraps within the sheet. The share control is visible. | The screenshot does not execute a share destination or establish provider behavior. The remaining note continues below the scroll viewport. |
| [Signed coordinate](source9-room-visual/room-signed-coordinate.png) | The Key entry visibly reads **−0.0001 m** from the left wall and explicitly says it is outside. Subject/camera coordinates remain **1.4999 m**. This preserves the sign and nonzero sub-millimeter value instead of displaying zero. | Display precision is not physical measurement accuracy. No room sensing or AR trial occurred. |
| [Modifier crossing](source9-room-visual/modifier-crossing.png) | The summary simultaneously states **all 5 center positions inside** and **1 rectangular modifier crosses a wall**. Both pieces of information are visible, consistent with the distinction between center placement and projected emitting-face extent. | The image does not validate stands, housings, cables, ceiling clearance or general collision detection. |

The actual [six-meter accessibility attachment](source9-room-visual/room-notes-six-meter-ax.txt) contains the full note label with **6.00 m** width, **7.00 m** depth, subject offset **3.00 m / 2.00 m**, and zero of five centers outside. The later [two-meter attachment](source9-room-visual/room-notes-two-meter-ax.txt) contains the changed committed values, three outside centers, and the Key coordinate **−0.0001 m**. Both record the observed element type, value and frame. These are retrieved XCTest observations; they are not a transcription inferred from screenshots.

This supplies actual source-9 evidence for the previously corrected room-notes label and signed-number presentation. It does not explain the earlier source-8 initial-status failure. Source 9 passed before source 10 introduced its additional explicit status-label contract and raw-log diagnostics; the later changes must not be credited for these results.

## Remaining acceptance

Source-10 asynchronous save/load, initial readiness and subsequent room interactions still require their own native execution. This three-screen review is not a VoiceOver speech audit, Dynamic Type matrix, contrast audit, dark-mode review, physical-device usability review or release approval. Actual share/open, physical placement accuracy and the documented room/model limitations remain separate gates. The independent [library visual review](source9-library-visual-review.md) also retains the distinct plan-caption overlap under KF-036.
