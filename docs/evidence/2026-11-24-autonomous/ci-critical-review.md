# Independent CI repair review

## Scope and conclusion

Wave 9 specialist 4 reviewed the pending repair on main above source `0fce248b4e61bace88002b40f6c56fddedb19c8a`. This is a separate source, shell-control and host-kernel review. It does not establish a successful Apple component installation, native compilation, simulator test or device result for the repaired source.

The missing-component diagnosis is supported by the retained actual job log. The preflight fails closed, tests a real compile and link when executed on a Mac, and uses Apple's documented installation command. The review found one concrete total-budget regression; the integration lead corrected it before the exact-source snapshot. The strict eight-control host regression is additional to the existing six-fixture check and preserves its thresholds.

## Observed failure

The retained `0fce248-room-precision-failure.log` identifies job `138314533755`, Xcode 26.6 build 17F113, and iPhoneSimulator SDK 26.5. At 08:38:03 UTC the Metal compilation step reports that the Metal toolchain is missing, followed by `TEST BUILD FAILED` and exit 65. The selected UI test step did not run. This supports an environment-component failure, not a demonstrated UI assertion or Swift source failure.

## Corrective finding: job budget

The added Metal preflight has a 12-minute step bound. Combined with the retained 25-minute UI build and 32-minute UI execution limits, those steps can use 69 minutes. The previous 70-minute job total then left at most one minute for checkout, environment recording, XcodeGen, simulator selection and evidence finalization. The observed failed job already took about a minute from environment setup to build invocation.

The integration lead changed the UI job total to **85 minutes**, leaving 16 minutes beyond the three bounded stages, and added an explanatory comment. The 12-, 25- and 32-minute stage limits and every test selector remain intact. The independent simulator build/unit job has a 50-minute total, increased from 35 to accommodate the new preflight. These limits remain operational bounds, not assurances about future runner speed or artifact service availability.

## Preflight review

- `mktemp -d /tmp/keyfill-metal.XXXXXX` gives each invocation its own directory. The EXIT trap quotes that path and removes only the owned probe directory.
- The probe writes a small Metal kernel, compiles it to an intermediate file, links a library and requires nonempty output. Locating an `xcrun` wrapper alone is not treated as success.
- The initial probe is intentionally a condition. Its explicit `&&` chain propagates compile, link and empty-output failures despite Bash's conditional `errexit` behavior.
- On a failed initial probe, the script makes one component-install attempt, then requires a successful full reprobe. Download failure and reprobe failure stop the script before its success message.
- Both workflow invocations use `set -euo pipefail` around the `tee` pipeline, so logging cannot hide a script failure. Both native evidence artifacts include `metal-toolchain.log` and use `if: always()`.
- All script constructs are compatible with the Bash features already used in the macOS workflow. Actual macOS execution remains pending.

Apple's current documentation was checked on 2026-11-24. [Downloading and installing additional Xcode components](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components) documents `xcodebuild -downloadComponent metalToolchain` as a combined download/install action. [Building a shader library by precompiling source files](https://developer.apple.com/documentation/metal/building-a-shader-library-by-precompiling-source-files?language=objc) documents compile-then-link through `metal`, and permits the SDK targeted by the app. No alternative third-party installer, privilege change or altered compiler acceptance is introduced.

## Strict precision integration

The new core step compiles the deterministic held-out fixture generator, uses the same host verifier compiled by the preceding six-fixture step, and selects six `area-camera-*` plus two `world-translation-*` controls. Its `--maximum-channel-error 1` requirement supplements the existing mean error, outlier fraction and invalid-count criteria. The verifier's default maximum remains 255, so the established invocation is unchanged. Malformed fixtures, missing files and a failed comparison return nonzero. The pipeline preserves that result and uploads `study-precision.log`.

I independently compiled the current C++17 host verifier with `-O2 -Wall -Wextra -Werror` and ran those eight existing deterministic buffers. **8/8 passed**, all with mean error zero, maximum RGB error zero and matching invalid counts. This reuses the previously generated Double reference buffers; it is not a fresh Swift reference generation or GPU execution. The complete 33-fixture diagnostic corpus still has the documented raw Float32 cutoff failures; this review does not relabel that corpus as passing. Production CPU eligibility routing is evaluated separately in the rendering review and portable tests.

## Actual verification

| Check | Result |
| --- | --- |
| Python unittest discovery | 28/28 passed, including all four committed preflight control-flow tests. |
| Independent linker-failure injection | Initial linker failure, successful installation and reprobe returned 0. Persistent linker failure returned 23 without a success message. |
| Independent empty-library injection | Initial empty output followed by successful installation/reprobe returned 0. Persistently empty output returned 1 without a success message. |
| Cleanup in all four independent cases | Exactly one install attempt; every owned probe directory removed. |
| Workflow shell syntax | All 22 `run: |` blocks passed `bash -n`. |
| Recursive native shard coverage | All six UI classes assigned exactly once across three shards. |
| State validation and next gate | Structure valid; M01 remains active with native build/persistence evidence outstanding. This does not verify evidence truth. |
| Strict host kernel controls | 8/8 passed; zero RGB differences, exact invalid counts. |

The independent failure injection used temporary Python stubs for `xcrun` and `xcodebuild`, not Apple tools. It checks shell control flow and cleanup only. No shared SwiftPM build was started by this reviewer.

## Reviewed hashes

| File | SHA-256 |
| --- | --- |
| `.github/workflows/ios-prototype.yml` after the budget correction | `8cceb09934ff653d015c3363a6671de9016e11f57c4e0970c5b8bbd2a4479b32` |
| `scripts/ensure-metal-toolchain.sh` | `f966000fae4d4b799ad898ff3c613b8d582a0423109e3aa6a6df92eafe93c159` |
| `scripts/tests/test_metal_toolchain.py` | `a500d59f82c346ba0e6adf236e57fcbd441d293686ad1c02a06008022af387b0` |
| `scripts/precision-boundary.swift` | `dc62c1091974aaf5b481cff217fa9e05e1f491af4e0a174bd7c118b4bb598bd5` |
| `scripts/verify-kernel-host.cpp` | `02a5f31856ad5ffbd8299da25a348b3e92ff9608f7ca6b39b2d5b9bec52d2e01` |

## Remaining acceptance

Inspect the repaired workflow's real preflight log, compiler/SDK details, unsigned builds, native units, all UI shards and finalized result bundles. A successful download alone is insufficient; the reprobe and app compilation must pass. Keep native failures, timeouts and cancellations explicit. A superseding source push can cancel an active native run under the existing concurrency policy; it must never be recorded as a successful result.
