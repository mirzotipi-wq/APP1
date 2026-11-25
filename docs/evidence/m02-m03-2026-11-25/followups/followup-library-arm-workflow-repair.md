# Scoped library/reference ARM runner repair

Base: `f6f43dde19be7a554bc5c6924e3239c18b34d1be`. Owned edit: **only** `.github/workflows/ios-prototype.yml`. No commit, push, cancellation, rerun, source change, or concurrency change was performed by this worker.

## Reason and resulting routing

Root/a100's terminal b298 evidence identifies both full library accessibility audits as Intel AX service `Code=-56` timeouts; the other nine library/reference tests passed. The earlier ARM run completed those audit calls and reported ten actual issues. Routing back to ARM aims to obtain completed full audits; it does not declare those prior issues fixed or reinterpret the Intel service failures as layout findings.

| UI shard | Standard runner | Required architecture | Test / job deadline |
|---|---|---|---|
| room-precision | `macos-26-intel` | `x86_64` | 32 / 85 minutes |
| library-reference | `macos-26` | `arm64` | 32 / 85 minutes |
| studio-export | `macos-26-intel` | `x86_64` | 40 / 93 minutes |

The UI job now selects `matrix.runner`. Its environment check receives `matrix.expected_arch` through the trusted `EXPECTED_RUNNER_ARCH` step environment and compares the quoted value with `uname -m`. The native unit job remains Intel and is byte-for-byte unchanged. The successful room/precision 5/5 result is separately preserved in `followup-room-precision-terminal.md`; root confirmed studio/export 20/20, so its routing remains unchanged.

Xcode 26.6, iPhone 17 Pro/iOS 26.5, all selectors and test methods, both complete `.all` accessibility audits, Metal gates, artifact collection, deadlines, fail-fast behavior, and matrix concurrency remain unchanged. No retry or skip was added. The ARM route has not yet executed and remains subject to runner acquisition and actual audit results.

## Validation and frozen evidence

- YAML parsed successfully; all **27 shell blocks** passed `bash -n`; all **five inline Python blocks** parsed with `ast`.
- Exact three-row runner/architecture/deadline mapping verified. Core and native-unit job structures are unchanged.
- Reversing only the approved runner fields, step environment, architecture assertion, and explanatory comment reproduces the complete prior workflow **byte-for-byte**.
- Shard validation passed: **seven UI classes assigned once across three shards**. Library selectors still include ProjectLibrary, ReferenceComparison, and the entire AccessibilityAudit class.
- **35 Python tests passed** in 0.377 seconds; `git diff --check` passed.

Receipts and exact patch: `/var/tmp/keyfill-c0abc39c4f18/library-arm-workflow-validation/` (`structural.json`, `validation-summary.json`, `python-and-shards.log`, `workflow.patch`).

Workflow SHA256: `78fa24a8a6da06f60e95989256d186853604392b9feea21f151a7210338f4e0e`.

Exact diff SHA256: `1923e7ff1095a3315b37eef9196d318aa8326b425477a10262d16aef7fe22ab0`.

a100 independently reviewed the complete frozen diff, matrix, toolchain, selectors, and validation receipts and closed review with no blocker at workflow hash `78fa24a8a6da06f60e95989256d186853604392b9feea21f151a7210338f4e0e`. Their scoped review is preserved in `/dev/shm/keyfill-a100-library-b298/report.md`. Actual ARM scheduling and full audit acceptance remain pending CI. Root owns the coherent next commit, publication, and any cancellation of the superseded workflow. The existing 100-worker count is unchanged.
