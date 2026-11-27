# Saved image review — CPU Study and mannequin

**The twelve standard fixtures retain exactly the same image bytes and scene JSONs in the original and final archives.** The visible changes below are differences between the declared fixtures. They are not appearance improvements caused by the lane's implementation changes. The historical close-camera defect has a separate, observable outcome: the corrected renderer rejects the clipped subject with `invalidCamera` instead of returning the mostly unsupported image.

Reviewer: **W74-implementation**, actual canonical runtime ID `/root/wave08/w74_implementation`. Inspected immutable input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; tree `bba62b3555a03cdbd6dcb47a419a433d996c82f7`. Source was read in `/tmp/keyfill03-7f4b/workers/W74-implementation`. This is an archived-image and source review; W74 ran no renderer, benchmark, build or test suite.

## Evidence and method

The [original provenance](evidence/baseline.json) identifies baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. The [final source manifest](evidence/final-source-manifest.json) records parent `74f7584b4e474c752ec0939add6b7522ba98094f`, exact source hashes and the optimized archived matrix run. That parent identifies the recorded source context; the file hashes identify the actual inputs. W74 checked the archived LightingCore source hashes against the immutable input and read the [fixture script](../../../scripts/render-study-fixtures.swift) alongside the actual scene JSONs.

W74 directly displayed both contact-sheet PNGs and the three camera PNGs below with `view_image`. The existing original sheet is **1840 × 975**, and the final sheet is **1120 × 660**. Their tile sizes and spacing differ, so whole-sheet pixels are not a renderer comparison. No image was regenerated, repainted, resized or replaced for this exhibit. Individual scene and PNG links accompany every fixture.

The [W74 archive receipt](workers/wave08-evidence/W74-archive-review.json) records SHA-256 hashes, source identities and actual byte checks:

- All twelve original/final PPM files and all twelve scene JSONs are byte-identical; each image has **zero changed pixels** between those archives.
- Original and final saved PNGs decode to their PPM RGB bytes. Final raw RGBA RGB bytes also agree, every final alpha byte is **255**, and every final raw validity-mask byte is **0**.
- Original standard-fixture raw RGBA and masks were not archived. Their manifest reports zero unsupported pixels, but original raw-mask equality cannot be established. The PNG checks concern the saved files; they do not reconstruct a historical conversion command or encoder version.
- The original fixture manifest is an object with a fixture array; the final raw archive manifest is itself an array. Their different schemas were parsed explicitly. Two failed read-only inspection attempts and their corrections are recorded in the receipt.

### Original saved contact sheet

![Original twelve synthetic fixtures, ordered left to right and top to bottom as listed in the review table](evidence/original-contact.png)

### Final saved contact sheet

![Final twelve synthetic fixtures with unchanged underlying PPM images and scene JSONs](evidence/final-contact.png)

## Exact scene settings and twelve-fixture observations

All twelve scenes use subject position **(0, 1.5, 0) m** and an **85 mm** lens. Camera **S** is **(0, 1.66, 2.3) m**, with a sphere image of **120 × 80** pixels. Camera **B** is **(0, 1.60, 1.7) m**, with a neutral mannequin image of **144 × 96** pixels. Camera **O** is **(0.84, 1.63, 1.45) m**, also **144 × 96**, providing the oblique bust view. Omitted preview settings use **5600 K white balance and 0 exposure stops**.

The common rig has these exact values; a single-light fixture retains only its named source. Rectangles use the script's interactive deterministic sampling, with 8 × 8 samples on fully illuminated rectangles. The hard fixtures remove the optics entries, selecting the default point model.

| Source | Position, metres | Intensity | Emitter temperature | Rectangle width × height |
|---|---|---:|---:|---|
| Key (K) | (−1.5, 2.1, 1.2) | 900 cd | 5600 K | 1.0 × 1.2 m |
| Fill (F) | (1.5, 1.7, 1.5) | 300 cd | 5600 K | 0.8 × 0.8 m |
| Rim (R) | (0.8, 2.2, −1.2) | 450 cd | 3200 K | 0.4 × 0.8 m |

The last column describes the actual saved appearance and gives the count of changed RGB pixels against the named **fixture comparator**, recomputed from the final PPMs. Those counts describe fixture variation; original-to-final counts are zero for every row.

