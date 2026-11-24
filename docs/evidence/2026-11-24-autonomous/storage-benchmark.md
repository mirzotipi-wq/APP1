# Project-library storage measurements — 2026-11-24

## Finding and limits

A normal one-project save is small in this host measurement. A full 64-project, twelve-light-per-project library costs materially more, and a supported legacy combining-mark name near the file-size limit dominates validation and save time. The largest measured median save is **669.938 ms**, including validation, optimistic read/compare, encoding and atomic replacement.

This is a **shared Linux CPU and tmpfs filesystem benchmark**, not iPhone latency, physical-disk throughput, a UI trace, cold startup, memory usage, power-loss durability or a release-gate result. No production implementation changed. The evidence identifies a bounded asynchronous-storage follow-up; it does not justify skipping validation, dropping old names or weakening stale-snapshot protection.

## Reproducible source and environment

- Frozen LightingCore source: `0fce248b4e61bace88002b40f6c56fddedb19c8a`, exported with `git archive` into a scratch directory before compilation.
- Swift **6.4.3**, `swiftc -O`, x86_64-unknown-linux-gnu.
- Linux **6.18.57**, Debian 13 environment, AMD EPYC **9V74**, nine exposed logical CPUs.
- `FileManager.default.temporaryDirectory` resolves to the host's **tmpfs** filesystem. Each run creates one UUID-named root with three child stores, and the successful run removed that root before producing its output.
- One warm-up and **five measured samples per operation**, with no exclusions. Five-sample nearest-rank p95 equals the maximum observed sample; it is not an estimate of a long-run population tail.
- The complete measured run took **11.937055001 seconds**, including fixture construction and out-of-timer verification, excluding compilation and JSON-result encoding.

The fixtures use deterministic project/light UUIDs and valid scene settings. The single-project fixture has three lights; the full library has 64 projects and twelve lights per project. The large-name fixture has three lights and the project name `Legacy` followed by 4,000,000 U+0301 combining marks. It is six graphemes and 4,000,006 scalars, and is accepted by the legacy-compatible storage contract. The bounded new-name entry UI does not create this name; preservation/import of existing data can encounter it.

| Fixture | Encoded bytes | Fraction of 8 MiB limit |
| --- | ---: | ---: |
| One project, three lights | 1,979 | 0.024% |
| 64 projects, twelve lights each | 370,588 | 4.418% |
| Legacy combining-mark name | 8,001,975 | 95.391% |

## Timing results

All values below are milliseconds. Encode creates the same pretty-printed, sorted-key JSON used by the file store, without an additional validation pass. Decode includes library validation. Load invokes the actual bounded file store. Save changes one real light intensity on every iteration, prepares that proposed snapshot outside the timed interval, then invokes the actual validation/locked comparison/encoding/atomic-write transaction. It does not time a no-op assignment or substitute an in-memory fake for file operations.

Every encoded result was compared with the canonical bytes. Every decoded/loaded value was compared with the fixture. Every successful save was reopened and compared with its expected value and canonical file bytes. Verification happens outside the individual timed interval, so it affects cache warmth and total run time but is not included in the operation sample. All warm-up and measured verifications succeeded.

| Workload | Operation | Median ms | Nearest-rank p95 ms |
| --- | --- | ---: | ---: |
| one project, three lights | JSON encode, pretty/sorted, without validation | 0.044 | 0.044 |
| one project, three lights | JSON decode plus library validation | 0.044 | 0.052 |
| one project, three lights | File store load, including read/decode/validation | 0.074 | 0.091 |
| one project, three lights | File store save, validation/CAS/encode/atomic replacement | 0.166 | 0.282 |
| 64 projects, twelve lights each | JSON encode, pretty/sorted, without validation | 7.028 | 7.330 |
| 64 projects, twelve lights each | JSON decode plus library validation | 8.522 | 12.237 |
| 64 projects, twelve lights each | File store load, including read/decode/validation | 7.789 | 7.934 |
| 64 projects, twelve lights each | File store save, validation/CAS/encode/atomic replacement | 26.964 | 34.960 |
| one project, approximately 8 MB legacy name | JSON encode, pretty/sorted, without validation | 20.451 | 22.465 |
| one project, approximately 8 MB legacy name | JSON decode plus library validation | 315.805 | 328.012 |
| one project, approximately 8 MB legacy name | File store load, including read/decode/validation | 319.649 | 369.643 |
| one project, approximately 8 MB legacy name | File store save, validation/CAS/encode/atomic replacement | 669.938 | 723.468 |

