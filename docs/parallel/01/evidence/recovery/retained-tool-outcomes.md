# Retained terminal outcomes

These excerpts were returned to the coordinator before execution-environment loss. The complete raw logs and full source manifest were committed locally at `f851500` but were not published before the environment disappeared. These excerpts are not reconstructed full logs and do not establish acceptance of the recovered remote tree.

## Clean session-extraction run

Local source subsequently committed as `7c6f1c0`; Swift6.2.1 Linux, one job, batch compilation disabled:

```text
Test Suite 'debug.xctest' passed at 2026-11-26 04:20:03.863
	 Executed 383 tests, with 0 failures (0 unexpected) in 12.609 (12.609) seconds
Test Suite 'All tests' passed at 2026-11-26 04:20:03.863
	 Executed 383 tests, with 0 failures (0 unexpected) in 12.609 (12.609) seconds
```

The test runner's displayed timestamps use its host-local time; no timezone conversion or device-runtime claim is inferred.

## Additional worker04 contract suite

Local integration commit `538d45d`, after the preceding full run:

```text
Test Suite 'StudioFeatureContractTests' passed at 2026-11-26 04:22:10.586
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'Selected tests' passed at 2026-11-26 04:22:10.586
	 Executed 8 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
```

The full suite was not rerun after adding these eight tests before the outage. Do not relabel these two executions as one391-test run.

## Earlier observed failures

Both selected Linux toolchains exposed `libswiftObservation.so: undefined reference to swift::threading::fatal(char const*, ...)`. The native Observation adapter is now Darwin-only; the same session orchestration executes in portable tests without a Linux UI-observation dependency. An initial compile exited by signal9; unused embedded toolchain targets were removed and compiler work serialized. Disabling indexing caused missing test-discovery index units, so indexing was restored. A clean build removed obsolete autolinks and produced the383-test pass above.

## Environment boundary

A later process creation failed with `exec-server transport disconnected`; the subsequent probe returned `No usable execution environment is available`. Further filesystem/build work was stopped. Already returned source edits and reports were recovered through connected GitHub tools. Fresh recovered-source runtime verification remains required.
