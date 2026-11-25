# UI outcome provenance, bounded host snapshots, and availability fallback

**Prepared candidate; runtime improvement is unproven.** Baseline: `214ca90bbd166482277d33d63b89c1472ba9abf6`. Final workflow SHA256: `6792b1c16bd96ceba120e1906c9ee7ebdbaab01d8b8fbfaf0da39f8b2c29fbdb`. Exact diff SHA256: `b7ecd7ac867e1f05007f7438b98a401c2237ef01f5d88dc068c26f06c358a208`.

## Concrete defect and resulting diagnostic fields

The actual f6 studio step recorded an assertion failure and GitHub's 40-minute timeout, while its trap-derived status file said `test_exit_code=0`. The candidate gives the required UI step the fixed ID `selected_ui_tests`. The collector now receives `${{ steps.selected_ui_tests.outcome }}` through a step environment variable and writes it as `github_test_step_outcome`. The old trap observation is retained verbatim under the distinct field `observed_shell_exit_code`; no signal or process exit code is invented.

[GitHub's steps-context reference](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#steps-context) defines `outcome` as the completed step's result before optional-error handling, with success/failure/cancelled/skipped values. The required UI step has no optional-error waiver. Its complete shell body, EXIT trap, test selector construction, xcodebuild invocation, and failure propagation are **byte-identical to baseline**. The existing trap's internal environment-variable name is retained; only its serialized diagnostic label changes.

## Optional host observations

Two best-effort steps run immediately before and after UI tests. Each captures `vm_stat`, `sysctl vm.swapusage hw.memsize`, process PID/PPID/CPU/RSS/`comm`, and disk space for the workspace and runner temporary directory. Commands use explicit argument arrays, never full process arguments or an environment dump. Each command has a **five-second timeout**, and each recorded output is limited to **65,536 characters** with a truncation marker. Each diagnostic step has a **one-minute bound** and `continue-on-error: true`; the after step uses `always()`.

Full UI evidence gains `artifacts/ui-host-before-tests.log` and `artifacts/ui-host-after-tests.log`. Command errors/timeouts remain diagnostic observations and do not replace the required UI outcome. After-step collection remains best effort: runner loss or a hard job termination can prevent further steps or uploads. These two snapshots do not establish resource pressure or its causal role.

## Ordering and runner scope

The previously reviewed build-before-boot relocation remains: select the available simulator, build the UI bundle, boot it, then run the unchanged UI tests. This matches the successful native sequence but has no claimed timing or accessibility benefit yet.

The final candidate **changes library-reference from `macos-26`/`arm64` to `macos-26-intel`/`x86_64`** following the actual 214 ARM job's cancellation with runner ID zero and zero executed steps. Its adjacent comment explains the acquired Intel pool and retained full audits. Room, studio, and native-unit runner choices remain unchanged. This is an acquisition fallback; it does not establish that Intel accessibility service failures are repaired, and it supplies no ARM RealityKit acceptance.

All selectors, full accessibility audits, required assertions, Xcode 26.6/iPhone 17 Pro/iOS 26.5 requirements, existing commands, test/build/boot/job deadlines, retry/skip behavior, concurrency, and existing artifact paths remain unchanged. Host logs are an additive full-evidence path. No deadline relaxation, test split, rerun or product edit was introduced.

## Validation and history

The initial diagnostic/ordering candidate `7f2be855ca5b5dd39edff2a1751b5ddb1efe1870c75cbb0f0e49aa0a0d6ddedd` passed YAML parsing, **29 shell-block syntax checks**, **seven inline-Python parses**, exact required-run-body comparison, whole-document restoration after approved changes, and `git diff --check`; root independently reviewed that source. Its original diff and validation are retained under `prior-7f2be855-*` filenames.

The final candidate is proven byte-for-byte identical to that reviewed candidate except for the two library matrix values and the explanatory comment. A complete YAML comparison and diff check passed for that final delta. Thus the executable blocks covered by the earlier checks are unchanged. The final validation explicitly records the runner change; the historical runner-preservation claim applies only to the earlier candidate. No mirror tests were added. Actual macOS execution of the new diagnostic steps remains pending CI.

Stable validation packet: `../validation/ui-host-diagnostics/`. The bounded actual failure receipt is `followup-f6-studio-terminal.md` with `../validation/f6-studio-terminal/`; it preserves 14 passes, one failed post-relaunch status check, one interrupted method, and four unstarted methods without treating a trap value as a successful test verdict.
