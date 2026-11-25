# UI build timing investigation and bounded boot-order candidate

Existing worker a099 follow-up; 2026-11-25. Baseline main: `214ca90bbd166482277d33d63b89c1472ba9abf6`. This follow-up adds no distinct worker. Candidate is uncommitted and unpublished.

## Finding

The examined native and UI Debug builds perform the same compiler work. Their logged elapsed times differ substantially, especially before compilation. There is no measured CPU, memory, swapping, or host-exhaustion evidence establishing the cause. Moving explicit simulator boot after the UI build is a small, supported ordering candidate; faster builds and better accessibility-audit reliability remain unproven.

## Actual timing evidence

All intervals below use GitHub log timestamps, from the build step's `Run` group to `TEST BUILD SUCCEEDED`; they are elapsed log intervals, not task CPU measurements. The final interval includes compilation, resources, linking and packaging rather than isolated Swift compilation.

| Logged interval, seconds | f6 native, job 139182923426 | b298 library, job 139160177595 | f6 room, job 139182923435 |
| --- | ---: | ---: | ---: |
| Step group to Xcode invocation output | 1.667 | 167.828 | 127.333 |
| Invocation to target graph output | 16.963 | 165.290 | 114.423 |
| Target graph to build-description output | 7.329 | 28.416 | 9.461 |
| Build description to successful build | 118.069 | 234.771 | 167.497 |
| Total observed build span | **144.027** | **596.305** | **418.714** |

Native: 11:51:32.975–11:53:57.002 UTC. Historical library: 11:10:19.396–11:20:15.701. Same-run room: 11:51:25.845–11:58:24.559. Thus the historical library build is about 9m 56s and the f6 room build about 6m 59s; the reported 16–22-minute f6 library/studio build observations must not be generalized to every UI shard. Their complete logs were not examined in this comparison.

The library's pre-description span is **361.534s**, versus **25.958s** native, accounting for about 74% of the 452.278s total difference. Its step header itself spans about 34s before the shell/environment header completes, followed by about 134s before Xcode's invocation output. The first package-resolution gap is about 112s versus 11s native. These delays precede app/test compilation. Later app compilation also has longer logged gaps, but the log does not isolate their CPU or resource causes.

## Build scope and host evidence

The native and historical library graphs each contain the same five target entries: `KeyAndFillUITests`, `KeyAndFillTests`, `KeyAndFill`, and two `LightingCore` package target entries. All four complete `builtin-SwiftDriver` command strings are identical after removing log timestamps: same `-Onone`, `-j4`, batch mode and `x86_64-apple-ios17.0-simulator` target. Unique per-file compilation entries are identical: 30 LightingCore, 44 application/generated sources, 8 UI-test sources and 13 native-test sources (95 total). Both log 111 `SwiftCompile` entries including batch headers, 119 explicit PCM generation operations, four emitted modules, one Metal compilation and seven links. Native's `-only-testing:KeyAndFillTests` does **not** eliminate UI-test compilation in these observed builds.

Both use macOS 26.6.1/25G76, Xcode 26.6/17F113, Swift 6.3.3 and Intel x86_64, but different runner machines and preceding workloads. Native ran macOS portable tests and the SDK/persistence helper before the app build; those possible warm-up effects were not controlled.

Neither full log contains resource-pressure, swapping/pageout, out-of-memory, killed-process, thermal, or storage-exhaustion diagnostics. Neither records CPU or memory telemetry. Both boot logs contain migration/system-app waits. The historical UI boot reports terminal `Finished` before compilation, so these logs do not establish simultaneous initial migration and compilation. The simulator remains running during the old UI build. Some embedded boot timestamps precede GitHub ingestion timestamps by tens of seconds, demonstrating buffering; individual output gaps cannot be treated as exact execution profiles.

Historical b298's two `Code=-56` audit-service timeouts are established runtime failures separate from build duration. This comparison does not diagnose the newly reported f6 library failure or establish any relationship between boot order and audit failures.

## Exact candidate and validation

Only `.github/workflows/ios-prototype.yml` is modified in the repository. UI order changes from `select → boot → build → test` to `select → build → boot → test`. Git displays the seven-line build block moved immediately before the unchanged boot block: seven insertions and seven deletions. Every build/test command, boot-body byte, test selector, full accessibility audit, runner choice, deadline, artifact action and other workflow byte is preserved. Library remains ARM; room/studio remain Intel.

This avoids explicitly running the selected simulator throughout compilation. Native provides feasibility evidence: it selected the available iPhone 17 Pro in `Shutdown` state at 11:51:32.963, successfully completed Debug and Release builds, then explicitly booted at 11:56:20. The candidate does not change the active f6 run. It also provides no test-runtime reduction and cannot repair a late XCTest/export failure by itself.

Validation performed locally:

- YAML parses successfully.
- Entire candidate text equals the baseline text with only the adjacent build/boot block relocation; both raw blocks are byte-identical.
- Entire parsed YAML equals the baseline document with only those two UI steps swapped. All 39 workflow steps remain present.
- `git diff --check` passes.
- No build, source test suite, CI rerun, resource purchase, timeout change, commit or push performed. Independent review was requested from existing worker a097.

Baseline workflow SHA256: `78fa24a8a6da06f60e95989256d186853604392b9feea21f151a7210338f4e0e`.
Candidate workflow SHA256: `f771ff14b9f5c5dad21eeedbf831c66df587447ce177d2caa3270e117f1b6f48`.

Actual acceptance requires a subsequent authorized CI run to demonstrate build, boot and test behavior under unchanged limits. Assess combined build-plus-boot elapsed time, not merely movement between step labels; evaluate any audit result independently. Await the terminal f6 library/studio evidence before an integration decision.

## Primary receipts inspected

- Full f6 native decoded log: `/var/tmp/keyfill-c0abc39c4f18/f6-native-terminal-triage/complete-terminal-decoded.log`, 5,348 lines, SHA256 `22b526aada515a858c9ed8ef7d133e5434d178e1647f6fff054e0b51b62f16d1`; repo copy-manifest in `docs/evidence/m02-m03-2026-11-25/validation/f6-native-terminal/` binds it.
- Historical b298 library full log: `docs/evidence/m02-m03-2026-11-25/validation/library-intel-timeout/job.log`, 4,126 lines, SHA256 `3028873ca24a890ea4103a60ca2d0af003e3fd521fb53539aa80f7603f555b4e`.
- Same-run f6 room timing cross-check: `/var/tmp/keyfill-c0abc39c4f18/f6-ui-terminal-triage/room-precision/complete-terminal-decoded.log`, 3,633 lines, SHA256 `dae61a8bcd23d864b3242b7b8e30586b3a46e97567b2f3f84ecc65ee2b73b1cf`.
- Exact baseline workflow from `git show 214ca90bbd166482277d33d63b89c1472ba9abf6:.github/workflows/ios-prototype.yml` and the candidate working file.
