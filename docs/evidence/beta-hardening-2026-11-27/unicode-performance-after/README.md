# A027 — strict JSON string validation fast path

## Change

Only the project document scanner and its Unicode regression test file were modified in APP1. Object keys and escaped string values still use scalar Foundation JSONDecoder. Non-key values without escapes reject raw controls during the byte scan; ASCII needs no allocation, while non-ASCII uses the non-repairing `String(validating:as:UTF8.self)` initializer. Duplicate decoded key policy, envelope and size checks, unknown scene metadata support, and UTF-16/32 conversion are unchanged.

## Correctness

Swift 6.0.3 Linux, `swift test --jobs 2` with a task-private build, cache, module-cache and temp directory: **30 focused tests passed, zero failures**, including the previous 28 methods plus raw-control and quote/backslash boundary regressions. New coverage checks every raw control byte from 0x00 through 0x1F in four locations, escaped quotes and zero through four backslashes before closing delimiters, duplicate keys and malformed UTF-8 after those tokens, and accepted UTF-8 boundary scalars (including DEL and noncharacters). Existing malformed UTF-8, unpaired escaped surrogates, duplicate keys, encoding compatibility, unknown metadata, byte limit, and document validity tests all passed.

Exact command, timings and log are in `focused-debug-receipt.json` and `logs/focused-debug.log`. The Debug build took about 60 seconds; the tests took 4.243 seconds. Root will run the integrated suites. This packet does not claim Apple runtime or device performance verification.

## Measurement

A023 originals are untouched. All A023 dependency sources and nine input fixtures were copied without changes; candidate parser alone replaced the current parser. The old current parser was added with only its two type-name occurrences changed to `BeforeProjectDocument`. The original legacy baseline remains intact. The same optimized WMO executable compares all three variants, rotating their order over three process samples per fixture. Large inputs use one untimed warmup and one timed decode; ordinary inputs use ten warmups and 1000 timed decodes. File reads are outside timing. Every result checks the expected decoded name and scene. All 81 full samples exited successfully; all medians were recomputed from the retained JSONL. A one-sample unwarmed pilot preceded the full run.

| Input | Legacy baseline ms | Strict before ms | Candidate ms | Candidate / before |
|---|---:|---:|---:|---:|
| ordinary | 0.0412 | 0.0365 | 0.0384 | 1.0543 |
| long_string_1mib | 5.5274 | 6.5952 | 2.5377 | 0.3848 |
| empty_strings_1mib | 16.0303 | 277.3550 | 13.2921 | 0.0479 |
| escaped_strings_1mib | 3.3892 | 45.8844 | 45.2823 | 0.9869 |
| wide_object_1mib | 88.2293 | 139.9251 | 99.8051 | 0.7133 |
| long_string_8mib | 40.1912 | 54.8442 | 22.6801 | 0.4135 |
| empty_strings_8mib | 190.0611 | 2361.7288 | 160.6330 | 0.0680 |
| escaped_strings_8mib | 27.6289 | 393.2155 | 372.1802 | 0.9465 |
| wide_object_8mib | 903.2400 | 1290.5959 | 796.4442 | 0.6171 |

The 8 MiB array of 2,796,151 empty values decreased from 2361.7288 to 160.6330 ms (14.70 times faster, 93.20% less time). Ordinary control medians were 0.0365 and 0.0384 ms; three samples do not establish equivalence or a tail distribution. The escaped-value path remains scalar Foundation decoding: the 8 MiB escaped-array candidate is still 13.47 times the legacy baseline. This scoped change deliberately retains strict validation. Host medians are observations, not an iPhone/iPad performance claim or a new threshold. The A023 baseline timings differ from this run; comparisons here use the matched three-variant run.

## Artifacts and hashes

`candidate.patch` preserves the two-file diff. `before/`, `sources/`, `inputs/`, `main.swift`, `build_and_run.py`, and `manifest.json` allow reproduction. `build.json`, `pilot-raw.jsonl`, `full-raw.jsonl`, `full-summary.json`, and `verification.json` retain commands, toolchain, output validation, raw samples and summary checks.

- `Sources/LightingCore/LightingProjectDocument.swift`: `c1bd09b7a11e54bff4ae59b09a6affcd5e550eca4dadc76f92d18cadf2319bea`
- `Tests/LightingCoreTests/ProjectDocumentIgnoredUnicodeTests.swift`: `3061207a0e791ee2c222dec311214b1acf249637e58b10f43b6d7a6c5d77549d`
