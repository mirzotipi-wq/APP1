# w097 — Final owner refresh supplement

Same-ID followup; the primary report remains unchanged. Owner 02 remains at `b5c1f008446f8b33f3ee97f8fefe6675058ef347`. Owner 03 advanced to `6f93f95c817d2bd230ae93554dea25a174a437f8`; all subsequent reads used that revision.

| Owner 03 path | Current Git blob | Change since prior observation |
|---|---|---|
| App/ReferenceStudyPreview.swift | `999b590b7eaad2bed75d417690856004300568b2` | Unchanged |
| Sources/LightingCore/ReferenceStudy.swift | `82e54a53f3d32d745aee1edfa297086504fb81ec` | Unchanged |
| NativeTests/StudyPreviewAdoptionTests.swift | `f65004c8b7ca86248a163c80b9d7a3c02dabf20e` | Replaces prior `c514f15cf000538f56d7653b7b30d85d451442ad` |

The [retained terminal receipt](https://github.com/mirzotipi-wq/APP1/blob/6f93f95c817d2bd230ae93554dea25a174a437f8/docs/parallel/03/evidence/ci-native-342-failure.json) now establishes Apple compilation and a failed original hosted execution at source `342e3280e3eb077d55e122c8bfb88b4062b431ed`, run 45857561126/job 140042273149: 165 starts, 164 passes, one failure, zero skips/unstarted. Debug app/native-bundle and Release app builds passed. The initial AX positive control returned no identifiers and timed out before scene switching; this does not demonstrate a product defect.

The reviewed test correction replaces AX status/backend/warning assertions with actual mounted center-pixel observations: gray 32 initially/while held, then gray 160 after replacement. Single-host sequencing and two A/one B calls remain. This is changed coverage, not equivalent AX verification or an executed pixel pass.

Current owned HANDOFF retains corrected source `dbbc264fde91bfb04a1e82fbebdf2f8d5792d761` as awaiting native execution. The hook-only before/fail comparison remains unperformed. The unchanged adoption-input receipt is historical and must be read with the later failure/patch.

Three additional pinned identity reads confirm owner 03 still carries the older engine, shared header and eligibility blobs; none matches the lane 04 targets. Full identity pairs are retained in the receipt. Combined 03/20 gates remain open. No acknowledgment is inferred. [Read receipts](final-owner-refresh-receipts.json) preserve identities, limitations and rejected URL attempts. No live CI polling, execution or source/ref changes occurred.