## Relationship to current UI code

`App/ProjectStore.swift` exposes synchronous throwing `load`, `save` and recovery methods. `StudioView.load`, `persistScene`, `applyLibrary` and `saveLibrarySnapshot` call those methods directly; initial load is called inside the view's `.task`, and save/application paths are reached from SwiftUI actions. Those inspected functions do not introduce an explicit background-executor hop. This is source inspection, not a native executor trace or measured UI stall.

A focused next implementation would move serialization and complete store transactions off the UI executor while retaining immutable expected/proposed snapshots, serialized comparison and replacement, and adoption only after confirmed success. It must define cancellation and edits arriving during a save without losing either the saved record or current in-memory work. Measure that flow on the agreed baseline iPhone before claiming responsiveness. Moving only the final file write would leave most of the large-name validation cost synchronous, and the tmpfs measurements already show that physical disk latency is not required to expose this cost.

## Exact reproduction

Run from the repository root with the recorded compiler available. The first command exports the pinned production source; the benchmark source is the companion committed script.

```bash
mkdir -p /tmp/keyfill-storage-source
git archive 0fce248b4e61bace88002b40f6c56fddedb19c8a Sources/LightingCore | tar -x -C /tmp/keyfill-storage-source
swiftc -O /tmp/keyfill-storage-source/Sources/LightingCore/*.swift scripts/benchmark-project-library.swift -o /tmp/keyfill-storage-benchmark
/tmp/keyfill-storage-benchmark > /tmp/keyfill-storage-benchmark.json
```

The executable itself uses a new UUID temporary directory, rather than the repository or the application's Application Support directory. The compile-directory example is separate from its temporary data stores. An error exits instead of emitting success metrics.

## Source and artifact hashes

| Item | SHA-256 |
| --- | --- |
| `ProjectLibrary.swift` | `0b6689015a9102d5b5ca6f309553455b48c047534432bc2c2b99726a242d73c4` |
| `Scene.swift` | `fbd552b5f35fa3fbacc10099b25eadf5853ab2bc9ae7013975db83c302513c74` |
| `SceneCodec.swift` | `f411f4f57bae222a60802686bccee78fb418f75f8102030dcc8931a4f90622ee` |
| `SceneFileStore.swift` | `4e1411ae2633433a173f6c49a0d36a3e99248794c83a8865b297d7377dcd5d83` |
| `benchmark-project-library.swift` | `f60e75dfd3f1df2048b6e3718f7ee8afbed311a50c706d609f6d06c1b4700669` |
| Optimized executable | `60ce86ebe8e5bcbf6f058d5dad9e35bf1a70e8289814913ada1e64d72545a54e` |
| Raw JSON below | `209765c33f77feb029e61b0b73d60d53b8df0489c24009843183df01587bbef5` |

The raw JSON hash includes its trailing newline. No timings were rounded in that artifact; displayed table values are rounded to three decimals.

## Complete raw output

