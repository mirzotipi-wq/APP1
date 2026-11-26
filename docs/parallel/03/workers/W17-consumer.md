# W17 — Original fixture artifact checks

Runtime/task: `/root/wave02/consumer`. Input: `9c172d3e2d0c3f18636d84e8f31150236c63cbaa`.
Private worktree: `/tmp/keyfill03-7f4b/workers/W17-consumer`, recreated after the environment interruption; initial HEAD/status verified clean. No earlier W17 context or execution existed.
Output: `/tmp/keyfill03-7f4b/builds/W17-consumer`.

## Actual result

`TMPDIR=/home/agent/keyfill03-7f4b/tmp python3 /tmp/keyfill03-7f4b/builds/W17-consumer/check_original_fixtures.py` exited 0.

All twelve required fixture names and their scene JSON/PPM files are present. Every scene parses as schema 5 with finite numeric values and unique light IDs. Strict P6 parsing verified dimensions, maximum channel value 255 and exact RGB payload sizes: seven 120×80 sphere images and five 144×96 bust images, totaling 136,320 pixels. Manifest dimensions and declared RGBA/mask lengths are internally consistent; all record zero unsupported pixels and no validation errors. Direct RGB inspection found zero pure-magenta pixels.

All ten `differentPixelsFromComparison` counts reproduce exactly from archived RGB bytes, including 911 changed pixels for bust-roll-90 versus bust-soft. All 25 baseline SHA-256 entries for JSONs, PPMs and manifest match. Before/after hashes confirm every original artifact remained unchanged.

## Limits and provenance

No raw validity-mask or RGBA files are archived here. PPM preserves RGB only; mask sizes/counts remain manifest evidence, and alpha bytes or exact mask positions cannot be independently checked from these artifacts. Nonzero image differences and coverage labels do not prove triangle intersections, finite visibility, authored geometry or photometric accuracy.

Required directives, fixture-writer storage/validation code and Git state were read. `agent_cycle.py check`/`next` exited 0: structure valid, M03 gates outstanding, not runtime acceptance. No source edit, commit, Swift build/test, rerender, visual image review, native/Metal execution, cleanup or physical-calibration claim.

Reproducible script: `check_original_fixtures.py`; per-fixture metrics, ten comparisons and hashes: `original-fixture-checks.json` in the output directory.
