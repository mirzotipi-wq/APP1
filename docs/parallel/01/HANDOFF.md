# Lane 01 final handoff — architecture and app composition

## Delivery and acceptance

The ten-wave implementation is complete on `finish/01-architecture-composition`.
Exactly **100 actual fresh contexts** performed the ten required roles in ten
waves. Returned agent IDs, assignments, source revisions, reports, preservation
and cleanup records are in [WORKER_LEDGER.json](WORKER_LEDGER.json) and the ten
wave ledgers. Followups count zero; the root coordinator is not counted.

The final tested code is **`ce9f7aabd2de935c933468a00f007604ed7ea6ca`**, tree
`7e02b41c9df248f84207afb5599cb2cdf76ded7d`. The final publication adds only
lane-01 documentation, reports and evidence to this code. Local and CI portable
checks pass at that exact published code revision. **Native acceptance remains
unverified**, and three producer APIs still prevent complete rejected-draft
retention. Those are explicit integration dependencies below.

The inspected campaign baseline is `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Latest inspected main is `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. The bounded
origin inspection advertised finish lanes 01–05 and no lane-20 ref. Earlier
BASE_SHA searches were limited to inspected campaign paths; metadata elsewhere
was not surveyed. Lane 20 must preserve later main changes during integration. Only this lane's branch was pushed.
CI configuration remains lane 19's responsibility; canonical status and final
main integration remain lane 20's.

## Architecture delivered

| Owner | Responsibility and resulting behavior |
|---|---|
| `StudioEditorState` | Owns the validated scene, live UUID selection, revision identity and undo history. Invalid changes are atomic. A no-reset receipt cannot replace scene content beneath retained history. |
| `StudioFieldCommand` | Separates typed control mutations from rendering. Resolves the addressed live light and validates the complete changed payload; arbitrary scene/adoption boundaries still receive full validation. |
| `StudioSession` | Owns each window's editor, library, saved snapshot, project-operation reservation/task, Plan gesture and active feature presentation. Reserves before edit teardown and validates prospective receipt adoption before publishing state. |
| `StudioFeatureContext` / `StudioFeaturePresentation` | Carry immutable opening identity/snapshot and the live acceptance receipt. Distinguish logical workspace identity from storage generation and reject foreign owners, obsolete revisions and retired callbacks. |
| `StudioFeatureSheets` | Connects reference, arrangement, target-lux, room and AR through one session-owned presentation. Uses matching teardown, immutable one-shot inputs and live room/AR inputs. |
| `StudioAdaptiveLayout` | Supplies one stable header/action subtree while delegating geometry to native horizontal/vertical stacks. Accessibility forces only the outer header into a column; inner actions continue to fit by width. |

`StudioView` is reduced from 1,537 to 1,240 lines against the common baseline.
The extraction removes seven duplicate feature route fields and transfers
editor, operation, gesture and presentation ownership to cohesive types. It
retains the portrait-lighting workflow and existing feature implementations.
`Scene.swift`, `KeyAndFillApp.swift`, `project.yml`, scene/document codecs, CI and
other feature-owner files are unchanged. The non-documentation diff consists of
20 scoped composition, package and regression files.

### Scene, selection and undo invariants

Supported schemas 1–5 continue through existing scene validation. Stable UUIDs,
SI values, optional default representation, optical roll and manual versus
automatic aim remain intact. A removed selection falls back to a remaining live
light; an empty rig has no selection. Undo does not steal an existing valid
selection. Invalid or effective no-op commands preserve revision, redo and the
active edit owner.

Every actual scene change and undo/redo receives a new revision token. Equal
content after undo cannot revive an old asynchronous result. Room/AR can submit
multiple accepted changes under one owner undo group; an unrelated valid command
starts its own change. Rejected/no-op commands leave the feature group intact.
Changed feature results clear a frozen zero-motion Plan origin so a later drag
cannot overwrite newly accepted geometry. A stale gesture end cannot close a
new owner's gesture.

### Project work and lifecycle

Project operations reserve synchronously before ending an edit. Stale or busy
reservations have no edit side effects. The session owns the task and reconciles
a committed receipt even when its sheet observer or task is cancelled after the
write. Request identity and storage generation protect adoption and cleanup.
Healthy repeated initial load cannot overwrite a dirty editor; explicit retry
remains available after failed initial load.

