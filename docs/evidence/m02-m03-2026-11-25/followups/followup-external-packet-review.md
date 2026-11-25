# External acceptance packet review

**Approved as an unexecuted preparation packet**, with two measurement-definition clarifications recommended before physical capture. Read-only review of `docs/acceptance/m02-m03-external-evidence.md` and `docs/acceptance/m02-m03-capture-manifest.json`; no execution, network or product edits.

## Verified

- JSON parses. Exactly twelve unique, consecutive scene records R01–R12 use the same field structure. All scene observations remain null/empty; planned setup/coverage are explicitly labeled.
- All 25 status fields are `not_run`; every outcome, observation, tested revision, captured/reviewed time and measured result is null. Nine accessibility tasks cover all six protected capabilities. The preparation revision is not passed off as a tested revision.
- `docs/QUALITY.md` and `docs/ROADMAP.md` are byte-identical to `d99c9bd`. Rendering coverage, independent photographer review, physical baseline/durations/performance thresholds, and manual real-device accessibility remain intact. M03 persistence is correctly separate from M07 physical-device coverage.
- The procedure is actionable: rights, measured geometry/camera/light quantities, calibration and assumptions, original/processed artifacts, backend, continuous-interaction recording, independent review, defects and retests are recorded. Synthetic, simulator and source-review substitutes are explicitly excluded from external acceptance.
- The packet acknowledges current model limitations and directs operators to retain failures. It invents no image-similarity threshold, physical calibration result, device measurement, human finding or milestone pass.

## Small clarifications

1. **Memory units:** the current `mbConversion` field and “MB conversion used” leave decimal/binary interpretation to the operator. Define MB as bytes / 1,000,000 for the unchanged 350 MB comparison; permit separately labeled MiB. Keep raw resident bytes. This prevents an accidental 4.86% threshold expansion.
2. **Frame measurement definition:** record the exact measured app-frame quantity and timestamp source, including whether it represents presentation intervals or CPU/GPU work. Explicitly separate it from standalone Study render latency. A `frameTimeDefinition` field would make this easy to preserve alongside tool/version and raw samples.

No formal JSON Schema or additional test gate is necessary for this blank capture template. Operator-supplied procedure/rig records remain required actual inputs, not missing implementation work. No further blocking issue found.

## Clarifications resolved

Focused reread confirms the protocol now defines MB as bytes / 1,000,000, permits separately labeled MiB without changing the threshold, and distinguishes presented-frame cadence from CPU/GPU/Study latency. The manifest adds `performance.timing.measuredQuantityAndMethod: null`. Both recommendations are resolved. **Scoped acceptance: ready as an unexecuted external capture packet; no remaining review finding.** This accepts preparation quality only and supplies no gate-execution evidence. Root reports the separate ARCHITECTURE correction; that change was outside this focused packet reread.
