# A023 measured JSON Unicode validation cost

The working fix has a substantial cost on valid, string-dense ignored metadata.
The 8 MiB empty-string array rose from **127.8 ms to 2393.5 ms** (18.7×), while the
141-byte ordinary document remained about **0.035 ms**.

| Ignored metadata at exactly 8 MiB | Baseline median ms | Current median ms | Ratio |
|---|---:|---:|---:|
| One long ASCII string | 35.953 | 53.479 | 1.49× |
| 2,796,151 empty strings | 127.815 | 2393.527 | 18.73× |
| 270,595 escaped strings | 28.543 | 390.398 | 13.68× |
| 559,230-member wide object | 863.344 | 1285.120 | 1.49× |

The same effect appears at 1 MiB: empty-string arrays rose **15.0 → 261.3 ms**;
escaped arrays **3.34 → 41.39 ms**. Every input decoded to the expected scene.

This used Swift 6.0.3, `-O -whole-module-optimization`, Linux x86_64 on an Intel
Xeon Platinum 8573C. Both full production decoders shared one binary and identical
dependencies. Baseline was `9e2313cbffb01d66249458c64087cb66c7652cca`; only its two
type-name occurrences were renamed. Current parser SHA-256:
`c7c5af8d4a90d7a80edd9ae8d71dc46753275b882cd2bb026f9556e441179d4f`.

Each median uses three independent processes, one warmup and one timed decode;
paired parser order alternated. File reads were untimed. The tiny control batched
1000 timed decodes per process. Raw times are in `full-raw.jsonl` and
`full-summary.json`; `manifest.json` records all source/input sizes and hashes.
`build.json`, source copies and scripts make the probe repeatable. All 54 full
matrix processes exited successfully.

Whole-process peak RSS was approximately unchanged for dense arrays/objects:
the 8 MiB empty array was about 153 MiB in both variants. The long string increased
from about 34.4 to 50.3 MiB. RSS includes input and warmup, not just the scanner.

**Recommendation:** preserve Unicode rejection, but optimize repeated per-value
token allocation/decoding and rerun this matrix plus the Unicode/duplicate-key
regressions. The importer already uses a utility worker; its cancellation checks
surround the decode, so they cannot interrupt this scan. This is measured host
import/cancellation-latency risk, not evidence of a UI freeze, a new gate, or device
performance. Three samples do not establish tail latency.
