# Native CI timeline: historical source 0fce248

This bounded follow-up by the same wave 9 CI specialist profiles the actual cancelled simulator job [138314533584 in run 45355893140](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140/job/138314533584). Source: `0fce248b4e61bace88002b40f6c56fddedb19c8a`. The current candidate `ff8b683` and run `45363578829` are separate; no workflow was changed or dispatched for this review.

Raw input: `/workspace/scratch/73dcd6a65726/verification/0fce248-native-cancelled.log`, SHA-256 `e85e5759d3393b5ef8684b7daf76868ffb1dc29923b6c43ad8f26efb92114991`.

## Recorded timeline

All times below are UTC on 2026-11-24. GitHub receipt timestamps sometimes lag timestamps embedded by simctl/XCTest. Durations describe the stated log interval, not inferred CPU time.

| Recorded event | Time / interval | Evidence and interpretation |
| --- | --- | --- |
| Unsigned Debug invocation → build success | 08:37:35.223 → 08:39:30.222; 115.0 s | Actual `xcodebuild ... Debug ... build` and `BUILD SUCCEEDED`. |
| Unsigned Release invocation → build success | 08:39:36.967 → 08:41:01.769; 84.8 s | Actual Release command and success marker; both build artifacts then uploaded. |
| Native-unit workflow step begins | 08:41:04.404 | Step first calls simulator boot, then blocking bootstatus, then the selected unit test command. |
| Simulator boot reaches terminal success | simctl reports `Elapsed=03:29` | Explicit wait states cover data migration and system-app readiness. The terminal line embeds 08:44:39 but GitHub receives it at 08:45:07.583; these clocks must not be mixed to manufacture phase durations. |
| Unit test command invocation appears | 08:45:57.610 | `xcodebuild ... -only-testing:KeyAndFillTests test`, Debug, same derived-data path. The gap after boot output is not assigned to a cause. |
| Test action package/build preparation | Resolve Package Graph at 08:46:05.298; target graph at 08:47:41.576 | The graph contains five targets, including both native-unit and UI test targets. No per-operation CPU duration is provided. |
| Native test sources compile | 08:48:52.366–08:48:55.836 | Actual SwiftCompile records for six native test source files; preparation and linking surround these records. |
| Unselected UI target also builds | First target record 08:48:06.026; final bundle touch 08:49:04.433 | All seven UI source/helper files compile, followed by UI test linking and bundle construction. This 58.4 s observation span overlaps other targets and is not an achievable savings estimate. |
| App emits runtime diagnostics | Embedded app timestamps begin 08:49:33.284 | Confirms the app process had launched by this point. There is no explicit complete install/launch timing breakdown. |
| Native suite begins | Embedded XCTest 08:49:38.247 | 220.6 s after the logged test command, and 513.8 s after the workflow step began. The 33.8 s after the last recorded UI bundle touch includes package-graph output and app launch; it is not all measured launch time. |
| Final started case | Receipt 08:49:41.948 | `ProjectDocumentIOTests.testSymbolicLinkDirectoryAndFIFOAreRejectedWithoutFollowingOrBlocking` starts, with no completion recorded. |
| Job cancellation | 08:57:50.870 | 488.9 s after that case's start receipt. No successful suite result exists. This log alone does not establish the scheduler's cancellation cause. |

Before the unfinished case, the log records **18 native cases passed**: nine bounded-reader, three PDF and six coordinated-document cases. The bounded-reader nonregular-file case itself passed; the later coordinated-document nonregular-file case did not complete. Do not merge those distinct observations or call the native suite successful.

## Evidenced next CI packet

The unit-only invocation nevertheless compiles and links `KeyAndFillUITests`. A future bounded packet can introduce or evaluate a dedicated native-unit scheme/build graph that includes the app, core and native unit target, while retaining the separate UI schemes/shards and exactly-once class coverage. Acceptance must show that the unwanted UI compile/link records disappear, the full native unit set still executes, and all three UI shards retain their tests. Measure the resulting complete job; no speedup is claimed here.

The log also relinks the application and creates a LightingCore package framework during the test action. It does **not** prove those operations are unnecessary: an ordinary app build and a test-host build can require different products. No cache, runner-pool or linker-setting change is justified by these records alone. The 3:29 explicit boot elapsed also shows why describing the entire 8:34 pre-test interval as compilation would be wrong.

## Incidental visible issue

The launched app repeatedly logs that `light.metering.center.weighted` is absent from the system symbol set. Both Meter labels still use that exact name in the current `App/StudioView.swift` source inspected during this follow-up. This is historical runtime evidence plus a matching current call site, not a current visual check. A small later UI packet should select a supported symbol and verify it on the declared deployment baseline. The active candidate is left unchanged while its native workflow runs.
