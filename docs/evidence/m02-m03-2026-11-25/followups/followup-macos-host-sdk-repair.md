# Bounded macOS host SDK repair

## Failure and scope

Base: `b298b1333f3abb901c23a198187628fe94331427`. Run `45600372389`, Intel job `139160177457`, failed before the EFBIG probe: direct Xcode 26.6 `swiftc` reported `unable to load standard library for target 'x86_64-apple-macosx26.0'`. Its recorded command had no `-sdk`; the separate Swift package step had passed 319 tests. The preserved failure remains `docs/evidence/m02-m03-2026-11-25/validation/checkpoint5-macos-probe-failure.log` and the original workflow log. This repair does not relabel that failure as a probe result.

Only `scripts/run_atomic_library_write_probe.py` and the focused new regression file `scripts/tests/test_atomic_library_probe_sdk.py` were edited. No application, workflow, thresholds, selectors, skips, deadlines, state, or documentation was changed by this worker. No commit or push was performed.

## Repair

Darwin now discovers the **host macOS SDK** with the exact argument array `xcrun --sdk macosx --show-sdk-path`, using the existing logged child runner and ten-second metadata deadline. The command inherits the same environment as the compiler; the manifest records `DEVELOPER_DIR`, `TOOLCHAINS`, and `SDKROOT` explicitly. The host SDK selector avoids choosing the iOS simulator SDK for this executable.

The compile manifest retains discovery arguments, raw-log paths, return/timeout observation, returned SDK path, and resolved path. Discovery receipts are written before exit-status, decoding, or path validation. Missing xcrun, timeout, nonzero exit, malformed output, or a non-directory path fails before compilation or any probe. A valid result becomes one `-sdk SDK_PATH` argument pair, preserving spaces and the original compiler invocation path.

Linux does no SDK discovery and retains the original compiler argument order. Existing 180-second compilation, shared 140-second probe work budget, process cleanup, resource isolation, source/binary binding, and all EFBIG/commit assertions are unchanged.

## Actual verification

- `python3 -m unittest discover -s scripts/tests -p 'test_*.py'`: **35 passed** in 0.351 seconds, including seven new tests and five malformed-path subcases. New tests mock and prohibit child execution; they verify command construction, selected environment, paths with spaces, failure provenance, and fail-closed behavior. They are not an actual Apple SDK/compiler run.
- Actual Linux integrated wrapper with root's absolute Swift 6.4.3 compiler and `--with-commit-interruption`: **exit 0 / passed**. Compilation took 26.318 seconds; all 31 Swift source hashes remained unchanged; all **11 EFBIG checks** and **three strict commit/interruption scenarios** passed. The actual Linux command contained no `-sdk`, and its manifest had no `hostSDK` entry.
- `git diff --check` passed. Agent-cycle structural check/next passed and retained outstanding native-build/persistence-smoke gates; structural validity is not release evidence.

Receipts: `/var/tmp/keyfill-c0abc39c4f18/sdk-repair-validation/python-tests.log`, `summary.json`, `linux-integrated.log`, and complete `linux-integrated/` artifacts, including compiler/source manifests and all probe snapshots/logs.

## Frozen handoff

Wrapper SHA256: `d8c036aa7348fba636c4f9c41d3d6468e112c34445756eff4cf98befe87ae7d3`.

Regression-file SHA256: `a82c613240110043c95f0606f32600316fde383f33e6f79e6e512dacc35eae64`.

a100 independently reviewed the frozen source, regression tests, original failure excerpt, and actual Linux manifests/results, and reported no blocking finding. Root owns integration and the next Apple CI run. **The repaired macOS compile and EFBIG execution remain unverified until that run executes.**
