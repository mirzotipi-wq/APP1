# Checkpoint 11 — explicit slider lifetime and legible plan captions

**Later native update:** the exact-source simulator job completed success at12:56:49UTC, with both unsigned builds and83/83 native methods passed. Current native_build now passes; persistence smoke and actual UI/optics/plan acceptance remain pending. Earlier observations below retain their original dates. [Detailed later native report](native-result-95e9c24.md).

## Exact integrated source

Current pushed/read-back source: **`95e9c2446b7bb05e6df38d103063b4254bb07c92`**. Exact tested tree: **`c35f501c41a6741a5cc90c012135b8d041d005ad`**. Parent: `6752f4dd0acea314b58d5a31b4d5e6f8c4f23bc7`.

The integration lead published this source and verified local/remote main equality. The records specialist independently checked local HEAD/tree, the sixteen commits since session baseline `968e4bb1b3932c5140b735b404c9538d909bab23`, and all thirteen source hashes in [cycle11-snapshot.json](cycle11-snapshot.json) against both the then-live files and the immutable `verification/cycle11-source` export, before later guide/workflow working changes. No implementation test was rerun for this documentation packet.

Source 11 adds **P21/T41**, the reviewed plan-caption correction, and **T42 within P19**, explicit native slider lifetime. Session totals are **21 integrated packages, 42 actionable tasks, eleven complete local integration cycles and sixteen pushed commits**: eleven source and five evidence-only commits. The actual workforce remains **61 specialists plus the lead**; reuse adds none. These implementation/task counts do not close native or release acceptance. The guide follow-up is outside this tested source and is not counted. KF-025 remains held outside production.

## What changed and why

The slider packet addresses a controlled counterexample in the real previous adapter/history: an end followed by a late value can reopen editing and leave Undo unavailable, or split the gesture's history boundary. Source 9's actual optics test failed with `1.3 m` instead of the original `0.6 m`; its retained recording shows one pointer drag and later gray history arrows. The native callback order remains untraced. Source 10 later repeated the original assertion failure with `2.25 m`; it did not contain this correction.

The integrated `UISlider` wrapper captures owner/project closures and mapping at touch start, routes values through a bounded session, publishes the final tracked value before closing, and retires that session on end, cancellation, disable, window loss or dismantling. Events outside an active session cannot reopen history. Existing discrete accessibility adjustments, exact-value editors, parent force-close and project/generation guards remain. The original adapter and core history implementation/tests are unchanged. The optics UI scenario keeps every original width/shape/Undo/Redo/save/relaunch expectation and additionally checks the slider's identity/value and enabled Undo/Redo. A bounded DEBUG trace is available but has not yet been collected from source-11 native execution. [Author evidence](slider-tracking-report.md), [independent review](slider-tracking-review.md).

The plan packet separates fixed equipment markers from their captions. Equipment icons remain centered at the original projected coordinates; a bounded deterministic layout avoids caption/marker and caption/caption intersections, prioritizes the selected caption, and supplies a truthful selected-name/light-list fallback when a dense arrangement cannot fit. Six portable cases cover the observed recovery geometry, anchors, narrow and supplied large-text dimensions, coincident equipment and malformed/tiny inputs. Actual Apple font metrics, portrait/large-text rendering, selection and VoiceOver remain unverified. [Author evidence](plan-label-author.md), [independent review](plan-label-review.md), [original source-9 recovery image](source9-library-visual/recovery.png).

The existing Projects-readiness helper now records hierarchy/screenshot diagnostics **only after failure**. Its enabled predicate and **15-second deadline are unchanged**. This increases available failure evidence; it does not claim to explain or repair the source-10 first-launch readiness failure. Source 11 also retains the original failed gesture evidence. No renderer optimization, guide integration, protected threshold or native timeout change is included.

## Complete local verification

The lead ran these commands against the immutable tested source with Swift **6.4.3**, Debian 13, x86_64. The specialist read the actual logs/result records and copied them unchanged. Counts are per configuration; overlapping focused suites are not added to the full suite total.

