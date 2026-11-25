# UI shard repair and separate runtime control

Base for the working candidate: **9eddd97c5e638edf1768332d9d83d7dc2cccb72a**. Actual completed application test revision: **cbf94cecb113c1f03b0b8c7287e763655c14ec11**. This packet records failures as well as successes; the new candidate has not yet executed on Apple hardware at capture.

## Completed application invocation

[Run 45623581873](https://github.com/mirzotipi-wq/APP1/actions/runs/45623581873) completed with **failure** at **14:41:50 UTC**. The [terminal workflow receipt](../validation/cbf-terminal-workflow.json) and individual raw-log excerpts bind the following results to cbf.

| Scope | Passed | Failed | Interrupted | Skipped / unstarted |
| --- | ---: | ---: | ---: | ---: |
| Linux Debug | 319 | 0 | 0 | 0 / 0 |
| Linux Release | 319 | 0 | 0 | 0 / 0 |
| Python checks | 35 | 0 | 0 | 0 / 0 |
| Native app tests | 110 | 0 | 0 | 0 / 0 |
| Room / precision UI | 5 | 0 | 0 | 0 / 0 |
| Library / reference UI | 8 | 3 | 0 | 0 / 0 |
| Studio / export UI | 19 | 0 | 1 | 0 / 0 |
| **Complete UI inventory** | **32** | **3** | **1** | **0 / 0** |

All required native Metal methods and unsigned Debug/Release builds passed. The [portable receipt](../validation/cbf-core-terminal/terminal-summary.json) records 319 Debug in 13.301 seconds, 319 Release in 5.652 seconds and 35 Python checks in 0.397 seconds, plus six shared-kernel and eight strict-precision fixtures. The [native receipt](../validation/cbf-native-terminal/terminal-summary.json) and [room receipt](../validation/cbf-room-terminal/terminal-summary.json) retain their separate platform scope. Native execution also included 319 portable package tests on macOS, separately from the 110 app methods.

The [library accounting](../validation/cbf-library-terminal/method-accounting.json) contains all eleven starts and terminal outcomes. Two full `.all` accessibility audits threw Apple accessibilityAudit **Code=-56**, without completed issue enumeration. The archived-delete method failed at keyboard introduction readiness, before typing or deletion. Earlier Projects/Save and large-library relaunch readiness failures did not recur. The [video and host investigation](followup-cbf-library-readiness-host.md) establishes that the introduction was gone and a normal q key was visible by the failure time; the retained query-only attachment does not establish AX identity or hittability. There is no demonstrated persistence-loss cause.

The [studio receipt](../validation/cbf-studio-terminal/terminal-summary.json) records all twenty starts, nineteen passes and no failed-method terminal outcomes. Its final `testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene` began at 14:40:49.867 UTC and was interrupted by the unchanged forty-minute test-step deadline at 14:41:07.226 UTC. All ten optics workflows passed. Their completed durations total 1,099.740 seconds; the other nine completed methods total 1,023.135 seconds. These are observations from this invocation, not future duration guarantees.

The before/after host snapshots do not establish resource-pressure causation. In library, `ps` reported a 59.243-second timeout despite its requested five-second bound. Studio's optional before-test capture exceeded its one-minute step. Both conditions remain recorded; `continue-on-error` applies only to optional host evidence, never to required tests. Missing finalized studio results are retained as a failure, not treated as a clean bundle.

## Three reviewed changes

1. **Keyboard readiness:** [implementation report](followup-keyboard-helper-semantics.md), [independent review](followup-keyboard-helper-independent-review.md). Apple's documented `isHittable` semantics make explicit existence reads redundant. The helper keeps `!proceed.isHittable && typingKey.isHittable`, the same evaluation order, exact q/Q query and ten-second deadline. One failure-only app snapshot supplies bounded selected-node attributes, console/text evidence and a genuine screen attachment. It never retries the failed wait or replaces its assertion. Actual speedup and underlying remote-query counts remain unknown.
2. **Required studio partition:** [implementation and source proof](followup-studio-shard-split.md). The ten optics wrappers and complete common workflow move byte-for-byte into `StudioOpticsUITests`, with identical setup and private helper bodies. Eight remaining smoke methods and two export methods stay in studio/export. The existing class-level checker assigns all eight classes exactly once; all 36 method bodies are preserved. The new optics shard has a 32-minute test step and 85-minute job bound. Existing deadlines and the maximum of three simultaneous UI jobs remain unchanged. Both studio shards retain trace collection, host captures and result uploads. One additional standard hosted setup is required; total wall time may increase.
3. **Separate audit runtime experiment:** [candidate](followup-accessibility-control-runtime264.md), [independent review](followup-accessibility-control-runtime264-review.md). Only the control's runtime selection/guard/message changes from 26.5 to the already-installed 26.4.1. Host label, Xcode 26.6, SDK 26.5, control app/test, full audit and every bound remain unchanged. Primary application jobs continue on iOS 26.5. The earlier component receipt records the primary workflow hash before the separately reviewed studio split; it is not a claim that the integrated primary workflow is unchanged.

## Control nonexecution and superseded run

The corrected control workflow was admitted at 9ed. [Run 45632330705](https://github.com/mirzotipi-wq/APP1/actions/runs/45632330705) built successfully, then exceeded the ten-minute boot limit. Its sole test step was skipped; there were **zero test starts and no audit result**. The retained boot log eventually reached Finished at elapsed 11:35, after the failed-step boundary. The [terminal packet](followup-accessibility-control-9ed-terminal.md) preserves stable source hashes, migration phases, timeout, verifier failure and absent xcresult. No dyld-cache, Metal or runtime-specific cause is established. Hosted-machine variation remains uncontrolled in the new runtime experiment.

Root intentionally cancelled the superseded primary 9ed [run 45632330628](https://github.com/mirzotipi-wq/APP1/actions/runs/45632330628) during core, before any Apple step executed, so the reviewed source candidate can run next. The [cancellation receipt](../validation/superseded-primary-9ed.json) also separates the earlier automatic cancellation of pending b26 run 45630594513. Neither cancellation is a passing workflow or an app assertion result. Completed cbf and control evidence remains intact.

## Gate decision and next action

**M01 remains complete. M02 remains active. M03 remains dependency pending.** Photometry retains declared numerical-fixture evidence. Editing remains unverified because the archived-delete workflow failed and Study switching did not finish. Accessibility remains failed/incomplete; earlier concrete findings and the manual real-device audit remain outstanding. Persistence retains its original scoped evidence, without a new iOS durability claim. Regression remains failed.

The twelve calibrated rights-cleared scenes with independent photographer review, physical iPhone performance/memory/thermal measurements, and manual device accessibility cannot be supplied by these simulator results. The [external acceptance packet](../../../acceptance/m02-m03-external-evidence.md) remains unexecuted. All 100 initial worker assignments are complete in the existing ledger; these are follow-ups by reused workers.

Publish the independently reviewed candidate, then require actual compilation, all four UI shards and the separate control outcome. Count starts and unique terminal methods, retain every failure/interruption, and distinguish pre-audit nonexecution from an audit result. No milestone promotion, skipped required test, audit filter, retry-until-green or protected-contract change is part of this integration.
