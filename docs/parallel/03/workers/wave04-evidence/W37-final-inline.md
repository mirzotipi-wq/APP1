## W37 — Consumer visual review

**Runtime ID / canonical path:** `/root/wave04/consumer`
**Parent:** `/root/wave04`
**Input:** `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`
**Evidence:** `03d5823f59b92b68d634303ef443af49be84a1bf`
**Private worktree:** `/tmp/keyfill03-7f4b/workers/W37-consumer` — inaccessible.

**Outcome:** Actual visual inspection completed through immutable GitHub PNG fetches and image display. No new silhouette, facial shading, shadow, or color regression was visible in the selected original/current comparisons.

### Observed images

I displayed both [contact sheets and the selected PNGs](https://github.com/mirzotipi-wq/APP1/tree/03d5823f59b92b68d634303ef443af49be84a1bf/docs/parallel/03/evidence): all twelve tiles in each sheet, plus individual original/current pairs for `bust-soft`, `bust-hard`, and `bust-side`.

The pointed crown appears in both versions. Ear, jaw, neck, and shoulder outlines remain consistent. Soft versus hard facial shading, the warm rim, and the cooler oblique bust view are preserved. The contact sheets also retain the dark rim-only silhouette, darker exposure fixture, and cooler white-balance fixtures. Their differing layout and enlargement were accounted for by inspecting the individual paired PNGs.

Observed Git blob references:

| PNG path beneath evidence | Blob SHA |
|---|---|
| `current-contact.png` | `a83cc59f179ce42a3a24559596f2e51a62ce7c38` |
| `original-contact.png` | `a1359bc63dcf68e84cc325fe021f1d3604384e7d` |
| `current/` and `original/bust-soft.png` | `abf693fe92855475d3b3223502aa38b15ebf703c` |
| `current/` and `original/bust-hard.png` | `1ed3dce6d3b410adfed2388156073e813ad6244c` |
| `current/` and `original/bust-side.png` | `1822fca4f04508e4445b45f309b5e94a92a578fa` |

Each selected original/current PNG pair has the same blob ID; this independently corroborates the visual comparison.

### Crown attribution and limits

[PortraitHeadMesh.swift at the input commit](https://github.com/mirzotipi-wq/APP1/blob/ace9f2eba068bc31dd04bb2f1e2028af315d6bdb/Sources/LightingCore/PortraitHeadMesh.swift), blob `0ee106c9d37603b65b6ab9f219b5307e71d27cdc`, explicitly narrows the upper profile from width `0.059` at `y=0.108`, to `0.032` at `0.130`, to zero at `0.143`. The upper pole is `(0, 0.143, -0.005)`. This supports attribution to authored geometry. Smooth normals and geometric fallback are implemented separately.

Also inspected relevant `PortraitStudy.swift` excerpts, blob `8784480e13099dffbffaad8c8e9ad837316e5ab9`, and the fixture script, blob `7247cd6d37f17061d645c71f38b67c968388bd51`.

Read all four required directives. No execution, builds, tests, edits, ref mutations, or local report writing occurred. This bounded visual review establishes no portrait fidelity, physical calibration, or complete rendering-gate pass. No image-display blocker remains for wave 8.
