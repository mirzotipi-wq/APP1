# W44 — private tiny-output implementation

- Worker: `/root/wave05/w44_implementation`; role: sole production writer.
- Input: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`, detached clean tree `/tmp/keyfill03-7f4b/workers/W44-implementation` before edits.
- Read: `AGENTS.md`, `docs/acceptance/m02-m03-code.md`, `docs/parallel/03/WORKER_PROTOCOL.md`, `agents/OPERATING_PROTOCOL.md`; source and original W42 public probe.
- Production edits began only after parent supplied the baseline receipt: unchanged W42 compiled with Swift 6.2.1 Linux `-O -parse-as-library`, compile exit 0, probe exit 1, 166 checks / 56 failures. This worker did not execute that run. Original failed evidence remains untouched.

## Patch

`ReferenceStudy.swift` normalizes only positive emitter output whose original per-sample candela is below `Double.leastNormalMagnitude`, including area shares already rounded to zero. Each contiguous tiny emitter is integrated at unit output, then its visible lux, unoccluded lux and XYZ are multiplied once by original candela and added to saved totals. Ordinary equations/order remain in the original accumulation path. Packed candela is restored before Float conversion. Sample count/order, area clipping, visibility, near-field guards, cancellation and mannequin code are unchanged.

`StudyTinyOutputTests.swift` adds five focused methods: mirrored grazing finite GGX point/directional unit linearity; full/clipped rectangle linearity at 64/1024 samples; ordinary/tiny mixed ordering; tiny-positive near-field rejection and zero-source omission; exact packed rows/geometry and Float32-zero output.

## Evidence and limitations

- Executed: `git status --short`, `git rev-parse HEAD`, `git branch --show-current`, `git log -3 --oneline`, `git diff --check`; clean initial tree, requested detached input, whitespace check exit 0.
- Executed independent Python binary64 arithmetic: original least-subnormal point lux/Y become zero; delayed scaling yields positive values; 16 quanta divided by 64/1024 becomes zero. Raw values in `wave05-evidence/W44-static-checks.json`. This is arithmetic evidence, not a Swift or renderer pass.
- Swift compile/tests, W42 rerun, native/GPU execution, timing and image parity: **UNRUN by W44**. Root owns serialized builds and must validate unchanged W42 plus focused/existing regressions before integrating. W50 independent challenge pending.
- Scope limitation: normal-range per-sample output can still underflow through sufficiently grazing cosine products; e.g. least-normal candela with cosine `1e-17`, squared distance `.0036`. This patch intentionally does not alter that ordinary path. Final subnormal quantization remains unavoidable.
- No commit, push, integration, fixture changes, cleanup, grandchildren, or interruptions.

## Deliverables

Persistent `docs/parallel/03/workers/wave05-evidence/W44-implementation.patch`, `W44-ReferenceStudy.swift`, `W44-StudyTinyOutputTests.swift`, and `W44-static-checks.json`. Source edits remain private; root integrates. Rollback: omit the two-file patch. Recommendation: run the frozen probe and focused suites, then independent challenge.