First save preserves selection, history, control/preview identity and the active
feature's logical workspace. It still invalidates old storage callbacks.
Successful document switch, reload or recovery rotates `workspaceResetID` and
clears the presentation. Both Study and 3D wrappers use that reset identity; 3D
selection separately checks storage generation and live light UUID. The actual
two-store conflict/recovery regressions exercise independent window sessions.

Scene/lux proposals accept once, including valid unchanged proposals. Lux may
change only the captured light's candela. Feature dismissal retires callbacks
immediately; old teardown cannot clear a newer presentation. Nested manual-room
close stays local to AR. Root disappearance does not broadly retire features,
because modal coverage may hide the root while a draft is still active.

### Navigation and presenter ownership

Reference/comparison, room, AR, arrangement and lux use the shared host. Export
continues to capture its owner's immutable scene/name/text snapshot. Protected
storage keeps Tools → Settings → Purchase options accessible while preserving
the existing restrictions on scene editing and project work. A source-specific
UI regression covers that utility route.

The adaptive header removes duplicate structural export-presenter positions
across fitting and accessibility branches. Export/PDF/document implementation
bytes remain unchanged. This is a state-ownership correction; it does **not**
establish the cause or resolution of the historical export-reopening failure.
The layout helper is specialized for intrinsic header/actions, not a general
maximum-size layout contract.

## Final actual verification

All results below identify their source and execution scope. Full commands,
logs, ordered case reconciliation and hashes are under [final evidence](evidence/final).

| Check | Actual outcome | Scope |
|---|---|---|
| Local Swift 6.0.3 Linux Debug at `ce9f7aa` | **433 passed**, zero failures/skips | Normal package suite; existing isolated build directory reused and changed inputs rebuilt. |
| Local Swift 6.0.3 optimized Release at `ce9f7aa` | **433 passed**, zero failures/skips | Explicit `-Xswiftc -no-whole-module-optimization`; distinct from default Release. |
| CI Swift 6.4.2 Linux core job `140083931415` at `ce9f7aa` | **433 Debug + 433 standard Release passed**, zero failures/skips; complete core job succeeded | Standard CI configurations, including whole-module Release. Raw case inventories match both local runs exactly. |
| Project-state workflow `45870276335` | **Succeeded** | Structural state validation, not milestone promotion. |
| Swift frontend parse at `ce9f7aa` | **86 native Swift inputs parsed**, exit 0 | Syntax only; no Apple SDK typecheck or runtime. |
| Package dump/describe and UI shard preflight at source-equivalent `1f14d48` | **Passed** | Target declarations inspected; nine UI classes retain their assignments. |
| Final selected input manifest | **183 hashes matched Git** | 182 checked-out files and the sparse privacy resource read from Git. Not complete CI dependency closure. |
| Apple native/simulator/UI jobs at final code | **Unverified** | Simulator job in progress and five UI jobs queued at the latest retained observation; no whole-workflow success claim. |

The 433 portable methods comprise 396 core and 37 actual composition/store
methods. Darwin package source additionally declares three Observation methods;
436 is the expected Darwin inventory, not an execution result. Native source
declares 195 unit methods, with 36 required UI methods plus two diagnostics.
Those counts also describe source inventory, not completed native tests.

The final CI result is [ci-final-core.json](evidence/final/ci-final-core.json);
the later job-state observation is [ci-latest-jobs.json](evidence/final/ci-latest-jobs.json).
The raw core log SHA-256 is
`c0fe6034fcc10e287441adac752285961640c0484d9dfe6484f410b8f04ed857`.
Host benchmark workloads and cancellation observations were independently
reconciled, but establish no device performance or measured UI speedup.

### Meaningful added regressions

The suite tests actual orchestration and storage. `StudioSessionTests`,
`StudioPlanSessionTests`, `StudioFeatureSessionTests` and `StudioFeatureWindowTests`
cover stale reservations/results, selection/undo, continuous edits, one-shot and
repeated acceptance, failed operations, competing saves and document recovery.

Two `StudioCommittedSaveTests` call the real store, pause **after disk commit and
before receipt adoption**, then cancel either the observer or session task. They
prove exactly one adoption, released task bookkeeping, retained room/selection/
history/workspace and rejection of old storage callbacks. They do not separately
prove Save closing an open room group: selection has already ended that group in
the fixture; existing Plan reservation tests cover edit teardown.

