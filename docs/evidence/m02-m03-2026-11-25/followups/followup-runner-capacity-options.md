# Standard macOS runner capacity options — read-only review

Checked official sources on 2026-11-25 against repository `18f387aa0db3ac06d21dfe241eb6dcbbc19f9b4c`. No workflow edits, builds, reruns, privileges, or purchases were performed.

**`macos-26-intel` is a documented standard runner with the required Xcode 26.6/iOS 26.5 software.** It is the relevant alternative architecture to evaluate with a100's compatibility review. There is no documented separate standard ARM64 pool preserving this image: `macos-latest` maps to the same macOS 26 ARM image. Relabeling to that alias is not an evidenced capacity remedy. [1–4]

| Label | Official architecture/software | Assessment |
|---|---|---|
| `macos-26` | Standard ARM64, 3 M1 CPUs, 7 GB RAM; required software present | Current affected selection; retaining it preserves the current architecture. |
| `macos-latest` | Same macOS 26 ARM image | No documented independent capacity pool; alias can migrate later. |
| `macos-26-intel` | Standard x64, 4 CPUs, 14 GB RAM; required software present | Candidate for a separate architecture, subject to complete native/UI compatibility and actual runner acquisition. |
| `macos-15` | ARM64; installed Xcode stops at 26.3, default 16.4 | Does not preserve Xcode 26.6/iOS 26.5 requirements. [5] |
| `xcode-27` | ARM64 on macOS 27; Xcode 27.x and iOS 27.x | Does not preserve the required OS/toolchain/runtime. [6] |
| `macos-26-large` / `macos-26-xlarge` | Larger Intel / ARM runners | Outside the authorized standard-runner scope; separate billing/setup requirements. [7] |

## Required software is listed for both macOS 26 architectures

The Intel and ARM image manifests both list **Xcode 26.6, build 17F113**, default at `/Applications/Xcode_26.6.app`; `iphoneos26.5` and `iphonesimulator26.5` SDKs; and the installed **iOS 26.5 simulator runtime**, including iPhone 17, 17 Pro, 17 Pro Max, 17e, and Air. [3–4]

The opened manifests have different host/image revisions: Intel `20260824.0517.1`, macOS 26.6.1 (25G76); ARM `20261117.0516.1`, macOS 26.7.2 (25G332). An older search snippet showed an earlier ARM image; the report uses the opened page. Image versions are not interchangeable evidence. [3–4]

## Conditions and limitations

The current workflow explicitly asserts `uname -m = arm64` in both native and UI jobs. A label-only Intel change would fail those guards. Any deliberate architecture change must preserve every test/shard, assertion, deadline, Metal gate, and artifact requirement; a100 owns the code compatibility determination. Toolchain presence does not prove RealityKit/Metal behavior.

To preserve exact toolchain/runtime requirements, verify the actual Xcode build and selected iOS runtime on the acquired runner; `DEVELOPER_DIR=/Applications/Xcode_26.6.app/Contents/Developer` can select the listed Xcode without changing system privileges. The existing workflow records active tool versions but does not pin those exact minor versions. GitHub identifies the job's actual image in its setup log and updates images over time. [2]

GitHub explicitly warns that high macOS demand can delay acquisition. No official source consulted guarantees immediate Intel capacity or a separate standard ARM pool. Standard runners are free for public repositories; private repositories retain their ordinary included-minute/billing rules. No claim is made that a different label will resolve the supplied runner-acquisition failure. [1]

## Official sources

1. [GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
2. [Runner-images labels, image policy, and actual-image verification](https://github.com/actions/runner-images)
3. [macOS 26 Intel image software manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md)
4. [macOS 26 ARM64 image software manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md)
5. [macOS 15 ARM64 image software manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
6. [Xcode 27 ARM64 image software manifest](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)
7. [Larger-runner labels and billing/setup constraints](https://docs.github.com/en/actions/reference/runners/larger-runners)
