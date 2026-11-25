# Keyboard readiness and isolated startup observation after 6f3

Base and tested source: `6f3da3341f350084eac4a05b35a5bfd408d50193`. Root owns this integration packet; a100 owns the isolated control and library investigation, a097 independently reviews both source deltas, and a099 verifies core/room/optics execution. These are reused members of the completed 100-worker cohort.

## Observed application execution

[Run45641483928](https://github.com/mirzotipi-wq/APP1/actions/runs/45641483928) is still executing. The exact core receipt proves **319 Debug,319 Release,35 Python** passes, eleven EFBIG checks, three interruption/rename scenarios, six shared-kernel fixtures and eight precision fixtures. The independently parsed native log proves **110 unique starts and110 passes, zero failures/skips/missing methods**, including all three required Metal tests. Its native aggregate is75.021s,76.853s wall; the separate macOS portable suite passed319 in23.644s. Unsigned Debug and Release builds succeeded. These are simulator/host observations, not physical acceptance.

The library terminal log parsed by a100 has eleven starts and terminals: **nine passes,two failures,zero skips/interrupted/unrun**. The exact numeric editor's full `.all` audit passed; the initial-plan full audit returned Code=-56. Archived-delete still stopped at keyboard readiness before typing or deletion. Eight other functional methods passed. Room/precision is now independently verified5/5, zero failures/skips; studio/export is independently verified10/10, zero failures/skips, including the formerly interrupted Study-switching method. The new optics shard remains running. Their own terminal receipts retain exact method identities and outcomes; unfinished jobs are not passes.

## Keyboard helper correction

The [complete failure excerpt](../validation/keyboard-absence-guard/6f3-keyboard-readiness-excerpts.log) shows Continue resolution at76.28s, implicit retries at80.87s and83.93s, and the first key query at85.44s. The failure-only snapshot traversed142nodes without truncation. It contains q at node100 with a normal frame and enabled state, all alphabet rows and the name field; it does not list Continue or the introduction message. It does **not** record isHittable, so neither the snapshot nor the screen alone proves the predicate was true during the original wait.

The candidate restores the negative-side existence short-circuit: `(!proceed.exists || !proceed.isHittable) && typingKey.isHittable`. This retains both accepted fixed-state conditions and Continue-first order. It avoids requesting a hit point when the button is already confirmed absent, while retaining the key's positive hit test. The redundant key-existence read removed in6f3 stays removed. Every other helper byte, caller, exact text assertion, confirmation/deletion/relaunch check and the10-second wait remains unchanged. No repair or speedup is claimed before new Apple execution. The reset environment has no Swift compiler, so no new local Swift parse is reported. See [source proof](../validation/keyboard-absence-guard/candidate-source.json) and [independent review](../validation/keyboard-absence-guard/independent-review.md).

## Isolated control observation budget

The separate [control run45641484079](https://github.com/mirzotipi-wq/APP1/actions/runs/45641484079) built and booted iOS26.4.1 but recorded zero method starts or audit markers. XCTest's Code18 initialization error at15:20:27.826563UTC falls after the nominal six-minute boundary and before the timeout annotation at15:20:38.096274UTC. The first cancellation signal was not retained. This is a confounded startup observation, not a completed audit or Code=-56 reproduction.

The control-only delta changes the outer test-step budget6→10minutes and job32→36minutes. All other control commands, runtime, app/test/project, readiness assertions, full `.all` call and failure propagation remain byte-identical. Individual step bounds total34minutes, with two minutes for setup/finalization. The primary application workflow and its deadlines are unchanged. This permits one bounded observation of the control's actual startup/audit outcome; it does not promise a pass. See [candidate validation](../validation/control-startup-budget/validation.json), [preceding invocation](../validation/control-startup-budget/root-preceding-invocation.json) and [independent review](../validation/control-startup-budget/a097-independent-review.md).

## Integration and remaining gates

Retain every earlier failed invocation and all81 existing evidence entries. M01 remains complete. M02 remains active because calibrated real-scene comparisons/photographer review and physical iPhone performance/thermal evidence are absent. M03 remains dependency pending; editing is unverified and accessibility/regression are failed or incomplete. Manual device accessibility is also unrun. No protected contract, test inventory, audit filter or product threshold changes.

Publish the independently reviewed combined candidate to main, let the productive6f3 run finish, then verify the new helper in normal required CI and the isolated control separately. Do not infer a new-source pass from earlier results or treat the isolated control as application acceptance.
