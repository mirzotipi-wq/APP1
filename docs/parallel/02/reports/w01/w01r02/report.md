# W01R02 — units and invariants review

Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Read-only source review; no Swift execution.

**Outcome:** no ordinary-range photometric defect found in the reviewed scope. Independent Python transcriptions checked 136 rectangle cases against separate vertical-slice quadrature (maximum relative error **0.0408064%**), seven parallel analytic cases (**0.0257085%**), and eight geometric-similarity cases (zero measured error). These are numerical-review evidence, not passing Swift tests or physical calibration.

## Prioritized findings

1. **P3, extreme accepted intensity:** `SurfacePhotometry.swift:183–194` divides intensity among 1024 cells before integration. Reproducer: rectangle centered at origin, right +X/up +Y, width=height=0.05 m, onAxisCandela=`Double.leastNonzeroMagnitude`, receiver=(0,0,0.05), normal=−Z. The transcribed implementation returns 0; the rounded closed-form answer is approximately `1.487e-321` lx. Early division underflows despite a representable final result. Physically negligible; `LightOutputAdjustment.swift:85–94` already recognizes/rejects integration underflow. A normalized geometry integral multiplied by candela afterward would preserve more range. Swift reproduction remains unrun.

2. **P3, lane01 out-of-ownership request:** `Scene.swift:97–99` accepts finite distance `1e155` m and 100000 cd, then returns 0 because distance² overflows. A Decimal reference gives representable `1e-305` lx. Consider `(candela / distance) / distance` or an explicit supported upper bound. **Unreachable through scene positions** (each coordinate is bounded to ±100 m); no ordinary scene severity.

## Invariant map

Point: `E=I·max(0,nᵣ·toSource)/r²` lx. Directional: add `max(0,nₑ·toReceiver)`; this is a cosine emitter. Rectangle: `L=I/(wh)` cd/m² and `E=∫L·cosₑ·cosᵣ/r² dA`. Fixed-output similarity gives `E′=E/s²`; arbitrary distance changes alone do not obey inverse-square in the finite-source near field. No core lumen conversion exists: angular integration implies `Φ=4πI` for isotropic point and `Φ=πI` for one-sided cosine/rectangle. See `invariant_map.md` for falsifiable boundaries and line references.

## Commands and limits

Ran `git status --short`, `git rev-parse HEAD`, read-only `cat`/`nl`/`rg`/`git grep` inspections, and `python3 private-output/invariant_probe.py` (exit 0). Initial filename guesses and sparse `App` search reported missing paths; later searches used actual files and `git grep HEAD`.

Artifacts: `invariant_probe.py`, `invariant_results.json`, `invariant_map.md`. Final `git diff --exit-code` succeeded; only `private-output/` was untracked. No build, Swift/package toolchain, installation, network research/write, source modification, commit, or push. Existing Swift tests were read, not executed. Root separately reports a corroborating Swift rectangle witness at `/tmp/keyfill02/docs/parallel/02/evidence/baseline-rectangle-probe.swift` and `.txt`, plus 366 passing baseline tests; this worker did not run or inspect that evidence. Review does not establish native, GPU, or physical accuracy.
