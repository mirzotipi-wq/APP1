# M02/M03 external acceptance packet

**Status: prepared, not executed.** This packet collects evidence for the existing
[quality contract](../QUALITY.md). It does not change that contract, grant an
exception, or count as a device test or photographer review. The accompanying
[capture manifest](m02-m03-capture-manifest.json) deliberately contains `null`
observations and `not_run` statuses. Preserve that distinction when filling it in.

The preparation baseline is `d99c9bdfc1b3c1a185d87079efcc62cd34049279`.
Record the actual tested revision in each result; later changes can invalidate an
earlier result. The [engineering evidence](../evidence/m02-m03-main-2026-11-25.md)
tracks automated results and unresolved failures separately.

## Required evidence and operator

| Gate | Existing acceptance requirement | Evidence to collect |
|---|---|---|
| M02 rendering | Twelve rights-cleared controlled scenes; calibrated comparison; independent photographer review; no clipping, flicker or obvious geometry errors in required cases | Rights records, measured rig and camera records, authorized reference captures, matching app output, comparison notes, actual reviewer findings |
| M02 performance | Physical iPhone 13 or agreed baseline; Release; standard portrait with three lights; target 60 fps; p95 frame time at most 20 ms over five minutes after warmup; fifteen-minute thermal test; peak resident memory at most 350 MB; no critical thermal state | Device/build/settings record, workload definition, unfiltered timing samples, resident-memory samples, thermal-state timeline, trace and calculations |
| M03 accessibility | VoiceOver, Dynamic Type, contrast, non-color cues, numeric editing and reduced motion; manual audit on a real device | Device/settings record, completed task observations, recordings or screenshots where useful, defect and retest references |

The photographer must supply an actual independent review. An agent review,
synthetic image, simulator screenshot or blank form cannot supply it. The device
operator can also conduct the manual accessibility audit, provided the record
states who performed it and what was actually exercised.

M03 persistence is a separate engineering gate. Its interruption requirement does
not itself mandate physical hardware. Host interruption and rename-failure
receipts belong with the automated evidence. The broader physical low-storage
and device matrix belongs to M07; it is not added here as a new M03 requirement.

## Twelve-scene capture plan

These are proposed capture assignments, not completed fixtures. Freeze the final
scene list and comparison method before judging results. Keep failures and any
replacement rationale. Every selected case needs its own authorized capture,
measured setup and matching app scene; changing a label does not create a case.

| ID | Proposed controlled setup | Coverage to inspect |
|---|---|---|
| R01 | One hard key, front three-quarter portrait | Key direction, skin/material, hard facial and cast shadow |
| R02 | One soft key, same subject and camera as R01 | Modifier dimensions and distance, soft transitions, shadow extent |
| R03 | Hard key and weaker fill | Key/fill balance, shadow detail, distinct source roles |
| R04 | Soft key and fill | Soft-source balance, facial form, skin/material |
| R05 | Key and hard rim | Rim side and extent, silhouette, occlusion |
| R06 | Key and soft rim | Broad rim, edge transition, modifier placement |
| R07 | Three-light key/fill/rim portrait | Complete standard rig, source identity, camera framing |
| R08 | Mirrored measured three-light rig | Left/right geometry, aiming, corresponding shadow changes |
| R09 | Elevated key with measured downward aim | Vertical geometry, facial and floor shadow placement |
| R10 | Rolled rectangular modifier near a grazing view | Emitter orientation, partial illumination, temporal continuity |
| R11 | Mixed-temperature key/fill with neutral and color targets | Recorded white balance, neutral reference, supported color limits |
| R12 | Hard/soft sources with visible diffuse and glossy materials | Material response, occlusion, cast-shadow shape |

### Capture and comparison procedure

1. Record permission or license, rights holder, permitted uses and a local evidence
   path for every reference. Record model authorization when applicable. Keep
   source images in the operator's authorized storage; this packet performs no
   upload or outreach.
2. Record scene units and axes, subject and camera position, camera model/lens,
   focal length, exposure, white balance, image color profile, room/background,
   each light's position, aim, output setting, temperature, modifier dimensions
   and roll. Preserve the native app scene and its checksum. Record which light
   quantities were measured and which remain assumptions; electrical watts are
   not the app's candela input.
3. Describe the calibration procedure and instruments, including meter/target
   identity, calibration record and uncertainty when available. Capture the
   neutral/gray and color references needed by that procedure. Retain source
   captures and processing settings so a reviewer can reproduce the comparison.
4. Record the app view and rendering backend. Match camera/framing, geometry,
   source assumptions and comparison exposure/white balance. Preserve original
   app output and any comparison transform separately. Use one declared method
   across the fixture set; disclose any case-specific correction.