| Fixture scene / saved image | Camera | Active emitters | White balance / exposure | Observation and fixture comparator |
|---|---|---|---|---|
| [soft](evidence/final/soft.json) · [PNG](evidence/final/soft.png) | S | K/F/R rectangles | 5600 K / 0 stops | Neutral sphere, broad front highlights, warm upper-right rim and soft panel shadow. Baseline sphere. |
| [hard](evidence/final/hard.json) · [PNG](evidence/final/hard.png) | S | K/F/R points | 5600 K / 0 stops | Smaller, sharper highlights and a more sharply bounded panel shadow; 5,678 pixels differ from `soft`. |
| [warm](evidence/final/warm.json) · [PNG](evidence/final/warm.png) | S | K/F/R rectangles | **3200 K / +1 stop** | The neutral sphere and panel look bluer and brighter. Emitter temperatures remain those of `soft`; 5,896 pixels differ from `soft`. The historical name does not mean warmer emitters. |
| [bust-soft](evidence/final/bust-soft.json) · [PNG](evidence/final/bust-soft.png) | B | K/F/R rectangles | 5600 K / +1.25 stops | Frontal neutral head, ears, neck and shoulders; softer facial shading and a warm rim on the upper-right contour. Baseline bust. |
| [bust-hard](evidence/final/bust-hard.json) · [PNG](evidence/final/bust-hard.png) | B | K/F/R points | 5600 K / +1.25 stops | More sharply defined facial and neck shadows, with a stronger warm panel region; 4,451 pixels differ from `bust-soft`. |
| [bust-side](evidence/final/bust-side.json) · [PNG](evidence/final/bust-side.png) | O | K/F/R rectangles | 4300 K / +1.25 stops | Oblique face and nose silhouette with a cooler face. Camera position and white balance both change; 5,630 pixels differ from `bust-soft`. |
| [key-only-hard](evidence/final/key-only-hard.json) · [PNG](evidence/final/key-only-hard.png) | S | K point only | 5600 K / 0 stops | Bright left-side highlight, dark right hemisphere and long hard shadow extending right across the panel; 5,423 pixels differ from `hard`. |
| [fill-only-soft](evidence/final/fill-only-soft.json) · [PNG](evidence/final/fill-only-soft.png) | S | F rectangle only | 5600 K / 0 stops | Much darker sphere with a subdued right-side highlight; the key highlight and warm rim disappear. 5,687 pixels differ from `soft`. |
| [bust-rim-only](evidence/final/bust-rim-only.json) · [PNG](evidence/final/bust-rim-only.png) | B | R rectangle only | 5600 K / +1.25 stops | Largely black face and clothing, with a narrow warm head/shoulder edge and warm panel illumination; 4,526 pixels differ from `bust-soft`. |
| [bust-roll-90](evidence/final/bust-roll-90.json) · [PNG](evidence/final/bust-roll-90.png) | B | K/F/R rectangles; **K roll 90°** | 5600 K / +1.25 stops | Frontal pose and silhouette remain fixed. The shading change is subtle at this size; 911 pixels differ from `bust-soft`. The non-square key emitter is rolled, not the head or camera. |
| [exposure-minus-two](evidence/final/exposure-minus-two.json) · [PNG](evidence/final/exposure-minus-two.png) | S | K/F/R rectangles | 5600 K / **−2 stops** | Darker sphere, panel and rim with the same framing and light placement; 5,896 pixels differ from `soft`. |
| [white-balance-3200](evidence/final/white-balance-3200.json) · [PNG](evidence/final/white-balance-3200.png) | S | K/F/R rectangles | **3200 K / 0 stops** | Blue neutral sphere/panel, with less brightening than `warm`; 5,896 pixels differ from `soft`. This isolates white balance without the extra exposure stop. |

At the saved resolutions, the fixtures retain coherent sphere and mannequin silhouettes, the intended key/fill/rim separation, recognizable soft/hard shadow differences, and the declared exposure and white-balance responses. No new seam, missing body region or magenta unsupported region was visible in these twelve images. The narrow crown is already visible in the original bust views and remains unchanged in the final images. Pixelated contours and discrete shadow edges remain visible at these small resolutions. The bust is an original **neutral synthetic direct-light model**, not calibrated skin, fabric or a reconstructed person; these observations do not establish photographic realism.

## Historical clipped-camera diagnostic and corrected result

This diagnostic is separate from the twelve fixtures. The [actual probe](evidence/portrait-camera-visual.swift) sets subject **(0, 0, 0) m**, camera **(0.001, distance, 0) m**, a **50 mm** lens, **no lights**, and a **144 × 96** mannequin render. Its two distances are **0.18 m** and **0.20 m**.

