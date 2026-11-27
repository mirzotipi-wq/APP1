# Worker 035 — concurrency/error semantics

- ID: w035; lane 04, wave 4; independent read-only reviewer.
- Base: `c08cd0be2548467add169c3594207cf489760787`.
- Candidate `App/StudyKernel.h`: `f60258402a96f58b62607d5cefec5e41c7ec4137`; baseline: `df3175546623508b192d29210dcd9b51efce4c37`.
- Ownership: report only; integration belongs to root on `finish/04-metal-cache`. No source, global state, handoff, harness, oracle, preview, thresholds, fixtures, commits or refs changed.

## Actual evidence

Read the nine mandatory startup files once with pinned GitHub `fetch_file`; read both header blobs with `fetch_blob` and pinned `Sources/LightingCore/ReferenceStudy.swift` / `App/MetalStudyRenderer.swift`. An in-memory line comparison found only metadata guards and relocation of guarded casts; sampling bodies are unchanged.

In restored private worktree, `git status --short --branch` returned clean detached HEAD; `git log -3 --format='%H %s'` identified the exact base above. `python3 scripts/agent_cycle.py check` and `next` both exited 0; check validates references only, and next reports historical M03 gates. Current lane ownership overrides that old work selection.

## Findings

No blocker found. Counts are finite/integral and bounded before conversion; dimensions/pixel bounds and exact grid 8 reject early. Nonzero encountered tags require integral 1...areaCount before indexing. Area traversal is at most 12; sample traversal advances by 1 or 64 within 768, with at most 64 contributions per area block. No new loop, synchronization or cancellation behavior is introduced. Valid packed inputs retain the same arithmetic and traversal.

Within a valid frame envelope, canonical (255,0,255,0) remains an unsupported pixel: the decoder records its mask/count and restores opaque alpha. It does not throw or implicitly disable Metal. Malformed dimensions/length, noncanonical alpha-zero RGB or intermediate alpha throw `invalidComputeOutput`; the engine then selects CPU and evicts Metal frames. Parity rejection remains a separate backend failure.

Cancellation during validation leaves the backend unchecked. Cancellation after submitted GPU work discards the result before retention; cancellation error paths do not downgrade the backend. CPU checks remain every eight pixel evaluations.

## Recommendation and limits

Accept this focused semantic review. Actual buffer lengths remain the validated caller's responsibility. No compilation, runtime cancellation experiment or actual Metal execution ran. Wave-3 results predate this candidate and are not wave-4 evidence; fresh candidate parity/precision validation remains required.