Three Darwin-only `StudioObservationTests` exercise actual observation of
scene edit/undo, feature lifecycle and busy reservation/completion. One native
`StudioAdaptiveLayoutTests` method hosts the production helper and checks three
installed State UUIDs plus live geometry across eight width/accessibility phases.
**These four methods remain unexecuted.** The hosted fixture checks allocated
geometry, not physical viewport visibility, real export/PDF sheets, RTL,
VoiceOver, real rotation or actual control targets. Its bounded main-queue
settling may need a phase-specific observation if native execution demonstrates
a timing failure; no such runtime failure or false pass has been established.

### Preserved failures and native boundary

An earlier Apple Swift 6.3.3 build exposed conditional `@ObservationIgnored`
accessor errors. Owned correction `8b18366` places attributes directly on complete
Darwin declarations. An actual-source macro probe reproduced four errors before
the correction and typechecked after it. Later Apple logs compile the corrected
session and no longer contain those diagnostics, but still fail elsewhere.

The latest completed retained native job, `140067450161` at prior code `adffee4`,
failed in inherited `StudioAppAccessibilityUITests.swift:95` on ambiguous
`greatestFiniteMagnitude`, with no native case execution. Main's later fix uses
**`CGFloat.greatestFiniteMagnitude` for both `CGSize` bounds**. Lane 20 must retain
it when integrating; this lane did not edit that owner's file.

The forced-Darwin Linux Observation test attempt compiled but failed to link on
an unresolved Swift Observation runtime symbol: zero tests executed. An earlier
local default Release compile ended with signal 9 before tests; its cause is
unproven. Both failures retain their original source/commands/logs. Successful
later checks do not relabel them. Historical Keep/Done, export reopen after Undo
and Meter reachability failures retain exact owner source SHAs and job receipts
in [INTEGRATION_REQUESTS.md](INTEGRATION_REQUESTS.md).

## Integration steps and unresolved owner dependencies

1. **Lane 20:** integrate this branch while preserving later main and feature-owner
   changes, especially the explicit `CGFloat` correction. Reconcile conflicts at
   the shared composition seams against [INTERFACES.md](INTERFACES.md). Keep
   canonical M03 status tied to required evidence.
2. **Reference, arrangement and lux owners:** add explicit synchronous acceptance
   callbacks and update callers together using [FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md).
   Their current Void callbacks consume/dismiss local drafts before the parent can
   communicate rejection. Current scene admission is protected, but complete
   pending-draft retention is **not implemented** for those three producers.
   On rejection retain the actual draft and editor; consume/dismiss only on
   acceptance, including accepted no-ops, with reentrancy protection.
3. **Lane 19 with feature owners:** run generated Apple targets and required native/UI
   suites on the final integrated source, including Observation, hosted layout,
   first-save viewport retention, nested room/AR dismissal, protected-storage
   purchase navigation and export reopen/cancel. Preserve exact source hashes,
   method accounting, failures and result bundles. Native commands and target
   membership are in [CONFIGURATION.md](CONFIGURATION.md).
4. **Accessibility/CI owners:** recheck Meter reachability with a fresh observation
   after the last scroll. The historical helper makes twelve observations followed
   by drags, then fails without inspecting the final gesture. Do not infer recovery
   from accumulated teardown metrics or weaken containment/hittability criteria.

Existing room/AR Bool adapters are connected; they need native validation rather
than a replacement interface. Actual SwiftUI lifecycle, focus/caret, first-save
viewport retention, AR, StoreKit and device accessibility remain unverified.

## Worker and evidence integrity

Each wave includes acceptance, data invariants, API compatibility, implementation,
concurrency, resource lifetime, feature integration, accessibility/privacy,
platform/performance and independent review. Acceptance schedulers count once
alongside nine peers. Root, scheduler and at most two peers respect real capacity;
integration and expensive builds are serialized. Final reports meet the
800-tool-estimated-token cap; briefs have a 2,000-token limit. The requested
12,000-token working budget cannot be enforced or measured by the spawn API.

Source revisions, patches, original/condensed reports, same-context followups and
cleanup records remain attributable. Earlier environment resets and reconstructed
provenance are explicitly recorded; missing historical raw logs are not described
as recovered. Temporary trees were removed only after source and artifacts were
preserved. The final root audit checks 100 distinct actual IDs, ten roles per
wave, all report hashes and final-source equivalence. No additional contexts are
counted for retries, followups or failed capacity requests.

For entry points, read this handoff, [INTERFACES.md](INTERFACES.md),
[FEATURE_ADAPTERS.md](FEATURE_ADAPTERS.md), [NAVIGATION.md](NAVIGATION.md),
[INTEGRATION_REQUESTS.md](INTEGRATION_REQUESTS.md), and the final evidence receipts.
