# W03R07 — receiver-normal consumer trace

Revision: `1b286885cb803ba17e159713651515ab119e17f1`. Result: no normal mismatch in the audited solver, diagnostic UI/card, and plan export paths.

`StudioPhotometry.receiverNormal` normalizes **camera − subject**; point, directional, and rectangular branches pass that same normal to their receiver calculations (`StudioOptics.swift:97–136`). The target solver invokes this shared forward model for unit output, maximum output, and achieved output (`LightOutputAdjustment.swift:51,62,90`), so it cannot independently choose another plane.

Consumers agree: `App/LightTargetLuxView.swift:30,44,50,111` shows the shared current reading, invokes the solver, and explicitly describes a camera-facing plane at subject center. `App/StudioView.swift:990–997` labels and computes that same diagnostic plane. `NeutralCardPreview` validates the same normal and sums shared per-light illuminance (`Colorimetry.swift:157–178`); its sum remains distinct from a single-light target.

Export preserves the validated scene and resulting candela (`LightingPlan.swift:211–228`). Text records subject/camera XYZ and source settings (`:303–318`); PDF reads the same positions/settings (`App/LightingPlanPDF.swift:95–112`). Neither exporter computes lux or an alternative receiver normal. `git grep` confirms no `receiverNormal`, `illuminance`, or `lux` occurrences in either exporter. The plane is therefore derivable from exported geometry, but no explicit exported receiver-plane label exists. This is an informational limitation, not a contradictory lux claim; if export later adds lux, its owner should reuse `StudioPhotometry` and name the plane.

Evidence: `source-trace.txt` records immutable-revision commands, results, and numbered excerpts. Source inspection only; no builds, numerical accuracy measurements, device checks, or calibration claims. Point 1%/area 5% gates remain unchanged.
