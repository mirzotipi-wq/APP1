# A042 — reproduce the parser comparison

The compact A023/A027 packets omit their generated inputs. A023's original
`prepare.py` also assumes an obsolete checkout location and rewrites its source
snapshot. Keep those historical files intact; use these commands from the
repository root with Python 3.9 or later.

## Reconstruct inputs without Swift

```sh
PARSER_REPRO="$PWD/docs/evidence/beta-hardening-2026-11-27/reproduce-parser-benchmark"
PARSER_WORK="$(mktemp -d "${TMPDIR:-/tmp}/app1-parser.XXXXXX")"
python3 "$PARSER_REPRO/reconstruct_inputs.py" --output-dir "$PARSER_WORK/fixtures"
```

The generator extracts only A023's original byte-building logic. It pins both
original manifests and the original preparation script, compares all nine
fixture records, then checks the written bytes against both manifests. The
141-byte control plus four shapes at 1 MiB and 8 MiB total **37,748,877 bytes**.
Generated hashes and sizes appear in `fixtures/verification.json`.

## Optional fresh three-variant measurement

After the coordinator releases the compiler slot, provide an installed Swift
toolchain explicitly. The original measurement used Swift 6.0.3 on Linux x86_64.

```sh
python3 "$PARSER_REPRO/run_benchmark.py" \
  --swift-toolchain /absolute/path/to/swift-6.0.3/usr \
  --fixtures-dir "$PARSER_WORK/fixtures" \
  --output-dir "$PARSER_WORK/run" \
  --compiler-released-by-root
```

This copies hash-verified A027 dependencies, harness and runner into the new run
directory. It compares `baseline`, `before` and `current` in one optimized binary,
retaining the original pilot and 81-sample full protocol. Sources, inputs, caches,
temporary files, executable, logs and new measurements stay there. All destination
directories must be new and outside the preserved evidence tree; collisions are
rejected. Choose another run directory to repeat.

**A042 verification:** all nine fixtures regenerated with exact sizes and hashes;
existing destinations and protected paths rejected. See `verification.json`.
The new measurement wrapper was reviewed but **not executed**. No new compilation,
benchmark timings or device-performance result is claimed.
