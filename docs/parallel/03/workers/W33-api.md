# W33 API review

Runtime identity `/root/wave04/api` confirmed by `collaboration.list_agents`; private tree `/tmp/keyfill03-7f4b/workers/W33-api`; immutable input `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`. Durable checkout `/workspace/scratch/7f4be4bbb2d6/APP1-lane03`.

## Source-derived truth table

C = subject origin, camera `(0.001,0.18,0)`, 50 mm, width24. Cancellation false unless specified.

| Input | Public `PortraitStudyRenderer.render` result |
|---|---|
| Valid camera `(0,1.60,1.7)`, 70 mm, width72; subject `(0,1.5,0)`; point emitter `(0,1.5,0.10)`, 500 cd/5600 K | Image; positive unsupported count, mask1/magenta for genuine proximity failures. |
| C, zero or valid lights | `invalidCamera`; no returned image/mask. |
| C, malformed Kelvin NaN, including inactive light | `invalidScene`. |
| C, otherwise valid active rectangle aimed at its own position | `invalidEmitter`; inactive valid-data version reaches `invalidCamera`. |
| C or setup-invalid camera; immediate cancellation | Width24: `cancelled`, one poll. Width23/25: `invalidResolution`, zero polls. |

Order: resolution → cancellation → camera setup → lighting preparation → pixel clipping → lighting evaluation. Clipping throws outside the sole `invalidSurface` catch; it cannot become unsupported pixels. Sources: `PortraitStudy.swift:162–227`, `ReferenceStudy.swift:232–307`, `Scene.swift:62–77`.

Shipped bust wrapper propagates errors and retains completed images only (`App/MetalStudyRenderer.swift:175–194`); its initial cancellation precedes width handling. Preview maps camera/emitter errors separately, with zero unsupported pixels on failure (`App/ReferenceStudyPreview.swift:48–57`). UI promises no precedence.

**P3 documentation ambiguity:** W13-api/wave02’s “camera before scene” wording describes setup checks, not later clipping. Qualify subsequent handoff; add combined clipping/malformed-light regression when implementing. No API defect established.

## Executed check and limits

`python3 docs/parallel/03/workers/wave04-evidence/W33-static-audit.py` exited0: source ordering, catch/propagation checks, eight source hashes, exact22-method inventory (camera3/portrait7/cancellation7/input5). Existing assertions cover individual failures; combined clipping/malformed-light behavior above is source reasoning, not execution.

Startup status/log and `agent_cycle.py check`/`next` exited0; private tree clean. Raw exact searches, slices, results and limitations: `wave04-evidence/W33-*`, including `W33-static-audit.json` and detailed review. Guessed-path rg exit2 and display truncation required focused recovery beyond four calls. No Swift/native tests, builds, source edits, commits, pushes or cleanup; no runtime pass claimed.
