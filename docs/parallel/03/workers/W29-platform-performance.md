# W29 — platform/performance

Runtime/task: `/root/wave03/platform_performance` (actual name exposed by `collaboration.list_agents`; no separate opaque ID exposed). Input/private tree: `1cefc654630a86ab320e58283957f4e91d6cbce6`, `/tmp/keyfill03-7f4b/workers/W29-platform-performance`.

**Finding:** retained `baseline-benchmark.json` labels source `f150f98e35dd735927075aac4d2f8b02295c6a67`, optimized, seven samples, 8 frame/12 cancellation/4 visibility records. It cannot establish current-source performance: the baseline-to-input production diff contains exactly `PortraitHeadMesh.swift` and `ReferenceStudy.swift`.

Mesh triangles now retain a geometric normal and twice-area; construction adds normalization and storage, while successful hits reuse that normal. The angular determinant cutoff admits additional grazing intersections, potentially changing work/images. Neither net speed nor memory benefit is measured. Lazy shared-mesh initialization remains a cold-start diagnostic limitation. Sphere setup adds an early cancellation poll before camera/sample preparation; the existing timed cancellation matrix covers busts, so it does not measure sphere early-cancellation latency. Existing functional evidence is separate.

**Smallest remaining execution (root only):** one fresh-process run of the unchanged complete harness from this clean revision, using the available Swift toolchain and a root-owned `$OUT` directory:

```sh
swiftc --version > "$OUT/compiler.txt"
swiftc -O Sources/LightingCore/*.swift scripts/benchmark-study.swift -o "$OUT/benchmark-study"
"$OUT/benchmark-study" --samples 7 --revision 1cefc654630a86ab320e58283957f4e91d6cbce6 > "$OUT/current-benchmark.json"
```

Retain all 8 frames, 12 probes and 4 visibility workloads; one warm-up and seven measurements for frame/visibility workloads, raw samples/p50/p95 and host/compiler/revision. Verify repeated-byte equality, zero unsupported pixels and **all 12 `cancelled=true`**: the harness itself permits `cancelled=false` when no deadline was observed. No additional cold-start gate or historical rerun is needed. Timing remains host diagnostic, without portable/device thresholds.

Actual read checks: mandatory four documents in one batch; `git rev-parse`, `status`, `show --stat`, baseline-to-HEAD source-name diff and parent-to-HEAD source diff; JSON metadata extraction; harness read; targeted `rg` for mesh initialization/provenance/build commands. An initial provenance regex returned no matches (exit 1). W21 accounting/W27 identity work was not repeated. No builds, benchmarks or tests executed. Final private HEAD unchanged; `git status --short` empty. Only this assigned report was written outside the private tree.
