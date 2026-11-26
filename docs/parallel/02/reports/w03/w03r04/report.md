# W03R04 — directional double-cosine analytic regression

**Disposition: useful coverage gap; candidate passes.** Source and immutable snapshot v1: `1b286885cb803ba17e159713651515ab119e17f1`. Swift 6.0.3, x86_64-unknown-linux-gnu.

Existing `StudioOpticsTests` checks receiver and emitter cosine separately. `PhotometryInvariantTests` uses a mixed-rig baseline and `ReferenceStudyTests` compares production paths; none provides an independent absolute oracle with both directional factors non-unit. Candidate `DirectionalDoubleCosineTests.swift` adds one focused test.

Translated fixture: subject (1,1,-2), source (1,1,3), aim (5,1,0), camera (1,4,2), 1250 cd. Two independent 3–4–5 triangles give emitter cosine 3/5, receiver cosine 4/5, and squared separation 25 m². Expected E=(1250/25)(3/5)(4/5)=**24 lx**. Actual Swift: **24 lx**, absolute and relative error **0**. Omitting one factor yields 40 or 30 lx, so this fixture detects either omission. Oracle uses no production geometry/photometry helpers.

Command:
```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w03r04 /tmp/keyfill02-r2-workers/w03r04/private-output/probe.swift v1
```
Result: exit 0; 1 XCTest executed, 0 failures. Probe embeds the unchanged candidate assertion plus a scalar diagnostic print and XCTest runner. Tolerance 1e-10 lx preserves the 1% point gate; 5% area gate unchanged.

Artifacts: candidate, `probe.swift`, `probe.log`, `compile.log`, and `scalar-reference.txt` in this private-output directory. No production edits or package builds. This verifies one ideal directional fixture on Linux, not the full package suite, equipment calibration, or device behavior.
