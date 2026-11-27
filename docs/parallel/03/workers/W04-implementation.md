# W04 implementation — wave 01

Runtime ID/canonical task: `/root/wave01/implementation`.
Assignment: bounded read-only CPU sphere/panel intersection and lighting review; exclude the known mannequin determinant defect.
Input SHA: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Worktree: `/tmp/keyfill03-7f4b/workers/W04-implementation` (clean detached HEAD).
Status: complete. Commit: none. No source edits, builds, renders, downloads, arithmetic probes or children.

## Result

**No additional actionable candidate established.** No minimal reproduction is proposed without an established counterexample. This conclusion is source inspection only.

Evidence reviewed in `Sources/LightingCore/ReferenceStudy.swift`: material validity/GGX response at lines 24–49; geometry bounds and sphere/panel intervals at 62–93; clipped-area weighting at 120–211; validated sample preparation at 228–265; near-field checks, visibility and accumulation at 285–369; camera/resolution prerequisites and pixel path at 447–458 and 479–533. Validated coordinate/intensity bounds appear in `Sources/LightingCore/Scene.swift:3–16,33–36,62–80`.

Test source cross-checks (not executions): `Tests/LightingCoreTests/ReferenceStudyTests.swift:17–156` covers analytic signal, convergence, sphere penumbra, GGX, invalid inputs and rendering. `Tests/LightingCoreTests/StudyEmitterFacingTests.swift:37–169` covers facing/translation, guards and mixed-source indexing. `Tests/LightingCoreTests/GrazingStudyContinuityTests.swift:64–242` covers clipping continuity, weights, visibility/material preservation and packed alignment. No new failure follows from this bounded review.

## Commands and actual checks

Every shell invocation set `TMPDIR=/home/agent/keyfill03-7f4b/tmp`.

- `git status --short --branch`, `git rev-parse HEAD`, `git log -5 --oneline`: clean detached input confirmed.
- `cat`, `nl -ba`, `sed -n`, `wc -l`, bounded `rg -n`/`rg --files`: required protocols/documents, source and tests read. One `rg` lookup exited 2 for nonexistent `Sources/LightingCore/LightOptics.swift`; lookup error only.
- `python3 scripts/agent_cycle.py check`: exit 0; validates ledger structure/references only.
- `python3 scripts/agent_cycle.py next`: exit 0; M03 editing/accessibility/persistence outstanding.
- Swift/package/native tests actually run: **none**. No historical pass or source match counted as execution.

Private build-output directory unused. Root owns integration/runtime validation.
