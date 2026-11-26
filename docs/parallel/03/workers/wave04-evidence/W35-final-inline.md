# W35 — complete returned final message

**W35 result: preserved on pinned `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`, using static inspection and an executed Python model.**

- The false poll sets the counter to eight and consumes one slot. Seven more pixel evaluations can follow; the ninth checks cancellation before evaluating. Background misses use the same unconditional checkpoint.
- Per-pixel `invalidCamera` escapes outside the `invalidSurface` catch. Earlier pixel writes remain private arrays; image construction occurs only after both loops and the final cancellation guard.
- The bust engine reaches cache admission only after the renderer returns a complete image and another cancellation check succeeds. A thrown camera error cannot reach that branch.
- The preview pipeline suppresses stale/cancelled success and error completions. Current `invalidCamera` produces an error completion with `image=nil`. Retry creates a new attempt/ticket and bypasses completed-image reuse for failed frames.
- Cancellation can arrive before an earlier camera failure ends the loop; that failure can precede the next cancellation poll, but stops work sooner. The argument concerns partial frames and pixel work, not an atomic veto of cancellation after the final poll.

**Executed model:** 6,561 eight-slot supported/background/camera-error patterns; maximum **8** further pixel starts; **256** cancellation exits and **6,305** camera-error exits. None returned an image or reached modeled cache admission. All-background case used eight starts/two polls. Supported → background → camera error retained two private pixels and returned no image. Sixteen publication states checked. Python exited **0**.

**Artifacts successfully written before environment loss:**
- `docs/parallel/03/workers/W35-concurrency.md`
- `docs/parallel/03/workers/wave04-evidence/W35-source-control-flow.txt`
- `docs/parallel/03/workers/wave04-evidence/W35-execution.txt`
- `docs/parallel/03/workers/wave04-evidence/W35-cancellation-model.py`
- `docs/parallel/03/workers/wave04-evidence/W35-cancellation-model.json`

Private tree: `/tmp/keyfill03-7f4b/workers/W35-concurrency`. Tool-returned runtime ID/canonical path: `/root/wave04/concurrency`. Host: `6e77ed83c607`.

No Swift build/tests, candidate inspection, source edits, commits, pushes, or cleanup. Parent-reported nine pipeline tests and 383 core passes remain inherited evidence. Root’s first-depth replacement retains this argument if checkpoint and throw/catch placement stay intact.

**Environment failure:** After successful artifact writes/status verification, the final report-shortening command failed before process creation: exec-server transport disconnected, recovery timed out after 45 seconds. The environment is now unavailable. Last verified report is the 521-word version; its requested ≤800-token limit was not verified. The initial source read also required a bounded follow-up because output was truncated.
