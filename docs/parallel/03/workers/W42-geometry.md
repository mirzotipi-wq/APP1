# W42 geometry/data — positive tiny Study output probe

- Worker: `/root/wave05/w42_geometry`; input/private HEAD verified: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`.
- Private tree: `/tmp/keyfill03-7f4b/workers/W42-geometry`; private output: `/tmp/keyfill03-7f4b/builds/W42-geometry`.
- Read: `AGENTS.md`, `docs/acceptance/m02-m03-code.md`, `docs/parallel/03/WORKER_PROTOCOL.md`, `agents/OPERATING_PROTOCOL.md`, actual `Sources/LightingCore/ReferenceStudy.swift`, and existing Study tests.
- Artifact: `docs/parallel/03/workers/wave05-evidence/W42-positive-tiny-study.swift`. One standalone executable using public `StudyLighting`; no production edits or changed fixtures.

## Frozen hypothesis and acceptance

The baseline initializes rectangle per-cell candela before summation and multiplies point/directional candela by cosines before inverse-square amplification. These intermediate values can round to zero even when the final lux and material signal are positive representable Doubles.

Six fixed fixtures cover full/clipped 0.1 m square rectangles at both 8×8 and 32×32, plus tilted point/directional GGX. Rectangle input is 16 least-positive subnormal quanta; scalar input is one. Every receiver has 0.06 m separation, above the 0.05 m point and rectangle guards. The grazing reflected view satisfies N·L=N·V=0.1, H=N. Expected lux/XYZ scale from a unit-output public-API evaluation; scalar lux and Y additionally use independent inverse-square/cosine and symmetric GGX formulas. Positive representable expectations must remain positive, finite, and within a frozen 1% or four-subnormal-ulp bound. A physically unrepresentable diffuse component may be zero.

## Execution and exact root command

No Swift build, probe execution, native test, render, or physical validation was run by this worker; root owns serialized execution. Baseline failure is a source-supported hypothesis until root executes the unchanged probe. Preserve all failing baseline output before fixes.

Run from the exact private input tree; use a distinct binary/log for the later fixed tree:

```bash
/workspace/scratch/13a77d3f98df/toolchain/usr/bin/swiftc -O -parse-as-library Sources/LightingCore/*.swift /workspace/scratch/7f4be4bbb2d6/APP1-lane03/docs/parallel/03/workers/wave05-evidence/W42-positive-tiny-study.swift -o /tmp/keyfill03-7f4b/builds/W42-geometry/W42-baseline
/tmp/keyfill03-7f4b/builds/W42-geometry/W42-baseline > /workspace/scratch/7f4be4bbb2d6/APP1-lane03/docs/parallel/03/workers/wave05-evidence/W42-baseline.log 2>&1
```

Actual checks: clean private status; exact SHA; source/API inspection; JavaScript IEEE-754 arithmetic sanity check only, retained in `W42-arithmetic-sanity.json`. This JS check is not Swift or shipped-API execution. No toolchain changes, commits, push, cleanup, grandchildren, or shared fixture edits. Initial search named three nonexistent model filenames; located actual `Scene.swift` and `StudioOptics.swift` using rg. Combined read output was truncated; bounded source reads recovered the required evaluator. No tree interruption observed. Token counters unavailable. Root must execute baseline and fixed probes before claiming a pass.

Canonical evidence location corrected at the wave leader’s request; the earlier copies under `docs/parallel/03/wave05-evidence` remain preserved. Probe source and expectations are unchanged.