| Check | Actual result | Recorded time and limit |
| --- | --- | --- |
| `swift test --jobs 2` | **257/257**, zero failures, exit 0 | XCTest aggregate **11.005s**; complete command **29.247s** |
| `swift test --configuration release --jobs 2` | **257/257**, zero failures, exit 0 | XCTest aggregate **5.625s**; complete command **37.037s** |
| `python3 -m unittest discover -s scripts/tests -p 'test_*.py'` | **28/28**, exit 0 | Tests **0.320s**; complete command **0.438s** |
| Native source syntax | **42 files**, exit 0 | Swift 5 language parse only; no Apple SDK type checking |
| State, next-task, shard manifest, icon, privacy and YAML checks | All recorded exit 0 | Structural/source validation, not native behavior |
| Declared native/UI inventory | **83 native methods / 23 UI scenarios** | Authored counts only for source 11; not executed counts |

The six new layout tests explain the full portable increase from 251 to 257. The separate unchanged-source slider/helper harness passed **38/38 Debug and 38/38 Release**: eight adapter, fifteen history and fifteen new tracking/mapping methods. Three new UIKit methods are authored and syntax-parsed only. These focused results do not add 38 unique methods to the full core suite or prove an actual touch gesture. [Retained focused commands/logs](slider-tracking-raw/commands.json), [full-cycle command results](cycle11-core-results.json), [structural results](cycle11-structural-results.json).

All elapsed values above are host observations with the original log timestamps preserved. They are **not device performance, interactive latency or a before/after benchmark**. The shell clock differs from connector UTC; it is not used to calculate session duration.

| Raw evidence | Bytes | SHA-256 |
| --- | ---: | --- |
| [cycle11-debug.log](cycle11-debug.log) | 71,163 | `d17e156e79c038968b24ffd26fc9f20366bc633d7ab4e2b3e2d123d33c90b725` |
| [cycle11-release.log](cycle11-release.log) | 70,572 | `473cce76f24a446591a505df2f944abbf493cc55fdf9bc9636a138f86039e3f8` |
| [cycle11-python.log](cycle11-python.log) | 127 | `e6544cc72e61852784afb30d9fd0c61483673ca04cba1478163f40df7ee3f067` |
| [cycle11-native-parse.log](cycle11-native-parse.log) | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

The empty parse log is supported by the explicit exit-0 structural result. Other copied raw logs are `cycle11-agent-state.log`, `cycle11-agent-next.log`, `cycle11-shards.log`, `cycle11-icon.log`, `cycle11-privacy.log` and `cycle11-yaml.log`. Their original result records remain separate from later documentation-consistency checks.

## Later completed source-11 remote core

The lead retrieved core job **138450151607**, completed **success at 12:41:19 UTC** after starting at `12:38:55Z`. The records specialist independently read the complete unchanged [95e9c24-core.log](95e9c24-core.log) and verified its **201,567-byte** SHA-256 **`23ca295d22bf6f6d26299d518444e2aeaf2219d0119c85ac0ab68c96e582c6f4`**. It has 201,455 decoded characters and records Ubuntu 24.04.5 with Swift 6.4.2.

Actual results are **257/257 Debug, zero failures, 7.807s**; **257/257 Release, zero failures, 4.130s**; and **28 Python checks, 0.270s**. State, source syntax, exactly-once UI shard coverage, icon and privacy checks passed. All six rendered sphere/mannequin fixtures reported zero unsupported pixels. The original **six host parity fixtures** passed with maximum channel difference at most one and matching unsupported masks; the **eight strict far-camera/translation controls** passed with zero channel difference and matching masks. The preparation step generated 33 inputs, but the strict command executed eight; this is not a claim of 33 passing controls. Host kernel checks are not actual Metal execution or device performance.

The approximately **12:42 UTC** job observation supplied by the lead had simulator **138451564691**, library/reference **138451564785** and room/precision **138451564904** running from `12:41:24Z`; studio/export **138451564680** was queued. No source-11 native build or method result was available. The earlier transition observation below remains a separate dated record, and native gates remain unverified.

## Native state at the earlier observations and retained predecessor failures

