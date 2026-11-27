# W35 — cancellation and publication review

Runtime/canonical ID: /root/wave04/concurrency. Input: ace9f2eba068bc31dd04bb2f1e2028af315d6bdb. Assigned private tree: /tmp/keyfill03-7f4b/workers/W35-concurrency.

**Preservation:** coordinator summary from the worker's complete returned message, archived in wave04-evidence/W35-final-inline.md. The worker verified successful local writes before the outage; those report/evidence files were absent after recovery. This is not byte recovery of the original 521-word report.

Pinned-source inspection found an unconditional checkpoint before every pixel, including misses. A false poll allows at most eight further pixel starts; the ninth checks cancellation first. The camera throw is outside the invalidSurface catch and before StudyImage construction, so earlier pixels remain private. The bust wrapper retains only a completed result after a final cancellation check. The preview suppresses stale/cancelled completions; a current camera error publishes image=nil, and retry creates a new ticket.

An actually executed Python model checked 6,561 eight-slot supported/background/camera-error patterns: maximum eight starts, 256 cancellation exits and 6,305 camera-error exits; none returned an image or entered modeled cache admission. Sixteen publication states were checked. All-background work used eight starts/two polls; supported → background → camera error kept two private pixels and returned no image. Python exited 0.

These are static/control-flow and model results, not Swift concurrency execution. Cancellation racing after a final poll is not an atomic publication veto. The root correction preserves this reasoning only if checkpoint/throw placement remains intact. No candidate inspection, Swift/native test, product edit, commit, push or cleanup by W35. The final shortening command failed before process creation during environment loss.
