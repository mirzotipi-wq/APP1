# W77 consumer review

**Status:** completed archived-image/source review. Actual runtime `/root/wave08/w77_consumer`; input `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; tree `bba62b3555a03cdbd6dcb47a419a433d996c82f7`. Private source `/tmp/keyfill03-7f4b/workers/W77-consumer`; assigned scratch `/tmp/keyfill03-7f4b/builds/W77-consumer`. Private tree remains clean.

**Directly viewed with `view_image`:** original/final contact sheets and both archived PNGs for `soft`, `hard`, `warm`, `exposure-minus-two`, and `white-balance-3200`. Key-only/fill-only views were inspected on both sheets. All images came from `docs/parallel/03/evidence`.

**Findings:** soft rectangles produce broad highlights and softer panel-shadow boundaries; hard point sources produce smaller highlights and sharper shadow edges. Key-only illuminates the left side with a long rightward shadow; fill-only is dimmer with a right-side highlight. `exposure-minus-two` darkens the sphere/panel without changing framing. `warm` is visibly blue and brighter at WB3200 K/+1 stop; `white-balance-3200` is blue at WB3200 K/0 stops. Both retain 5600 K key/fill and 3200 K rim emitters.

`Colorimetry.swift` adapts the selected approximate-blackbody white to D65 using Bradford, scales adapted scene-linear XYZ by `2^stops`, then applies luminance Reinhard mapping, neutral-axis gamut compression and sRGB encoding. Thus +1/−2 stops scale linear signal by 2/0.25; displayed RGB is not proportionally scaled. These are neutral synthetic sphere/mannequin direct-light models, without photographic/material calibration.

**Checks:** all 36 original/final PNG/PPM/scene pairs are byte-identical; all 31 archived core source hashes match the input. Six sphere fixture-comparator counts match W74. The reviewed `IMAGE_REVIEW.md` captions need no correction. Source/image hashes, scene settings and comparison counts are retained in [W77-archive-review.json](wave08-evidence/W77-archive-review.json).

**Limits:** no rerender, benchmark, build, test suite, native or Metal execution by W77. Original raw RGBA/masks are absent; final zero-mask/alpha255 checks are separate root evidence. No appearance improvement across revisions is claimed. One guessed source-path search failed and was corrected; its error is retained. Four historical resets and W72's ENOSPC receipt remain untouched. Exact counters unavailable; no measured budget-percentage claim.
