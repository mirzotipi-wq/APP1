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
  regressions were added; all three passed in Debug and Release at the first
  published checkpoint, as recorded below.
- The AR manual-measurement sheet rejects delayed writes that would reopen a
  retired presentation. The existing permission and tracking state machine is
  preserved.
- PDF export controls adapt to large text and short windows. Paper, units, Share
  and retry controls can scroll independently of the PDF preview. Snapshot and
  request-adoption behavior remains intact. Native layout verification is pending.

## Second implementation checkpoint

- The shared photo-session observer now performs idempotent terminal cleanup
  when SwiftUI removes its controller, including removal without a UIKit
  dismissal transition. Temporary covering by a picker remains distinct.
  Two focused native regressions cover the cleanup receipt and retained-photo
  lifetime. Workers 014 and 016 implemented and independently reviewed this.
- CI retains the existing checked unsigned arm64 Release app as a separate ZIP,
  with source/toolchain identity, bundle metadata, size and SHA-256. Packaging
  validates ZIP integrity and the included Info.plist, preserves failure logs
  separately and adds no compilation or signing step. Worker 017 identified the
  missing artifact; root implemented it and 025 independently reviewed it.
- A validated complete source revision appears in Settings and optional beta
  feedback metadata. CI stamps both the app and UI-test bundles with the actual
  checkout SHA; the UI fixture derives its expectation independently from the
  test bundle. The device check compares the embedded value with Git before
  packaging. Missing or malformed revision metadata remains unavailable.
  Workers 028 and 032 implemented and reviewed the app, core and CI wiring.

Device ZIP packaging, source-stamp propagation and new native cleanup tests remain
unverified on an Apple host at this checkpoint. Both additional portable
source-metadata regressions passed in Debug and Release at `c19d5f8`.

## Built-artifact metadata repair

Actual inspection of the uploaded `c19d5f8` Debug simulator application found that
Xcode omitted both custom metadata keys. Source review and compilation had not
proved propagation. The [failure and repair record](build-metadata-repair.md)
retains the original plist and exact artifact checksums. The candidate replaces
the arbitrary generated-key settings with explicit plist inputs and checks the
actual app/UI-test bundle metadata before simulator startup. Nine local guard
witnesses pass, including rejection of the actual faulty plist; fresh Apple
build propagation remains required.

## Validation and limits

Local environment: Linux; neither Swift nor Xcode is installed. `git diff --check`,
agent-state structure, native UI class partition, privacy-manifest and app-icon
checks passed. YAML, embedded Python and the changed shell commands parse. These
checks do not compile Swift or exercise native UI.

Published first checkpoint `c9b46a3` has an exact tree match with local `63131a9`,
recorded in [publication-01.json](publication-01.json). Its complete portable
[job](https://github.com/mirzotipi-wq/APP1/actions/runs/46061357326/job/140718057890)
passed: 602 distinct test methods each passed once in Debug and once in Release,
with zero failed method events; 120 tooling tests passed. All twelve synthetic
fixtures reported zero unsupported pixels; six shared-kernel and eight strict
precision cases passed. These numerical outputs are not a new visual or device
acceptance claim. The [extracted receipt](checkpoint-01-core.json) retains the
actual method and fixture evidence. The second source push cancelled its
native/UI jobs; [terminal job states](checkpoint-01-jobs.json) preserve those
outcomes. No native/UI acceptance is inferred from cancelled work.

Published second checkpoint `c19d5f8` has an exact tree match with local `b24caf6`,
recorded in [publication-02.json](publication-02.json). Its fresh
[run 46063267130](https://github.com/mirzotipi-wq/APP1/actions/runs/46063267130)
passed its portable job: **604 distinct methods in Debug and the same 604 in
Release, zero failed methods, and 120 tooling tests**. The
[reconciled receipt](checkpoint-02-core.json) identifies three original downloaded
ZIP artifacts by their verified SHA-256. These retain the test logs, all twelve
scene/image pairs, numerical parity results, raw benchmark samples and actual
Linux write/recovery failure evidence. Eight frame and four visibility workloads
contain seven measured samples each; all twelve cancellation probes observed
cancellation, and all reported p50/p95 values were independently recomputed.
Worker 057 independently reviewed all twelve actual outputs; the
[visual receipt and lossless contact sheets](checkpoint-02-visual/README.md)
retain those source-bound observations. No visible geometry, shadow, color or
exposure defect was found at the declared fixture resolutions.
Actual prior/candidate/recovery archive bytes were checked against the required
preservation relationships. These ext4 host results do not establish device
power-loss behavior. Apple/native/UI jobs remain in progress.

The [261-input source manifest](checkpoint-02-inputs.json) binds application,
resources, tests, tooling and CI to `c19d5f8`. The tester-guide update changes only documentation. The subsequent metadata
repair changes four build/configuration inputs; portable package and test inputs
remain byte-identical. Native results must be tied to the repaired source.

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
