# Native correction candidate — checkpoint 7

Prepared source `15a1b348c680423a46d94ecf739321a5a57bc0a7`, tree `9ac414a06f5ffb61b9d243fbac0ec56a5697dbaf`, parent `ff8b683098a720b4c7abdddf212f85a79f3cfd39`. The Git object exists remotely and its tree matches the immutable tested index export. At preparation, main had not yet advanced while the existing studio/export shard finished. It was then integrated as the parent of `816e7123cafbf214bef47e09d3e14abd993a83c7` through a non-forced main update. The exact read-back and new workflow are recorded in [checkpoint8](checkpoint-8.md); there is no separate source-seven workflow.

## Acceptance before integration

- **245/245 portable XCTest methods passed in Debug and 245/245 in Release**, zero failures. Actual suite times 16.543 s and 7.564 s in this run; these are whole-suite Linux timings, not device rendering measurements.
- **28/28 Python tests** passed, covering state/evidence schema, recursive native shard coverage and Metal toolchain preflight failure paths.
- Native Swift syntax parsing, source icon/privacy verification, state validation and all-six-class/three-shard coverage checks passed. Syntax parsing is not an Apple SDK build.
- An independent review found no concrete introduced regression or weakened acceptance assertion. [Review](native-correction-review.md).
- Original production domain, renderer, model and portable test sources are unchanged from source six in this native correction packet. All protected product/quality/roadmap requirements are unchanged.
- Corrected Apple SDK compilation, native test execution, current UI appearance and physical-device behavior remain **pending**.

## Demonstrated failures and focused corrections

| Area | Actual evidence | Corrective candidate | Acceptance retained |
| --- | --- | --- | --- |
| SceneKit presentation |32 clipping assertions matched the initial uncommitted identity camera; one FOV assertion rejected the exact observed Float round trip |Group scene/camera updates atomically without implicit animation; flush only the synchronous test before projection; compare physical FOV within one Float ULP |All 16 corner projections, finite/X/Y/depth bounds, target, ordinary-edit orbit and physical camera checks |
| Full-library recovery |One system alert exposed nested identical identified Button nodes; full-library scenario stopped before committing recovery |Remove the alert-action custom identifier; require one exact-label action in the named alert |Explicit confirmation, cancel, four-light retained content, saved status and relaunch |
| Room notes |Failed accessibility predicate while actual recording visibly displayed the correct committed6.00m width |Provide the same immutable notes string explicitly as accessibility label; capture actual label/value/type and failure hierarchy |Original width/draft exclusion, signed coordinate, reopened-sheet and unchanged-studio assertions; unchanged timeout |
| Project captions |Genuine screenshot measured inactive light counts at 1.883:1 against white and active count at 4.004:1 |Explicit semantic Color.primary for count/Open and short-ID metadata |Titles, action tint, layout, selection and labels unchanged; new rendered measurement required |
| Meter glyph |Native runtime logged two missing-symbol warnings |Use documented sun.max in the two labels |Meter behavior, text, IDs and hit areas unchanged; actual new appearance required |

See [SceneKit](spatial-native-correction.md), [recovery](recovery-ui-correction.md), [room notes](room-notes-native-correction.md), [captions](project-caption-correction.md), [meter](meter-symbol-correction.md), and the [original native results](native-results-ff8b683.md). These are one coherent native-acceptance corrective packet, not five artificially counted full integration cycles.

## Source-six evidence preserved

The earlier revision built both unsigned simulator configurations. Its native unit execution passed 40/42 methods with 33 assertions in two methods failing. Its reader 13/13, document-I/O 9/9, photo 7/7, PDF 3/3 and renderer 7/7 methods passed, including real simulator Metal on six fixtures with maximum channel error 1/255 and matching invalid masks. Library/reference UI passed 7/8; room/precision passed 4/5, including all three precision scenarios. Source-six failures remain failed evidence.

The actual Release bundle was inspected for Xcode/SDK, simulator platform/architectures, icon, privacy and shader packaging. This supports that revision's build gate; it is not a signed device or distribution artifact. Genuine current screenshots and a failure-recording frame were inspected by specialists and the lead, rather than generated or reconstructed.

## Specialist accounting

The planned organization used **60 distinct specialists in 10 waves of 6**, with follow-up tasks reusing those agents. During this final independent source review, the reviewer additionally spawned `/root/w09_ios_critical_review/spatial_assertion_review` for a read-only SceneKit subreview. The actual session total is therefore **61 specialist agents plus the lead**, not sixty and not sixty simultaneous workers. The extra reviewer changed no source, tests or state. This supplemental activity must be listed separately in the ledger and must not be hidden by relabeling it a reused specialist. No further new specialists are required for this packet.

## Raw logs

- [cycle7-debug.log](cycle7-debug.log), SHA-256 `48ed190aa905caa7acdb3a3bf34379824a6a23fac89f0635d5d155c23a933a9c`.
- [cycle7-release.log](cycle7-release.log), SHA-256 `102c0d6a6c01d9fad186b504f930c8ede2873d206e3765ab0011c032d0e20832`.

Raw shell timestamps retain their inherited offset; actual session duration uses the clock tool's UTC observations. No end time, execution cap, completed native run or release readiness is invented.
