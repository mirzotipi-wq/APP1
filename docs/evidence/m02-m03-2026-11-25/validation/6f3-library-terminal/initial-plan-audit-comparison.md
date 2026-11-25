# Bounded comparison: 6f3 initial-plan and numeric-editor accessibility audits

**No application/readiness cause is established by the retained evidence, so this comparison does not justify an app or audit change.** The [library job](https://github.com/mirzotipi-wq/APP1/actions/runs/45641483928/job/139303177809) remains **9 passed, 2 failed** on source `6f3da3341f350084eac4a05b35a5bfd408d50193`. One failure is the initial-plan `.all` audit; the separate keyboard-readiness failure is not reclassified here.

## What the run establishes

The numeric-editor full `.all` audit passed first, in a 128.893-second method. The next method relaunched the app with a fresh test identifier/process and failed in 47.063 seconds with `com.apple.xcode.xctest.accessibilityAudit Code=-56`, before any audit-issue attachment was reported.

Both methods passed the same loaded-plan checks: enabled Recipes; selected Plan mode; Portrait setup; Unsaved changes; three lights; camera control present. The failing method also captured its screenshot and two hierarchy snapshots before entering the common audit helper. Its failure occurred at 15:22:22 UTC, around six minutes into the 32-minute shard step; later library tests continued. It is not an outer-step cancellation or the separate control app's pre-test Code18 failure.

| Observation | Numeric editor: passed | Initial Plan: failed |
|---|---|---|
| App process in pre-audit tree | 14071 | 17532 |
| Pre-audit AX attachment, test elapsed | 100.56s | 21.74s |
| Next audit-completion/error observation | Teardown at 123.73s | Code=-56 at 15:22:22.964 UTC |
| Approximate interval after AX attachment | 23.17s to teardown | 24.89s to error |
| Saved hierarchy | 22,476 bytes; 209 subtree nodes | 16,568 bytes; 142 subtree nodes |

These enclosing intervals are not explicit audit begin/end instrumentation. Neither tree is truncated. The successful dump retains offscreen Studio nodes behind the modal, so total dump size is not a measure of the audit's actual work; it also contradicts a simple claim that the failed dump was larger. The numeric editor has a visible Intensity form with value 900 and Apply/Cancel; the initial tree shows the loaded Plan controls. Neither tree contains a keyboard, alert, or loading-progress element.

## Source checks and limits

Recipes is disabled while `!loaded || saveBlocked || libraryOperation.isBusy`. The load path adopts the library, scene, selection and presentation before setting `loaded=true`. The saved state and successful readiness assertions give no observed evidence of an outstanding initial load. Initial Plan selects the 2D plan branch; Study and 3D preview branches are not selected. The inspected plan layout has no timer or repeat-forever animation. Its preference writes compare against the prior value before changing state. This does not prove layout stability throughout a later audit.

The numeric test does additional scrolling, opens a modal, and checks field value/hittability plus enabled/hittable Apply and Cancel. It reaches its audit much later in its process lifetime. Screen, process age, navigation, and test order therefore vary together. The evidence cannot separate screen-specific audit work, a transient app/layout condition, or service/host variation. A successful numeric invocation disproves only blanket nonexecution of every audit on that runner; it does not establish platform reliability or clear the initial-plan gate.

No arbitrary wait, weakened readiness requirement, filtered audit type, retry, or deadline change is supported by this comparison. The ongoing isolated control and unchanged full-audit invocations are the next authorized evidence. No source edits, simulator executions, or additional artifact downloads were performed.

## Receipts

`a097-initial-plan-audit-comparison.json` binds the six inspected source files to the tested revision and hashes both tree attachments. `a097-audit-comparison-excerpts.log` preserves a contiguous **130-line, 13,644-byte exact selected window**, SHA256 `d697a4d3799562951dba661a402d015a1293191247071384f0875afb5386b39f`; it is not the complete job log. The complete retained log is 499,056 bytes, SHA256 `a58075258ec1d2c8b1727fbad1179c72b66899c559b8a7de441a5c925ce78b81`. Shared artifact retrieval/verification and screenshot inspection were performed by a100; this reviewer read the retained raw log and both text hierarchies.
