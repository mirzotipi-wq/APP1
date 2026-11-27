# W57 consumer — wave06

Actual canonical/runtime ID: `/root/wave06/w57_consumer`; role: lane03 consumer specialist. Input: `74f7584b4e474c752ec0939add6b7522ba98094f`.

Private tree: `/tmp/keyfill03-7f4b/workers/W57-consumer`. Output: `/tmp/keyfill03-7f4b/builds/W57-consumer`. Report destination: `docs/parallel/03/workers/W57-consumer.md`.

**Status: bounded source review complete; no supported-flow NaN witness found. No source change recommended.**

Exactly two app callers were found: `StudioView.swift:504` and `ReferenceComparisonView.swift:261`. Studio starts with finite portrait constants; numeric setters check finite/isValid, drag adoption checks Position validity, and replacement scenes pass `validated()`. Library loads/migration and project-document decode validate scenes. GuidedLighting validates its source and each returned candidate before comparison preview selection. Lens, optics and preview-setting validators reject nonfinite values. Undo/redo restore the editor's prior snapshots.

Request removes `placementRoom` from both snapshot and equality. Room changes already require valid room values and cannot introduce NaN into request identity. Its remaining scene values stay finite through the traced app paths.

W53's conditional mechanism remains credible for arbitrary invalid construction, e.g. `scene.camera.x = .nan`: synthesized equality is nonreflexive, so the stored error may fail the matching-request display condition. This is not a demonstrated supported app flow. Finite rendering-invalid geometry does not have that NaN equality defect. Keep this wave limited to paused UI and cancelled begin/task guards; do not canonicalize UI identity without a reachable witness.

**Evidence:** pinned GitHub reads used the assigned account/repository. Key blobs: preview `4b1e283efcb65e890e439c05cacd93fdac293a41`; Scene `0825a683a221da4fd72f11cea9e697f8e0a481ae`; GuidedLighting `484198fd05bfd55b59fe0b4c8c24b7cb55a5ec72`. Full hashes and local comparison are in `source-provenance.json`; raw local output is in `verification.txt`. Read lane04 OWNER_REQUESTS blob `7ff42021d0e4f2166b8750c233474083bbc26d79`; its routing guards require no consumer/engine change here.

**Actually ran:** read-only remote source review; after recovery, local `git rev-parse HEAD` and focused `rg` caller/validator/history inspection. No Swift build, unit/UI test, render, benchmark or device check ran. No commits, refs, pushes or external messages. Initial tool-display truncation was resolved with focused excerpts. The pre-outage tree was unavailable and lost; the recreated tree was subsequently verified at the input SHA. This is source evidence, not an executed acceptance pass.
