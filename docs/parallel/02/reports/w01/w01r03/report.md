# W01R03 — interfaces

Coordinator-condensed report; the worker’s full original is preserved in `interface_review_notes.md`.

Agent `/root/w01r01/r03_interfaces`; input `f150f98e35dd735927075aac4d2f8b02295c6a67`; isolated worktree `/tmp/keyfill02-workers/w01r03`.

## Findings

**P3 — early rectangular intensity underflow.** `SurfacePhotometry.swift:183` divides candela by1024 before distance amplification. Valid fixture: subject=(0,0,0), camera=(0,0,3), source=(0,0,0.05), 0.05×0.05m rectangle, automatic aim, 5600K, 1e-321cd. Python transcription returns supported0lx; analytic reference gives3.00313e-319lx. At1e-320cd error is16.225%. `ReferenceStudy.swift:249` shares this ordering. Scene validation accepts the positive input; neutral-card preview accepts computed zero. Magnitude is physically negligible. Root subsequently confirmed the Swift witness in `../../../evidence/baseline-rectangle-probe.txt` (reported separately from this worker’s execution).

**P3 — finite XYZ loses scale invariance.** `Colorimetry.swift:30–31` sums first: (1e308,1e308,1e308) produces overflowing sum and nil chromaticity, though (1/3,1/3) is representable. Scene-generated XYZ cannot reach this range. Display conversion of huge XYZ separately fails closed at its nonfinite guard; that is recorded as a range limit. Root subsequently confirmed actual Swift behavior in the baseline color probe.

## Contract map and outcome

Metres/normalized directions, on-axis candela, receiver lux, Kelvin, relative exposure2^stops, linear XYZ accumulation and encoded displayRGB remain distinct. Rectangle radiance is cd/area. Receiver is the subject-centre camera-facing plane. `StudioPhotometry` validates its selected light and needed geometry; whole-scene consumers (`NeutralCardPreview`, adjustment and `StudyLighting`) validate the full scene. Ordinary unsupported geometry propagates as nil/errors/render masks. No ordinary-range mismatch established.

Commands: `git rev-parse HEAD`, source/doc/test `cat`/`nl`/`rg`, `python3 private-output/probe_interfaces.py` (two successful iterations), final status/diff inspection. Full command log includes corrected missing-path reads. Probe script/results retained. UnitDirection huge/subnormal normalization checks passed. Swift tests were read only by this worker; no builds/installations/network writes/source edits/commits. Source clean; only private-output untracked.