```json
{
  "elapsedSeconds" : 11.937055001,
  "libraryByteLimit" : 8388608,
  "sampleCount" : 5,
  "temporaryDirectoryRemoved" : true,
  "warmupsPerOperation" : 1,
  "workloads" : [
    {
      "encodedBytes" : 1979,
      "fractionOfLibraryByteLimit" : 0.0002359151840209961,
      "lightsPerProject" : 3,
      "longestNameGraphemes" : 10,
      "longestNameScalars" : 10,
      "name" : "one project, three lights",
      "projects" : 1,
      "timings" : [
        {
          "medianMilliseconds" : 0.043695,
          "nearestRankP95Milliseconds" : 0.044496,
          "operation" : "JSON encode, pretty\/sorted, without validation",
          "samplesMilliseconds" : [
            0.044496,
            0.043695,
            0.042423,
            0.042193,
            0.043805
          ]
        },
        {
          "medianMilliseconds" : 0.044436,
          "nearestRankP95Milliseconds" : 0.051837,
          "operation" : "JSON decode plus library validation",
          "samplesMilliseconds" : [
            0.051837,
            0.045537,
            0.044225,
            0.044436,
            0.043695
          ]
        },
        {
          "medianMilliseconds" : 0.07393,
          "nearestRankP95Milliseconds" : 0.091446,
          "operation" : "File store load, including read\/decode\/validation",
          "samplesMilliseconds" : [
            0.083103,
            0.069924,
            0.091446,
            0.07393,
            0.064586
          ]
        },
        {
          "medianMilliseconds" : 0.165776,
          "nearestRankP95Milliseconds" : 0.282078,
          "operation" : "File store save, validation\/CAS\/encode\/atomic replacement",
          "samplesMilliseconds" : [
            0.206366,
            0.282078,
            0.156502,
            0.165776,
            0.160719
          ]
        }
      ]
    },
    {
      "encodedBytes" : 370588,
      "fractionOfLibraryByteLimit" : 0.04417753219604492,
      "lightsPerProject" : 12,
      "longestNameGraphemes" : 11,
      "longestNameScalars" : 11,
      "name" : "64 projects, twelve lights each",
      "projects" : 64,
      "timings" : [
        {
          "medianMilliseconds" : 7.028257,
          "nearestRankP95Milliseconds" : 7.329956,
          "operation" : "JSON encode, pretty\/sorted, without validation",
          "samplesMilliseconds" : [
            7.160735,
            7.006805,
            7.329956,
            6.951544,
            7.028257
          ]
        },
        {
          "medianMilliseconds" : 8.52157,
          "nearestRankP95Milliseconds" : 12.237125,
          "operation" : "JSON decode plus library validation",
          "samplesMilliseconds" : [
            12.237125,
            8.99905,
            8.52157,
            8.351169,
            7.076359
          ]
        },
        {
          "medianMilliseconds" : 7.789396,
          "nearestRankP95Milliseconds" : 7.934261,
          "operation" : "File store load, including read\/decode\/validation",
          "samplesMilliseconds" : [
            7.934261,
            7.884397,
            7.760664,
            7.382623,
            7.789396
          ]
        },
        {
          "medianMilliseconds" : 26.964268,
          "nearestRankP95Milliseconds" : 34.959957,
          "operation" : "File store save, validation\/CAS\/encode\/atomic replacement",
          "samplesMilliseconds" : [
            16.195561,
            16.097421,
            34.959957,
            27.734801,
            26.964268
          ]
        }
      ]
    },
    {
      "encodedBytes" : 8001975,
      "fractionOfLibraryByteLimit" : 0.9539097547531128,
      "lightsPerProject" : 3,
      "longestNameGraphemes" : 6,
      "longestNameScalars" : 4000006,
      "name" : "one project, approximately 8 MB legacy name",
      "projects" : 1,
      "timings" : [
        {
          "medianMilliseconds" : 20.450663,
          "nearestRankP95Milliseconds" : 22.46534,
          "operation" : "JSON encode, pretty\/sorted, without validation",
          "samplesMilliseconds" : [
            20.738731,
            20.442471,
            19.95542,
            22.46534,
            20.450663
          ]
        },
        {
          "medianMilliseconds" : 315.804551,
          "nearestRankP95Milliseconds" : 328.012105,
          "operation" : "JSON decode plus library validation",
          "samplesMilliseconds" : [
            309.121254,
            328.012105,
            322.690152,
            315.804551,
            311.446641
          ]
        },
        {
          "medianMilliseconds" : 319.648648,
          "nearestRankP95Milliseconds" : 369.642543,
          "operation" : "File store load, including read\/decode\/validation",
          "samplesMilliseconds" : [
            361.765512,
            369.642543,
            315.425078,
            319.648648,
            315.23786
          ]
        },
        {
          "medianMilliseconds" : 669.938184,
          "nearestRankP95Milliseconds" : 723.467586,
          "operation" : "File store save, validation\/CAS\/encode\/atomic replacement",
          "samplesMilliseconds" : [
            669.938184,
            723.467586,
            643.271747,
            709.622219,
            668.886009
          ]
        }
      ]
    }
  ]
}
```
