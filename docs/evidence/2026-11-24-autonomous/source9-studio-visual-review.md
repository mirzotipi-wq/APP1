# Source 9 export screens and failed optics boundary

Exact source: `3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`. [Workflow 45377378521](https://github.com/mirzotipi-wq/APP1/actions/runs/45377378521), studio/export job `138390492855`. These are genuine iPhone 17 Pro simulator captures from the executed UI scenarios, not generated mockups. The [provenance record](source9-studio-visual/provenance.json) records original filenames, byte counts and SHA-256s. The full compact ZIP was downloaded, matched its reported 2,423,568-byte size and SHA-256, and passed ZIP CRC verification.

## Actual visual inspection

Root opened the two original 1206×2622 PNGs with the image viewer. The [lighting-plan preview](source9-studio-visual/lighting-plan-preview.png) shows the US Letter/meters selectors, first page of the two-page plan, subject/camera/light diagram, units and modeling limits, the page count, Done, and the Share PDF action. No clipping or overlap is visible in that captured sheet. This is one rendered preview page; the earlier native PDF review supplies separate multipage evidence.

The [full-library editable-copy screen](source9-studio-visual/full-library-editable-copy.png) shows the unsaved Portrait setup snapshot with four lights, the save-copy action, subsequent import guidance, and the exclusions for reference photos, room measurements and edit history. The text and action fit the captured viewport. The actual scenario passed at the 64-project limit without saving or altering current history. Neither screenshot proves a successful external Files/provider transfer, printing, VoiceOver operation or a physical-device layout.

The [original attachment manifest](source9-studio-visual/original-manifest.json) also lists five other successful-scenario screenshots and the failed optics recording/event attachments. This review does not claim visual inspection of those five other PNGs. The compact archive contains no optics-failure PNG; the full artifact retains the recording and event attachments.

## Failed history interaction remains open

The complete [native result report](native-result-3b2a4ce.md) and [raw studio log](3b2a4ce-studio-job.log) record 8/9 studio/export passes and the original optics Undo assertion failure: expected 0.6 m, observed 1.3 m. Across all three UI shards, the result is 21/22. Both export scenarios passed; the whole workflow failed.

Subsequent bounded extraction from full artifact `14915129098` recovered the original optics screen recording and synthesized-event attachment. The event archive describes one pointer path named `press, hold, drag, and hold`, with four pointer events; it does not describe repeated accessibility increments. Root and a separate reviewer inspected eighteen sampled video frames: width begins at 0.6 m, changes during the drag, and later shows 1.3 m while both history arrows appear gray. This motivates checking an unfinished edit and an ineffective tap on disabled Undo. It does not establish the internal SwiftUI value/begin/end callback order or prove that an Undo command actually executed. No failed assertion or historical evidence is removed. The bounded diagnostic and native tracking correction are separate ongoing work, not a source-9 pass.
