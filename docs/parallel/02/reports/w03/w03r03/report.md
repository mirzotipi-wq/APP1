# W03R03 — unsupported orientation versus valid zero

PASS at `1b286885cb803ba17e159713651515ab119e17f1`, immutable snapshot `v1`; Swift 6.0.3, x86_64 Linux.

Six cases (point and directional × front/back/coincident camera) passed exact assertions. With subject (0,0,0) m, source (0,0,2) m and 400 cd, front camera (0,0,3) produced 100 lx; back camera (0,0,-3) produced exactly 0 lx with a valid black neutral card; coincident camera produced nil normal, nil illuminance and nil card. All scenes passed structural validation. Directional aim followed subject, giving emission cosine 1.

Source contract: `StudioOptics.swift:100–104,113–119` requires a camera-derived normal; `SurfacePhotometry.swift:9–17` rejects the zero vector and `:91–98` clamps negative incidence to zero. `Colorimetry.swift:165–179` preserves nil versus valid zero across the combined-card boundary.

Consumer boundary (read from Git because App is sparse): `App/StudioView.swift:991–1005` displays zero normally and nil as “Estimate unavailable”; `App/NeutralCardInspector.swift:34–41,122–139` displays a valid black card/zero readout versus “Meter unavailable.” No owner edits needed. Existing `StudioOpticsTests.testPointReceiverTracksCameraAndBackface` already covers the basic distinction; no duplicate test proposed.

Commands/results:
- `git status --short` initially clean; `git rev-parse HEAD` matched revision above.
- `python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w03r03 /tmp/keyfill02-r2-workers/w03r03/private-output/probe.swift v1` exited 0; **PASS 6 cases**; empty compiler log.
- `git show HEAD:App/StudioView.swift`, `git show HEAD:App/NeutralCardInspector.swift` confirmed consumer branches.

Artifacts: `probe.swift`, `compile.log`, `probe.log`, `scalar-references.md`. No package/native build, production changes or device/calibration claim. The 1% point/5% area gates remain unchanged; this bounded probe does not certify either full gate.
