# W78 — accessibility/privacy source review

- Runtime: `/root/wave08/w78_accessibility_privacy`; parent `/root/wave08`.
- Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; tree `bba62b3555a03cdbd6dcb47a419a433d996c82f7`.
- Private tree: `/tmp/keyfill03-7f4b/workers/W78-accessibility-privacy`; clean. Assigned private outputs unused.
- Status: completed source/image/receipt review; one communication gap sent for independent challenge. No production edits or tests run.

## Finding requiring disposition

**W78-AX-01 (P2, source evidence):** `ReferenceStudyPreview.swift:117–143` retains a previous same-subject image during updating/paused states, but gates the unsupported-pixel warning on `isCurrent`. If that retained frame contains magenta invalid pixels, its text warning disappears and its previous-render accessibility label omits the unsupported count. Preserve a previous-frame-qualified invalid description while those pixels remain displayed. Native UI and VoiceOver reproduction are unrun; root owns any correction.

## Scoped conclusions

Current `invalidCamera` yields no frame, zero unsupported count and camera guidance; conversion failure, retry, updating and paused labels are distinct. Current invalid frames expose a numeric warning. Model captions describe neutral synthetic geometry without calibrated-skin/reconstruction claims. The comparison screen’s sphere caption is correct because it uses the sphere default.

Directly viewed saved rim-only, minus-two-exposure and no-light-clear PNGs; all three corresponding masks contain only zero bytes. Exhibit captions correctly distinguish darkness from unsupported pixels. Current exhibit hash `8cce8f9932fd34bf7b2b9b43c83da5f001a2d0a69c979468ca92dfcb95c79792` matches W71’s status update.

The PNG filter operates after a fresh bounded sRGB encode, retains structural/color/transparency chunks and delegates decoding/CRC validation to ImageIO. This is local-source privacy review, not import/network/permissions runtime acceptance.

Finalized run **45842899560 / job139992156576**: independently counted **164 unique native passes**, including **10 pipeline** and **7 ReferencePhoto** methods; reviewed **391 portable tests**, successful Debug/native-bundle and Release builds, and **6 actual simulator Metal fixtures**, maximum channel error **1**, with exact-mask assertions. Log SHA-256 `019f50cd8b9a949c8f5c2e7c93e79a77826cd3cd7b41a6c234c0c3b1f2ef4bf1` verified. Separate UI/accessibility shards and manual VoiceOver are not established.

Receipt: [W78-accessibility-privacy.json](wave08-evidence/W78-accessibility-privacy.json), SHA-256 `a3cc501233e618eb7220d3765db74f69feb2e29100c62b89d5ad73fbfe622c4b`; includes exact source hashes, labels, gates, image/mask hashes and accounting. Historical resets/ENOSPC remain untouched. No milestone or release promotion.
