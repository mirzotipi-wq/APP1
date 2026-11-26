# W03R08 — unsupported receiver-orientation text

**Revision:** `1b286885cb803ba17e159713651515ab119e17f1`. **Check:** one immutable-source trace through meter and target editing. `python3 private-output/source_check.py > private-output/execution.log` exited 0; 8/8 structural assertions passed. These are source assertions, not application tests.

Coincident camera/subject produces a zero direction rejected by `UnitDirection`; `StudioPhotometry.illuminance` consequently returns nil (`SurfacePhotometry.swift:9–15`, `StudioOptics.swift:100–118`). Supported back-facing incidence instead clamps to zero (`SurfacePhotometry.swift:92–98`). The independent scalar reference uses subject `(0,1.5,0)`, camera `(0,1.5,3)`, point source `(0,1.5,-1)`, 1000 cd: incidence −1 and expected 0 lx.

The meter explicitly branches to **“Estimate unavailable”** and geometry guidance for nil. A supported zero uses the numeric branch, compact `0.0 lx` in en-US and an exact numeric accessibility value (`StudioView.swift:989–1004`; `StudioMeterReadout.swift:9–29`). Both meanings have text, independent of color.

Target editing omits the current-value row for nil. A positive Apply throws `unsupportedGeometry`, whose fixed sentence reaches `Label(error, …)` through `localizedDescription` (`LightOutputAdjustment.swift:15–16,50–54`; `LightTargetLuxView.swift:30–38,56–60,112–125`). **Bounded wording gap:** the editor has no explicit unavailable-current status before Apply, and the generic geometry error does not identify coincident camera/subject.

Zero target intentionally sets candela to zero before sampling; it does not repair receiver orientation, so the meter still reports unavailable for coincident camera/subject. Error text contains no interpolated names/photos.

Exact commands, source hashes/excerpts, result JSON and scalar expectations are saved alongside this report. No production edits, builds, UI/VoiceOver/device execution, privacy-system audit, physical-calibration claim, or change to the 1%/5% gates.
