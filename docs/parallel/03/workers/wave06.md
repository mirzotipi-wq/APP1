# Lane 03 wave 06 — preview status and cancellation

Input: `74f7584b4e474c752ec0939add6b7522ba98094f`. Source candidate: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`, pushed and remote-verified by root. **Ten actual contexts** exist: W51 acceptance leader plus nine fresh specialists. W54 followup reused its context and is counted once. All ten assignments are complete. W60 recommends retaining the exact candidate; native UI verification remains pending.

## Actual workers

| Worker | Role | Actual canonical runtime ID | Status | Report |
|---|---|---|---|---|
| W51 | acceptance | `/root/wave06` | complete | [W51-acceptance.md](W51-acceptance.md) |
| W52 | geometry/data | `/root/wave06/w52_geometry` | complete | [W52-geometry.md](W52-geometry.md) |
| W53 | API | `/root/wave06/w53_api` | complete | [W53-api.md](W53-api.md) |
| W54 | implementation | `/root/wave06/w54_implementation` | complete | [W54-implementation.md](W54-implementation.md) |
| W55 | concurrency | `/root/wave06/w55_concurrency` | complete | [W55-concurrency.md](W55-concurrency.md) |
| W56 | resource | `/root/wave06/w56_resource` | complete | [W56-resource.md](W56-resource.md) |
| W57 | consumer | `/root/wave06/w57_consumer` | complete | [W57-consumer.md](W57-consumer.md) |
| W58 | accessibility/privacy | `/root/wave06/w58_accessibility_privacy` | complete | [W58-accessibility-privacy.md](W58-accessibility-privacy.md) |
| W59 | platform/performance | `/root/wave06/w59_platform_performance` | complete | [W59-platform-performance.md](W59-platform-performance.md) |
| W60 | independent review | `/root/wave06/w60_independent_review` | complete | [W60-independent-review.md](W60-independent-review.md) |

Each worker was assigned its own detached tree at the input and its own output directory. Exact paths, commands/results, source hashes and evidence are in [wave06.json](wave06.json). Precreated trees were never counted as workers.

## Concrete changes and evidence

The original view stopped work while inactive yet retained Rendering/Updating claims. The candidate uses static paused text for pending empty/hidden frames and retained same-subject previous images; previous-image accessibility wording matches the phase. Active progress identifiers, current image/backend/warning, error scrolling, retry, request normalization and subject filtering remain.

W55 identified the pre-start ticket boundary. Root authorized a separate narrow correction: a canceled begin returns an unused ticket without replacing the live generation, and the view task checks cancellation before begin/frame clearing. One deterministic MainActor/ControlledRender regression was added; the original nine methods are byte-preserved.

| Evidence | Actual result | Scope |
|---|---|---|
| Root baseline Swift harness | Ten methods: original nine pass; new method fails two assertions (live completion count 0 versus 1, image nil versus 9) | Actual production generation seam |
| Root corrected Swift harness | Ten methods, zero failures | Actual Linux Swift seam; conditional SwiftUI body excluded |
| Root Swift frontend parsing | Exit 0 | Syntax; not native SwiftUI compilation |
| W51 independent byte/wiring checks | Eleven checks true; combined patch apply preflight exit 0 | Source inspection, not runtime UI |
| W58 accessibility/privacy | Recommends integration; baseline semantics/44-point retry intent/imports preserved | No layout/contrast/VoiceOver execution |
| W59 native provenance | Retained ace9 163-method result and nine preview methods verified against old hashes | Not a candidate native pass |

Candidate preview SHA256: `45a899619938e4a9c719f42af9c37d79e685c3a98d51465ca1995cc260595fc6`. Test SHA256: `a68a38abce16baff2eee55c175bd3874664d8707d6c358d04282691455407c99`. Source patches, receipts and reviewer evidence are in `wave06-evidence/`; root baseline/corrected raw logs remain under `../evidence/`.

## Limits and preserved interruption

Fresh native Debug/Release app compilation and native test results remain pending for this candidate, along with focused changed-presentation/foreground-recovery evidence. The held-render regression does not reproduce actual SwiftUI callback scheduling. No physical device, manual VoiceOver, memory, thermal or timing claim is made. Existing cache/kernel/dimensions/sample budgets are unchanged, so this view delta did not trigger a repeated timing benchmark. Earlier CPU changes retain separate source-specific gates.

W57 traced the two preview callers and validation paths without finding a supported-flow NaN witness. The arbitrary invalid in-memory construction edge remains conditional; no identity refactor or engine/cache/shared-composition change was made.

One executor outage prevented a W51 receipt command from starting and blocked W55/W56 report writes. All temporary trees/control/builds were lost; persistent reports/patch survived. Root restored control, W54 restored its tree, and W51 restored required trees serially. W55/W56 inline reports were preserved after recovery; W57 private artifacts were copied into root. The unsuccessful command is not reported as executed. No worker cleanup, commits or pushes were performed by this wave; root alone owns integration and preservation. Token counters were unavailable, so no measured budget compliance is asserted.

The wave does not promote M02/M03 or release readiness.