Source-11 [workflow 45394444997](https://github.com/mirzotipi-wq/APP1/actions/runs/45394444997) was created at **12:32:09 UTC** and initially waited behind source 10. At the single transition observation at **12:39:52 UTC**, it was **in progress**, updated at **12:38:55 UTC**. No source-11 Apple build, native method, UI method or visual result was observed in this packet. **Current `native_build` and `persistence_smoke` are unverified.** The previous source's build/unit pass is preserved as historical evidence.

Source-10 workflow **45383556829** finalized **failure at 12:38:51 UTC**. It actually passed both unsigned builds and **65/65 native methods**, including all fifteen actor/operation tests; its remote core passed **251/251 each configuration plus 28 Python**. Final UI observations are:

| Source-10 shard | Actual result | Scope |
| --- | --- | --- |
| Library/reference | **8/9 passed**, one failure; **652.003s** aggregate | Initial Projects-readiness predicate failed before delete work. The large-library load/save/browse/relaunch method and the other recovery/library/reference methods passed. Native failure cause remains unestablished. |
| Room/precision | **5/5 passed**, zero failures; **712.389s** aggregate | Both room and all three precision scenarios completed. No physical room/AR or device-performance inference. |
| Studio/export | **9 started, 8 completed: 7 passed, 1 failed, 1 interrupted** | Original optics Undo expected **0.6m**, observed **2.25m**. Both export scenarios, camera, corrupt-storage, meter, recipe and study-frame passed. Bust switching was still recording actions when the 32-minute deadline interrupted it; no finalized xcresult. |

Thus source 10 has **23 started, 22 completed: 20 passed, two failed and one interrupted**, not a complete regression pass. The complete job log and verified small text-only artifact are retained in [the final studio report](source10-studio-final/result.md). [Source-10 build/unit and other UI results](native-result-5cd7eb4.md) preserve earlier pending observations and later completed results separately. No actor or gesture cause is inferred from the deadline.

Historical source 9 remains **50/50 native and 21/22 UI**, with its original optics `0.6m`/`1.3m` failure. Its room pass occurred without the later explicit status label, so it does not explain source 8's earlier room failure. The [source-9 report](native-result-3b2a4ce.md) and original logs/visual evidence remain unchanged.

## Open acceptance and next observation at the earlier checkpoint

M01 remains active. Obtain the exact source-11 Apple builds, native methods and all UI shards; inspect the strengthened original optics expectation and failure-only Projects diagnostics if they fail. Verify the corrected crowded plan in genuine native images and narrow/large-text/selection/accessibility states. The guide follow-up remains outside this tested source/count, and KF-025 remains **HOLD** for the independently measured 4.43449% internal-cell jump and unaccepted cost; no native flicker claim follows.

The source-bound **20 supported evidence-point floor** is unchanged and is not a quality score, completion percentage or release approval. Physical calibration, device performance/thermal/accessibility, real provider/share behavior, inference, AR, commerce, customers, signing and owner approval remain open. No protected contract, assertion, timeout or acceptance threshold was weakened.


## Later actual native completion —12:57UTC observation

Source11 simulator job138451564691 completed **success12:56:49UTC**. The lead retrieved the complete raw log and artifact metadata at12:57:49UTC; the records specialist independently counted all83 completed method lines, build/bundle results and diagnostics. **Both unsigned builds passed** (Debug12:45:34.028320,Release12:47:26.070016), with icon/privacy bundle checks. Actual native XCTest passed **83/83**, zero failures, **22.210s execution/23.241s aggregate**, TESTSUCCEEDED12:55:21.154430. The new15tracking and3UIKit methods passed alongside8unchanged adapter and15actor methods. The separate macOS257/257 run includes15history methods; these are not extra native methods. [Complete report and suite table](native-result-95e9c24.md).

The unchanged774,676-byte [native log](95e9c24-native-job.log) has SHA-256 `bf4eedabe5693ee1866271ce63ea3ba028ab73d98013f6aabfec44a09b046d56`. [Artifact metadata](95e9c24-native-artifacts.json) is reported metadata only; no ZIP was downloaded or inspected for this observation. AppIntents/Node/startup diagnostics and associated passing cancellation/presenter-error/malformed-image fixtures remain visible in the log.

**Current native_build passes at95; persistence_smoke and full UI acceptance remain unverified.** Library/room UI were still running and studio queued in the lead's approximately12:57UTC job read. The three UIKit methods call configuration, accessibility and stray-event paths; they do not prove an actual drag, original0.6m optics Undo/Redo/relaunch, real VoiceOver or crowded-plan rendering. Earlier pending snapshots and all280 existing evidence records remain unchanged, with five later observations appended. Counts stay21packages/42tasks/11cycles/16pushed/61specialists. Guide/CI-budget working changes and the separate two-screen audit candidate under review remain outside this source and receive no acceptance or count increase.