| Case | Historical original | Corrected archived result |
|---|---|---|
| `overhead-clipped`, distance 0.18 m | Returns 144 × 96 image with **11,708 unsupported pixels**. Actual saved mask independently contains 11,708 ones. | **`invalidCamera`**; no clipped PNG, PPM, mask or RGBA frame is archived. |
| `overhead-clear`, distance 0.20 m | Returns 144 × 96 image, **0 unsupported pixels**. | Returns 144 × 96 image, **0 unsupported pixels**; PNG, PPM and mask bytes match the original exactly. |

Sources: [original results](evidence/camera-original/result.json), [corrected results](evidence/camera-corrected/result.json), and [camera review/provenance](evidence/camera-review.json).

### Actual original clipped-camera image

![Historical 0.18-m overhead no-light mannequin diagnostic: a mostly magenta unsupported region surrounds a black central region](evidence/camera-original/overhead-clipped.png)

The large magenta field is the renderer's unsupported-surface diagnostic, not colored illumination. The corrected result is an error record, so there is no corrected error screenshot to display or compare.

### Actual corrected clear-camera image

![Corrected 0.20-m overhead no-light camera image, fully black with zero unsupported pixels and identical to the original clear frame](evidence/camera-corrected/overhead-clear.png)

The clear image is black because this probe has no lights. W74 also directly viewed the [original clear PNG](evidence/camera-original/overhead-clear.png). Its unchanged black output does not indicate a brightness improvement. The camera review retains the initial center-ray witness problem, its original/corrected logs, and the later scan of actual pixel rays; that historical failed witness was not relabeled as a pass.

## What the implementation changes actually affect

| Change inspected at the immutable input | Behavior supported by source and retained evidence | Visible scope of this exhibit |
|---|---|---|
| [Head-mesh determinant threshold and cached face normal](../../../Sources/LightingCore/PortraitHeadMesh.swift) | Intersection uses `abs(determinant) > twiceArea × 1e-14`, avoiding an absolute cutoff that rejects small grazing triangles. Each triangle stores its normalized geometric face normal. | Edge-case intersection handling changes; all twelve standard images remain identical. |
| [Early sphere cancellation](../../../Sources/LightingCore/ReferenceStudy.swift) | After cheap resolution validation, cancellation is checked before camera setup and sample allocation. | A cancellation/lifecycle change; the saved completed images do not measure cancellation latency. |
| [First-surface camera-depth validation](../../../Sources/LightingCore/PortraitStudy.swift) | Finds the true nearest surface before the near-depth test, rejects a clipped closed subject with `invalidCamera`, and preserves ordinary clipping of the open panel. | Historical 0.18-m no-light probe becomes an error/no-frame outcome; the 0.20-m clear output stays identical. No new execution occurred during this review. |
| [Tiny per-emitter intensity scaling](NUMERICS.md) | Positive emitters whose per-sample intensity is subnormal are evaluated at unit intensity, then scaled once per emitter. Ordinary accumulation keeps its previous path. | No standard-fixture RGB change. This addresses early underflow within the documented limits; later grazing/weight underflow and final quantization remain possible. Tiny positive light can still display as RGB8 black while retaining geometric validity checks. |
| [Preview generation, retry and paused state](../../../App/ReferenceStudyPreview.swift) | Generation tickets and cancellation guards control publication; Retry creates a fresh attempt without editing the scene. Inactive scenes pause requests, and a retained previous same-subject image carries an updating/paused status. | Source-level lifecycle/UI behavior. These renderer PNGs are not native screenshots and provide no visual acceptance of the Retry control, paused labels or accessibility layout. |

## Disposition and limits

Accept this exhibit as the review of the **saved twelve-fixture software matrix** and the historical camera diagnostic, with byte identity and source continuity scoped as above. Preserve the original failures, including the earlier W72 storage-failure receipt. W74 encountered no new storage failure; its two corrected read-only inspection errors remain recorded.

Root-owned tests, benchmarks and Apple builds are separate evidence and were not rerun or counted as W74 work. Exact native method accounting remains pending outside this exhibit. No physical calibration, physical-device performance, manual VoiceOver session, native UI execution or actual Metal execution is claimed. The twelve standard fixtures do not exhaust the renderer's input domain or prove every numerical edge case.
