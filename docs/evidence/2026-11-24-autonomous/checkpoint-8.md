# Nested document integrity and final native failures — checkpoint 8

Current integrated source **`816e7123cafbf214bef47e09d3e14abd993a83c7`**, exact tree **`19065fb97a3bdbfc9d15ec948adc5df28a784509`**. Parent is native-correction source `15a1b348c680423a46d94ecf739321a5a57bc0a7`, tree `9ac414a06f5ffb61b9d243fbac0ec56a5697dbaf`. Both linear commits were integrated through one non-forced main update from `ff8b683`; the lead read back the exact main SHA through the connector and local git fetch. No branch other than main was created or updated.

[Workflow 45373901992](https://github.com/mirzotipi-wq/APP1/actions/runs/45373901992) belongs to source 816e712 and was queued at **10:24:11 UTC, 2026-11-24**. No separate workflow is invented for parent 15a1b348: its native corrections are carried into this latest source.

## Exact-source local verification

**251/251 Debug and 251/251 Release portable XCTest methods passed**, zero failures, from an immutable staged-index export. Whole-suite times were 14.042 s and 5.242 s in this Linux run. **28/28 Python tests**, state validation, native Swift syntax, recursive six-class/three-shard assignment, source icon and privacy checks passed. Swift 6.4.3, Debian 13 x86_64. These timings and syntax checks are not native device performance or Apple SDK execution.

The connector-created tree exactly matched local git write-tree before the commit/ref update. The portable increase from 245 to 251 is exactly six new nested-document test methods. The separately prepared slider adapter tests discussed below are not included in this source or count.

## Unambiguous nested project fields

The external editable-document decoder now requires unique decoded names in every JSON object, not only the root envelope. Duplicate scene/light/position/optics/camera/preview fields and unknown nested metadata fields are rejected. Each object has its own key set; arrays, quoted punctuation and reuse in different objects remain valid.

A bounded iterative container stack mutates per-object Set<Data> keys in place and releases each set when its object closes. Keys are decoded with Foundation and compared as exact UTF-8 sequences: escaped versions of the same name collide, while distinct NFC/NFD scalar sequences remain distinct. Foundation remains the JSON validity/encoding authority. The existing 8 MiB ingress bound, schema version, canonical exports and legacy library/SceneCodec decoding are unchanged. This is an application document-integrity policy; RFC8259 recommends uniqueness and explains divergent duplicate mappings without making duplicate-name rejection a universal grammar requirement.

Before the correction, six new tests produced 27 failed rejection assertions. All 24 focused tests then passed in Debug and Release. The independent baseline concretely selected 900 cd over a later 200 cd, Key over Fill and x=0 over a later x=5. The candidate rejects that ambiguous document.

Independent probes rejected 1,440 duplicate variants, including 1,296 previously accepted; preserved 1,944 accepted unique documents and canonical bytes; retained 216 platform rejections; matched 16 accepted deep cases and 6 depth rejections; and rejected 16 formerly accepted deep duplicates. No correctness mismatch was found. These are finite probe inputs, not additional XCTest methods or proof over every JSON text. [Author packet](nested-document-integrity.md), [independent review and complete probes](nested-document-review.md).

### Actual large-input cost

An exact 8,388,608-byte input containing 699,008 unique nested keys retained the same decoded scene/canonical bytes; one additional byte failed the existing size check. Candidate decode took 2,196.6 ms versus 319.1 ms for the root-only baseline in one shared-Linux sample. Candidate medians were 37.1 ms at 10,000 keys and 97.2 ms at 20,000 keys across three samples each. Whole-probe peak RSS was 141,680 KiB, including fixture construction and both decoders.

The per-key integrity check has a real cost on this deliberately wide input. Import decoding is asynchronous, and these measurements establish neither a device UI stall nor an app-specific peak-memory result. No timing bound, cache speedup or iPhone performance pass is claimed.

## Source-six native run is now final

[Source ff8b683 workflow 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829) completed **failure at 10:18:58 UTC**. Its both unsigned simulator builds passed, its actual Release bundle was inspected, and its numerical/native successes remain scoped to that source.

| Scope | Actual outcome |
| --- | --- |
| Native unit target |42 methods completed:40 passed,2 failed;33 assertions in two SpatialPreview methods failed. Reader13/13, document I/O9/9, photo7/7, PDF3/3, renderer7/7 passed. |
| Library/reference UI |8 completed:7 passed,1 recovery-confirmation ambiguity failed. |
| Room/precision UI |5 completed:4 passed,1 room-note accessibility observation failed. All3 precision scenarios passed. |
| Studio/export UI |9 started,8 completed:4 passed,4 failed; bust switching was interrupted. No completed suite aggregate or finalized XCTest bundle. |

The final studio/export job 138342789444 hit its 32-minute UI-step bound. Both export cases stalled after their shared menu actions; PDF page query and editable-copy name checks failed. A following camera test could not terminate the preceding process. Optics Undo restored the intermediate 0.8500000000000001 m instead of its initial 0.6 m. Corrupt-file protection, meter save/undo/relaunch, recipe edit/save/reopen and the actual study-frame test passed. The artifact log records the study pass after cancellation began; the streamed job log alone omits it, so counts use the retained artifact log.

Artifact 14909602374 (`ui-studio-export-evidence`) is a verified 26,595-byte ZIP, SHA-256 `bfd7da312d45689edbf7903717a7d213da1a6ea42b73aad3ac9a75d205f57bfe`. It contains six text logs and no finalized xcresult, screenshots or attachment manifest. Missing visual evidence is not reconstructed or treated as passing.

## Further corrective packet in progress

The new native findings trigger a separate packet after this source: one immutable-snapshot export sheet with local format switching, and an adapter that begins an owned continuous edit before its first slider-origin write. The original optics Undo assertion and existing export preparation timeouts are retained. These working changes are not covered by source 816e712 verification. [Export correction](export-native-correction.md); slider/native acceptance remains pending until the next integrated candidate runs on Apple tooling.

The earlier five native corrections from parent 15a1b348 have independent source review and local verification, with actual native re-execution still pending. Neither the later JSON check nor local syntax parsing transforms source-six failures into passes.

## Provenance and remaining gates

This makes **eight complete local implementation/verification integration cycles** and **eleven pushed commits** in the session, including three earlier evidence-only commits. The planned workforce was 60 specialists in 10 waves; the additional named read-only SceneKit subreview brings actual usage to 61 specialists plus the lead. The ledger records the additional agent explicitly. No human customer, physical-device operator or release reviewer was simulated.

M01 remains active with current native build/persistence acceptance outstanding. Current source has no native result yet; sourceff build evidence does not certify it. Physical rendering/calibration, device performance/thermal/accessibility, actual share/provider workflows, controlled reference inference, AR, commerce, customer validation, distribution and owner approval remain open. The independent twenty supported evidence points remain a scoped engineering review, not a certified commercial score or 95/100 claim.

## Preserved raw logs

- [cycle8-debug.log](cycle8-debug.log), SHA-256 `52fc0888681aedc8677a49382f51d4937833d2c88652873df14a5de61b74af35`.
- [cycle8-release.log](cycle8-release.log), SHA-256 `281ef3f9fccf9d92b1a37f4b317ba92e76e263577c309d3b975e42ddd4ace7e1`.
- [ff8b683-studio-export.log](ff8b683-studio-export.log), SHA-256 `3747cd1c44ef0b01358958696688a0bfeb09e7781df8cd335a7b98d35170c486`.
- [ff8b683-studio-export-native-tests.log](ff8b683-studio-export-native-tests.log), SHA-256 `0f60b9bf4d694cbbc022e3c74dc44a7b61372bdcd73f40e58a8f9f6d725983d3`.

## Subsequent exact-source observation

At10:38UTC, direct jobs evidence showed core success, both unsigned simulator build/upload steps successful, native unit/library/reference/room/precision tests in progress and studio/export queued. The retained [actual core job log](816e712-core.log) reports251/251Debug and251/251Release,28Python and successful shared-kernel steps. The workflow-list endpoint still displayed a queued state and was not used to override the more specific job observations. Native suite acceptance was not yet established.
