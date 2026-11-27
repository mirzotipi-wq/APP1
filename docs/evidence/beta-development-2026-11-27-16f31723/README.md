# Beta development — 27 November 2026

## Scope and baseline

This request uses 100 new actual specialist runs. The integration lead is not
counted. Workers 001–011 are direct specialists; 012 coordinates 013–100 under
the four-context runtime limit. The [worker ledger](worker-ledger.json) records
actual creation and completion separately. Earlier requests are not counted.

Baseline: `14d33cd336944a3d2772ced9822aef57d565d89e`. Destination: `main`.
Goal: improve the existing complete portrait-planning workflow through concrete
production fixes and independent review. Protected release requirements remain.

## First implementation checkpoint

- Reference, arrangement and target-lux editors now ask the session to accept a
  proposal before consuming the draft. Rejection keeps the current values and
  reference photograph, with inline feedback. Synchronous duplicate application
  guards remain active. Worker 009 found a missing reference guard during review;
  correction `14a4c0c` was reviewed before publication.
- Save/reload/recovery success messages belong to the exact editor revision and
  project. Edits, Undo and Redo cannot display an obsolete success claim. Error
  messages remain until resolved. Feedback appears next to the persistent Save
  controls, with full details available separately. Three focused session
  regressions were added; their execution is pending.
- The AR manual-measurement sheet rejects delayed writes that would reopen a
  retired presentation. The existing permission and tracking state machine is
  preserved.
- PDF export controls adapt to large text and short windows. Paper, units, Share
  and retry controls can scroll independently of the PDF preview. Snapshot and
  request-adoption behavior remains intact. Native layout verification is pending.

## Validation and limits

Local environment: Linux; neither Swift nor Xcode is installed. `git diff --check`,
agent-state structure, native UI class partition, privacy-manifest and app-icon
checks passed. These checks do not compile Swift or exercise native UI.

At baseline, [run 46057140877](https://github.com/mirzotipi-wq/APP1/actions/runs/46057140877)
passed portable core and the five initially running UI bundle builds. Its UI
execution and remaining jobs were still pending when inspected; the
[baseline snapshot](baseline-ci.json) preserves that observation. Baseline results
do not certify this candidate. Fresh changed-source builds, session tests and
Default/AXXXL native workflows remain required.

Document-provider reads and most AR lifecycle protections already exist and were
reviewed without speculative rewrites. Unsaved edits are still explicit-save:
there is no process-crash recovery journal. Worker 010 describes the separate
bounded, multiwindow-aware slice needed to add that safely.

M01 remains active; no milestone or beta-release gate is promoted by these source
reviews. There is no signed archive, physical-device acceptance, configured
StoreKit transaction, TestFlight upload, or release approval in this packet.

## Review records

Individual reports are in `workers/`. The ledger and this packet are updated at
coherent checkpoints while implementation continues. An unrun test is not a pass.
