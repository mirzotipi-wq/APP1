# W13 — Study input boundary tests

Runtime/canonical task: `/root/wave02/api`. Input: `d0583603fa05d42d5b8e36d9b1e8353965989ea6`.
Original private worktree/output: `/tmp/keyfill03-7f4b/workers/W13-api` and `/tmp/keyfill03-7f4b/builds/W13-api`; lost with the execution environment after completion.
Original isolated commit: `2a01899fa69be0654f35245cc1e06a4df0fbdf52`.
Recovered exact test-file blob: `23816b84316ea97532d573e38012764ae00cd8f4`.

Only `Tests/LightingCoreTests/StudyInputBoundaryTests.swift` changed: five methods, 131 lines, 6,152 UTF-8 bytes. Sixteen malformed-data rows exercise sphere interactive/reference, portrait and compute at width 24: unsupported schemas, five schema/field mismatches, thirteen lights, duplicate IDs and seven invalid zero-output light fields. All expect `.invalidScene` with a valid camera.

Controls retain resolution → camera → scene validation → active-emitter preparation precedence. Twelve valid inactive lights and an inactive degenerate-aim emitter are accepted. No cancellation expectations change.

Actual checks before interruption: required source/directive reads; `agent_cycle.py check` and `next` exited 0 (structure/M03 queue only); `git diff --cached --check` exited 0; final Git/Python scope and clean-tree checks passed. A guessed StudyComputeInput.swift lookup failed, then the actual ReferenceStudy.swift definition was read.

No Swift compilation/tests/renders/benchmark, native or Metal run occurred. Runtime results remain unverified by W13.

Recovery reused this same context. Full exact source was resent from retained context and stored with GitHub create_blob only; the returned blob prefix matches the original committed diff. No new worker, filesystem retry, tree/commit/ref mutation or production change.
