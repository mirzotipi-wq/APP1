# W09 — platform/performance

**Runtime/task:** `/root/wave01/platform_performance` (actual exposed ID).
**Input:** `f150f98e35dd735927075aac4d2f8b02295c6a67`.
**Worktree:** `/tmp/keyfill03-7f4b/workers/W09-platform-performance`.
**Status:** review completed; no build/test/render/source edit/commit.

## Executed probes

`TMPDIR=/home/agent/keyfill03-7f4b/tmp`; PATH prepended with `/workspace/scratch/13a77d3f98df/toolchain/usr/bin`.

- `pwd`: physical worktree uses `/home/agent/` in place of `/tmp/`.
- `uname -srm`: Linux 6.18.57 x86_64.
- `command -v swift`; `swift --version`: supplied executable; Swift 6.2.1 (`swift-6.2.1-RELEASE`), target `x86_64-unknown-linux-gnu`.
- `command -v xcodebuild || true`; `command -v xcrun || true`: neither on PATH.
- `git rev-parse HEAD`; `git status --short`; `git branch --show-current`: SHA above; clean; detached.

Read required documents, Package.swift and relevant scripts/CI. Initial `rg --files` returned 2: sparse `docs/parallel/03` absent; read protocol from integration checkout. Executable startup verified; compilation untested here.

## Serialized map — all proposed commands UNRUN by W09

Use one heavy slot. Reuse root's Debug366/Release366 and twelve images only with unchanged-source justification. Canonical command blocks: `.github/workflows/ios-prototype.yml`.

| Check | Commands / CI lines | Scope/settings |
|---|---|---|
| Core | `swift test --jobs 2`; `swift test --configuration release --jobs 2` | LightingCore only; no App/UIKit. |
| Images | Lines 69–71 | Twelve scenes: sphere 120, bust 144 pixels. |
| Host parity | Lines 97–108 | Six Float32 fixtures: width 96; eight precision fixtures: width 192, `--maximum-channel-error 1`. Not Metal execution. |
| Benchmark | Below | One built-in warm-up; ≥7 measured samples; eight frames at widths 72/144, twelve cancellations, four visibility workloads. |
| Native | Lines 173–208, 267–294; UI 463–465, 542–545 | Xcode/Apple SDK/Metal compiler; iPhone 17 Pro/iOS 26.5 simulator. Preview/UIKit and three required StudyRendererTests Metal methods need actual successful execution, no skips, finalized accounting. |

```bash
B=/tmp/keyfill03-7f4b/builds/W09-platform-performance
swiftc -O Sources/LightingCore/*.swift scripts/benchmark-study.swift -o "$B/benchmark-study"
"$B/benchmark-study" --samples 7 --revision f150f98e35dd735927075aac4d2f8b02295c6a67 > "$B/study-benchmark.json"
```

Create B before execution. Preserve mannequin width ≤144, bounded 8×8 area sampling, cancellation/cache limits and tolerances. Host p50/p95 imply no device performance or photographic fidelity. Native evidence remains unverified. No private executable artifacts created.
