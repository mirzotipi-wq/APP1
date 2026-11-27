# A023: JSON Unicode validation cost probe

This scratch-only probe compares the full external project document decoder at
baseline `9e2313cbffb01d66249458c64087cb66c7652cca` with the working Unicode fix.
The input fixture scene is the valid minimal scene used by the Unicode regression
tests. Metadata is ignored by scene decoding but scanned by document validation.

The exact current LightingCore sources are copied into `sources/`. The baseline
parser is copied from `git show` and adapted only by replacing its two type-name
occurrences with `BaselineProjectDocument`, so both parsers run in one optimized
binary. `baseline-original.swift` retains the original. `manifest.json` records
the parser, dependency and input SHA-256 values.

Fixtures: one ordinary 141-byte control and four shapes at exactly 1 MiB and
8 MiB: one long ASCII string, an array of empty strings, an array of valid escaped
strings (paired surrogate, controls, quote, backslash, slash), and a wide object
with unique fixed-width keys and empty values. Up to 30 bytes of JSON whitespace
fill otherwise indivisible token sizes. Exact sizes/counts are in the manifest.

Preparation, without Swift execution:

```sh
python3 prepare.py
```

Only after root explicitly releases the compiler slot:

```sh
python3 build_and_run.py --compiler-released-by-root --phase build
python3 build_and_run.py --compiler-released-by-root --phase pilot
python3 build_and_run.py --compiler-released-by-root --phase full
```

The local staged Swift toolchain is read-only. Module caches, temporary files,
source copies, executable, logs and inputs stay inside this task directory. No
global install, repository edit, package build or other worker is used.

The full matrix collects three independent process samples per parser/input;
each large-input process warms the same decode once, then times one decode using
`DispatchTime` monotonic nanoseconds. Parser order alternates across rounds.
The ordinary tiny control batches 1000 decodes after ten warmups. Output is checked
against the expected name and scene in every call. Input loading is untimed.
`/proc/self/status` VmHWM gives whole-process maximum resident set in KiB,
including the input and warmup. Raw stdout and summary JSON retain all timings.

These are Linux host observations, with no new acceptance threshold or claim
about iPhone/iPad performance. Three samples are a bounded comparison, not a
latency distribution or tail-performance estimate.
