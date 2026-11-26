# W85 — concurrency review

Actual worker: `/root/wave09/w85_concurrency`. Input: `a7c93be58a04154748c951b3d485b05300e9692c`; clean detached worktree `/tmp/keyfill03-7f4b/workers/W85-concurrency`. Exact file SHA-256 values, commands, source locations and the unrun probe are in `wave09-evidence/W85-concurrency-source.json`.

**Result:** no actionable lane03 concurrency regression established by this source review. No production edits.

The concrete A → pending B → reused A schedule reaches `pipeline.begin()` before A’s cached-frame early return, so B’s late success or failure finds a noncurrent ticket. Cancellation before render continuation resumes prevents conversion and publication. Inactivity begins a new ticket before returning for a nil request; resume starts a fresh ticket. A pre-cancelled begin leaves live work’s ticket intact. Conversion-triggered invalidation is rechecked before publication. These are source deductions, not new SwiftUI execution results.

Thrown renderer errors and cancellation observed at final engine guards do not reach cache insertion. Current ordinary errors publish an image-free error completion. Per-pixel checkpoint placement supports the eight-evaluation bound; eviction precedes append under the 4-frame/256-KiB RGBA/64-KiB mask limits. Native and core test sources were inspected, not executed.

**Completion boundary:** bust pixels finish → engine guard at `MetalStudyRenderer.swift:192` observes false → external cancellation occurs → `retain` inserts at line243. This concerns already-completed pixels. If the final guard linearizes completion, the cancellation is after completion; this schedule does not establish prohibited pre-completion cancelled insertion. Actor non-suspension alone does not serialize external cancellation. The preview still drops the result when its post-await check observes cancellation.

An unrun deterministic probe would cancel the current task inside `cancellationRequested` at the measured final callback, return false, and inspect return/cache behavior. Because line177 reads `Task.isCancelled` first, this targets the precise boundary. It is an adversarial seam, not a demonstrated production failure. Root retains the engine-owner contract decision.

**Execution/limits:** read-only shell/source/hash inspection and report writing only; no Swift tests, builds, renders, benchmarks or copied model. Inherited source36 passes and the retained original failure are not this worker’s execution. Root owns fresh a7 native evidence. Qualitative 60% checkpoint sent; exact token counters unavailable. Review finalized after this specific risk assessment.
