# W80 — independent review

- Runtime: `/root/wave08/w80_independent_review`; parent `/root/wave08`.
- Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; tree `bba62b3555a03cdbd6dcb47a419a433d996c82f7`.
- Private tree: `/tmp/keyfill03-7f4b/workers/W80-independent-review`; clean. Assigned private outputs unused.
- Status: completed archived-image/source challenge and independent W74 candidate diff review; no production edits or new execution.

## Actual checks and findings

Directly displayed original/final contact PNGs and original clipped-camera PNG with `view_image`. All twelve fixture names remain present; original narrow crown/shape persists. Different sheet scales are not image improvements. `warm` is 3200 K white balance/+1 stop; roll90 applies to the key emitter.

Independently checked all twelve original/final JSON, PPM and PNG files: byte-identical; zero changed RGB pixels. Decoded PNG/PPM/raw RGB agree; final alpha is 255 and all masks are zero. Original standard RGBA/masks are absent, so historical raw-mask equality is unproven. All **31 LightingCore** manifest hashes match source36; historical preview/test hashes differ and are explicitly scoped separately.

Original no-light 144×96 camera0.18 m has **11,708** mask ones and magenta pixels. Corrected result is `invalidCamera` with no clipped frame. Camera0.20 m PNG/PPM/mask remain identical and valid. `IMAGE_REVIEW.md` claims fit this evidence; no photographic calibration inferred.

**W78-AX-01 independently confirmed (P2):** a same-subject retained image with `frame.request != request` and positive unsupported count loses its warning and count from its image label in updating/paused states. Inactivity with an unchanged current request does not trigger this defect.

Reviewed W74 candidate `612e922e16a900bf69cbc1bf13d9995912db535703a4b0bd85f372de1f1d44a5`: previous-qualified count now appears in its image label and existing status container. Current warning, IDs, pipeline, tasks and tests remain unchanged; diff check clean. No source blocker; native layout/VoiceOver unrun.

Archived Apple log hash verified: **164 unique native passes**, including **10 pipeline**, plus documented 391 portable and six actual Metal fixtures. Exact masks follow the passing `StudyParityMetrics.passes` assertion; the printed flag checks counts. Source36 evidence predates W74 candidate.

## Receipt and limits

[W80 receipt](wave08-evidence/W80-independent-review.json), SHA-256 `36f6902817953634fa6131f5a9a88bb163d9f68e036e2d29be463bfb6e04470c`. Contains image/source/patch hashes and one corrected missing-path lookup. No renderer, build, benchmark, native UI, VoiceOver or physical execution. No gate promotion; resets and historical failures preserved.
