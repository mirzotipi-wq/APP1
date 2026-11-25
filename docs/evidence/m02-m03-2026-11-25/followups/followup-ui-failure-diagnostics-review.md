# Independent review: failure-only UI diagnostics

**Review closed with no remaining source blocker.** Final reviewed files:

- `UITests/ProjectLibraryUITests.swift`: SHA256 `bb226a7267c345209f1aad9d3fce53d37ef0b74508f955dfeb7d5a428eb1c004`.
- `UITests/StudioSmokeTests.swift`: SHA256 `34895840aa5885514f36fa08d88a668f437e5d0957e939fdf75ca01c02d6f9ee`.

The Library change prints the description already captured for its existing failure attachment. It introduces no new accessibility query, wait, retry, assertion change or passing-path behavior.

Studio retains the same status element, predicate, single ten-second wait, caller file/line, and final failure assertion. Only a failed wait enters the diagnostic branch. That branch makes one `snapshot()` call, reads attributes from the returned snapshot, catches errors, and does not run a fallback query or retry the expectation.

Initial review found a concrete UTF-8 limit issue: repairing a byte prefix that ended inside a scalar could expand the output beyond 4,096 bytes. The final code fixes it by inspecting at most 4,097 input bytes and retreating at most three continuation bytes before decoding. The boundary index exists because the retreat runs only when more than 4,096 bytes are available. The decoded content is therefore valid UTF-8 of at most 4,096 bytes, followed by the explicit truncation marker when needed.

No production behavior, required test sequence, threshold or assertion was weakened. This reviewer read the complete diffs and final source hashes and made no source edits, builds or test runs. The author's local syntax-parse result is separate evidence; Apple typechecking, snapshot behavior and capture latency remain pending actual CI. No runtime repair or accessibility pass is inferred from this review.
