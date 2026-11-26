# W23 — API/domain review

- Actual runtime/task ID: `/root/wave03/api`; parent `/root/wave03` (W21).
- Pinned input: `1cefc654630a86ab320e58283957f4e91d6cbce6`; tree `890c0472d1f56ab36f6c17110c1f759937ee1211`.
- Private detached worktree: `/tmp/keyfill03-7f4b/workers/W23-api`; initially and finally clean.
- Result: no new supported-domain API regression found by source review. No source changes; no integration blocker identified.

## Findings

1. Public signatures/defaults are unchanged. Only private `StudySetup.init` gains cancellation; `StudyComputeInput` retains its default false closure.
2. The mesh is internal, with fixed bounded geometry. Its cutoff scales twice-area by `1e-14`, expressing angular parallelism for unit rays. Camera rays normalize in `PortraitStudy.swift:193`; shadow segments normalize after offset in `ReferenceStudy.swift:319`. The 5 cm sample guard and 10 µm offset prevent zero shadow lengths in this domain. Cached normals use the same cross product/length as before.
3. Both mesh queries retain `t >= minimum && t < maximum`, including tie handling. Infinite maximum is intentional; empty/reversed/NaN bounds cannot satisfy endpoint comparisons. Arbitrary nonunit/nonfinite SIMD calls have no general defensive guarantee. Public positions are finite/bounded; camera framing validates positions, and lighting validates all scene data before samples, including inactive lights. No broader input contract is inferred.
4. Sphere setup now orders resolution → cancellation → camera → scene/emitter preparation, matching portrait. Precancellation intentionally outranks camera/scene errors, while invalid resolution wins without polling. Preparation remains uninterrupted after a false initial poll. Pixel/final checks are unchanged.
5. Read geometry tests for the preserved witness, 24 near-tangent cases, normals and exact endpoints; cancellation tests for precedence/eight-pixel/final checks; boundary tests for malformed scenes and emitter ordering. None were executed by W23.

## Checks actually run and limitations

Read all four assigned directives and relevant source/tests using `cat`, `sed -n`, and `rg -n`. Exact checks included `git rev-parse HEAD`, `git rev-parse HEAD^{tree}`, `git status --porcelain=v1`, `git branch --show-current`, and `git diff HEAD^ HEAD --unified=0 -- Sources/LightingCore/PortraitHeadMesh.swift Sources/LightingCore/ReferenceStudy.swift Sources/LightingCore/PortraitStudy.swift`. Two guessed file lookups exited 2; repository-wide `rg` resolved them.

Ran `python3 /tmp/keyfill03-7f4b/builds/W23-api/contract_arithmetic.py`: exit 0; witness norm 1.0; four determinant examples and endpoint assertions passed. Arithmetic only, not Swift/mesh validation. Script/output: `workers/wave03-evidence/W23-api/contract_arithmetic.{py,json}` relative to `docs/parallel/03`. No builds, Swift tests or rendering. Root's 380 Debug/380 Release results are not W23 execution. No arbitrary-angle completeness or physical-validation claim.
