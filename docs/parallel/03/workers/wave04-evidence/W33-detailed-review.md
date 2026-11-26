# W33 — clipping versus emitter errors

**Identity:** W33 API reviewer; actual canonical runtime ID `/root/wave04/api`, confirmed by `collaboration.list_agents`. Private detached tree `/tmp/keyfill03-7f4b/workers/W33-api`; input `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`. Report root: `/workspace/scratch/7f4be4bbb2d6/APP1-lane03`.

## Result: source reasoning, not runtime execution

`PortraitStudyRenderer.render` orders resolution → initial cancellation → camera setup/origin guards → scene validation/active-emitter preparation → per-pixel clipping → lighting evaluation. The clipping throw is outside the sole `invalidSurface` catch. No inspected path converts `invalidCamera` into unsupported pixels.

| Concrete input, cancellation false unless stated | Direct public API result |
|---|---|
| Framed camera `(0,1.60,1.7)`, 70 mm, width72; subject `(0,1.5,0)`; point light `(0,1.5,0.10)`, 500 cd/5600 K | Image with positive unsupported count; `invalidSurface` becomes mask1/magenta. Existing near-field regression asserts this. |
| Subject origin; camera `(0.001,0.18,0)`, 50 mm, width24; no lights | `invalidCamera`; no image/mask returned. |
| Same clipped camera; valid point light `(-1.5,2.1,1.2)`, 900 cd/5600 K | `invalidCamera`; earlier lighting masks, if any, cannot publish. |
| Same clipped camera; light Kelvin NaN, even with candela0 | `invalidScene` before clipping detection. |
| Same clipped camera; otherwise valid active rectangle aimed at its own position | `invalidEmitter` before clipping. With candela0 and valid stored fields, preparation skips it and clipping yields `invalidCamera`. |
| Clipped or setup-invalid camera, width24, callback immediately true | `cancelled`, one initial poll. Width23/25 instead gives `invalidResolution`, zero polls. |

Sources: `PortraitStudy.swift:162–227`; `ReferenceStudy.swift:232–265,285–307`; `Scene.swift:62–77`. Genuine receiver proximity remains an emitter-domain limitation, not malformed emitter data.

The shipped preview calls `StudyRenderEngine` (`ReferenceStudyPreview.swift:195–200`). Its bust branch directly propagates CPU errors, retains only completed images, and caps width at144 (`MetalStudyRenderer.swift:175–194`). Its initial cancellation precedes even width handling, unlike the direct API. Preview maps camera/emitter errors separately and gives failures zero unsupported pixels (`ReferenceStudyPreview.swift:48–57`). Its unsupported warning does not promise validation precedence.

## Coverage and documentation

Exact inventory: camera-depth3, portrait7, cancellation7, input-boundary5 methods (22 declarations). Relevant assertions cover no-light clipping, geometric entry/exit witness, thirteen supported camera controls, genuine near-field masking, pre-cancellation, resolution precedence, and setup-camera/scene/emitter precedence. No combined clipped-camera/malformed-light assertion was found in these files. Declarations/assertions were inspected, not executed.

**P3 documentation ambiguity:** W13-api and wave02 say “resolution → camera → scene → emitter.” This describes their setup-camera controls; it must not be generalized to the later clipping error. Qualify that wording in subsequent handoff and add a combined-error regression when source work resumes. No product/API defect established; no runtime probe necessary.

## Executed evidence and limits

Startup `git status --short --branch`, `git log -3 --oneline`, `python3 scripts/agent_cycle.py check`, and `next` all exited0; clean detached input. `check` verifies ledger structure only. Exact searches/slices are retained in `wave04-evidence/W33-{source-review,focused-source,wrapper-source}.txt`; guessed-path `rg` exit2 and recovered actual paths remain recorded.

Executed `python3 docs/parallel/03/workers/wave04-evidence/W33-static-audit.py` from report root: exit0; ordered source assertions, catch/propagation checks, 22-method inventory and eight file hashes recorded in `W33-static-audit.json`. This is a bounded static check, not a Swift test pass. No builds, source edits, commits, pushes, cleanup or native/runtime claims. Initial display truncation required focused reads beyond the four-call target.