5. Inspect the required skin/material and shadow coverage, geometry, highlight
   clipping and light transitions. For flicker, retain an actual recording of
   the relevant continuous interaction; a still cannot demonstrate continuity.
   Record unsupported inputs and disagreement plainly.
6. Have the independent photographer review the complete set, state their role
   and independence, and record per-case findings and an overall conclusion.
   A defect needs its failed artifact and a linked retest at the corrected
   revision. Do not replace a failed comparison with a synthetic substitute.

Current views have explicit modeling limits. The 3D adapters are illustrative;
the Study sphere and neutral mannequin use ideal lighting/material assumptions.
They are not calibrated skin or measured equipment profiles. Numerical fixture
agreement does not establish agreement with a real portrait. If the required
comparison cannot pass with the current model, retain the failure and describe
the missing capability; leave the gate open.

## Physical performance run

Record the actual device model, OS, build configuration, full source revision,
tool/version, app settings, ambient conditions, power/charging state and thermal
state before starting. If a baseline other than iPhone 13 is used, link the
existing agreement; this packet does not approve a replacement baseline.

Freeze the standard portrait scene with exactly three lights and save its
checksum. Describe the actual app view, backend, resolution and interaction
schedule. Use the real interactive workload. Host CPU rendering time, a cache-hit
loop or a simulator measurement cannot substitute for this physical run.

Warm up the chosen workload and record the warmup interval. Then capture at least
five uninterrupted minutes of frame timing, keeping all samples and recording
the measurement method. Identify the measured quantity explicitly: presented-frame
intervals describe visible cadence; CPU/GPU durations and Study compute latency
are separate diagnostics and must not be substituted for that cadence. Report
sample count, elapsed duration, target/observed
frame rate and p95 frame time. State the percentile calculation; for nearest rank,
sort the samples and select the one-based element `ceil(0.95 × count)`. Preserve
missed frames and outliers. Record any pause, interruption or instrumentation
effect so the result remains interpretable.

Run the workload for fifteen minutes while recording resident memory and thermal
state. The five-minute timing window may fall within that longer run if its
boundaries and warmup are explicit. Report peak resident bytes, MB as bytes divided
by 1,000,000, and every observed thermal-state change. MiB may be shown separately;
do not relabel it MB or change the 350 MB threshold. Record the cadence and coverage
of the memory/thermal samples; a final snapshot is not a peak measurement.

The quality contract's comparison values remain 60 fps target, p95 at most 20 ms,
peak resident memory at most 350 MB, and no critical thermal state. Record each
observed result and pass/fail assessment independently. Keep the raw trace and
samples even when one result fails. Any optimization retest uses the same
declared workload and settings, with both revisions retained.

## Manual device accessibility tasks

Use a physical device and record its model, OS, source revision, text size, display
mode, VoiceOver state, Reduce Motion state and any other setting used. The table
is a concrete coverage plan for the protected accessibility requirements; it is
not evidence until an operator records observations.

| Task | Observe and record |
|---|---|
| Navigate Projects and open a saved rig with VoiceOver | Useful names, focus order, active/archived identity and complete action labels |
| Select and move a light through accessible numeric controls | Selection announced, units and allowed range understood, value change retained |
| Open exact editing, apply a valid value, reject invalid input and cancel | Field/units, error announcement, keyboard reachability, Apply/Cancel, preservation of unchanged values |
| Change a preset, adjust a slider, Undo and Redo | Distinct actions and values announced; history restores the expected edit |
| Save, reopen, duplicate and archive/recover a project | Confirmation/status is understandable; focus remains useful; unrelated records remain intact |
| Increase Dynamic Type through the supported settings | Text remains readable; essential controls and labels remain reachable; no clipped required content |
| Inspect light and dark appearance and selection/error states | Contrast, labels, shapes and other non-color cues communicate meaning |
| Enable Reduce Motion and use navigation/preview controls | Motion respects the setting without preventing the task |
| Use the overhead plan and its light list at large text sizes | Displaced/omitted captions have useful accessible alternatives and stable selection |

Retain the exact failing task, observed behavior and useful recording/screenshot.
Link each repaired defect to its retest. Automated accessibility audits support
this work but do not replace the manual real-device audit.

## Recording the outcome

Copy the manifest into a dated evidence directory before entering observations.
Replace `not_run` only after execution, and fill in actual source/tool/device and
artifact references. Hash the raw artifacts after capture. A missing, blocked or
inconclusive result remains unverified; explain why in its notes.

When the evidence is complete, reconcile it with the engineering receipts in
`agents/evidence.json`, `agents/state.json` and `agents/HANDOFF.md`. M02 requires
all of its gates; M03 also depends on M02. Successful CI or a filled-in manifest
alone does not complete either milestone.
