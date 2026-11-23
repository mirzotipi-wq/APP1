# Direct-light Study and compute parity — 2026-11-23

Revision: d6407acc324bedfc5abe946565e6b4f60cd2a3ba. Parent development cycle starts at c0a735a5075fcfaebfd866a5b6de02fd8cb07e06.

## Verified
- GitHub Ubuntu 24.04 x86_64, Swift 6.4.2 RELEASE: 58 debug and 58 release XCTest cases passed with zero failures (0.096 s / 0.131 s reported XCTest suite time). Swift frontend syntax parse of App, NativeTests and UITests passed; no Apple SDK type check.
- CPU direct-light reference renderer: analytic sphere and finite-panel intersections, cosine/inverse-square, uniform rectangular Lambertian emission, per-sample visibility, dielectric GGX/Smith/Schlick, relative XYZ/display transform. Area 8×8 versus 32×32 midpoint integration: nine unoccluded fixtures max relative error 0.0032798081798638967. Partial shadow fixture visible fraction 0.742030795936865. Analytic/independent area photometry max relative error 0.0006782719414129317.
- Reproducible 120×80 soft/hard/warm PPMs and corresponding scene JSONs generated in CI, each zero unsupported pixels.
- Six 96×64 C++ host executions of shared Float32 kernel against the Swift Double CPU output. Threshold mean channel error <=1 (8-bit units), fraction of channels with absolute error >4 <=0.005, invalid count exact. Observed:

| Fixture | Mean absolute channel error | Maximum channel error | Fraction >4 | Invalid count |
|---|---:|---:|---:|---:|
| Dark | 0 | 0 | 0 | 0/0 |
| Hard | 0.0000542535 | 1 | 0 | 0/0 |
| Near-field | 0.000651042 | 1 | 0 | 84/84 |
| Soft | 0.000217014 | 1 | 0 | 0/0 |
| Translated | 0.000217014 | 1 | 0 | 0/0 |
| Warm rotated | 0.0000542535 | 1 | 0 | 0/0 |

[Core job](https://github.com/mirzotipi-wq/APP1/actions/runs/45262428316/job/138000434002) · [Log and render fixture artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45262428316/artifacts/14860961995) · [Workflow](https://github.com/mirzotipi-wq/APP1/actions/runs/45262428316).

Local Linux Swift 6.2.1 Release diagnostic 120×80 rendering, three lights, five warm samples each: median 35.7963 ms for rectangular emitters, 1.38594 ms for point emitters, 35.2798 ms for warm rect scene. These are not iPhone performance evidence; no p95, memory or thermal gate verified.

## Native limitations
Metal source compiled only as shared host math, not by the Apple Metal compiler. SwiftUI/Metal adapter and native XCTest are authored; actual Metal parity, native SDK compile, app launch and UI smoke await macOS. Simulator job 138000433437 queued; standard macOS 26 Intel runner is an alternate to earlier ARM queue cancellations. GitHub's standard public runner documentation: https://docs.github.com/en/actions/reference/runners/github-hosted-runners ; Apple Metal command encoder: https://developer.apple.com/documentation/Metal/MTLComputeCommandEncoder ; shared storage: https://developer.apple.com/documentation/metal/mtlresourceoptions/storagemodeshared ; Xcode fast math setting: https://developer.apple.com/documentation/Xcode/build-settings-reference .

Study uses neutral geometric test subjects, ideal Planckian spectra, no indirect illumination, measured fixture profile, skin or fabric, actual camera sensitivity, distortion, DOF or photographic calibration. Real device performance, rights-cleared controlled comparison scenes and independent photographer review remain mandatory. Rendering/performance gates unverified.
