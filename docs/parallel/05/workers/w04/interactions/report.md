# Lane05 wave04 — interactions

**Canonical worker:** `/root/w04_acceptance/interactions`  
**Frozen input:** `9725fb1177a5c7afbdf798ffd627e65e604c75b1`

Read pinned `AGENTS.md`, architecture, design, M02/M03 code acceptance, both preview adapters, viewport geometry, and relevant native test sources using `git show`. Repository files/commits changed: **none**.

## Actual checks and outcomes

Executed `python3 /tmp/keyfill05-be879deb/waves/w04/interactions/witness.py`; exit **0**. It reads three pinned source blobs, checks 21 implementation snippets, and reports their SHA256 values. This is a Python transcription plus independent camera-basis projection, not execution of Swift or native adapters.

- **Pan:** 144 projection cases across six yaw/pitch pairs, three portrait/landscape sizes, four signed drags, and centered/off-center fixed subjects at target depth. Camera right/up are reconstructed from position/target using cross products. UIKit-positive X/Y move the fixed subject right/down by the requested point delta; maximum error **5.684341886080802e-14 points**. Distance remains unchanged. Cases avoid target clamping.
- **Orbit/zoom/Fit:** six orbit cases preserve target and radius while applying yaw subtraction/pitch addition; two pitch-limit cases pass. Pinch scales 1.2/2 reduce RealityKit distance from 7 m to 5.833333333333334/3.5 m; scale 0.5 produces 14 m; extremes reach 0.45/1500 m bounds. Incremental factors compose correctly. Explicit Fit restores bounds center, yaw **0.56**, pitch **0.36**, and the radius-derived clamped distance.
- **Fit tokens:** source review and predicate witnesses agree. RealityKit defers its initial fit until valid layout, consumes a changed token once, and keeps pose through same-token metadata/layout updates; modeled fit counts **0,1,1,1,1,2,2**. SceneKit's stable orbit-mode predicate rejects repeated tokens and accepts a changed token; layout changes projection axis only. Initial/pending fit and SceneKit mode changes are separate triggers. SceneKit Fit reconstructs the shared orbit pose and controller target.
- **Production increments:** RealityKit orbit/pan read translation then reset to zero; zoom reads scale then resets to one; handlers consume began/changed states. SceneKit retains framework gestures; its pinch is not asserted to implement RealityKit distance zoom.

**Outcome:** no defect found in the sampled math or valid, stable orbit-mode Fit flow. No build, native interaction, rendering, toolchain, or XCTest execution claimed. Historical 171/25 passing and 176/30 discovered counts were not rerun; the separate recovery fix and its tests are outside this input/review.

**Artifacts:** this report and adjacent `witness.py`; no other outputs or commits.
