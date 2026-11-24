# Independent rendering precision and cancellation review

## Outcome and exact scope

Wave 9 specialist `w09_rendering_critical_review` independently reviewed the pending rendering packet against `docs/QUALITY.md`, the architecture's declared diagnostic model, and the implementations of camera framing, finite sources, CPU reference rendering, packed compute input, GPU routing and cancellation. The review was based on main `0fce248b4e61bace88002b40f6c56fddedb19c8a` plus the source hashes below.

**No new demonstrated P0/P1 defect was found in this packet.** The lower-bound routing geometry is conservative in exact arithmetic, the shared Float32 sphere correction addresses the reproduced far-camera cancellation error, and the cancellation counter bounds pixel work without changing sampling. These findings support integrating the packet for subsequent native verification. They do not pass the rendering, performance, regression or native-build release gates.

This reviewer executed an additional finite panel-domain audit. Existing 6/6 portable eligibility tests, the 33-fixture Float32 host report, strict eight-fixture correction, and cancellation measurements were inspected as evidence produced by the implementing specialists; they were not relabeled as independently rerun GPU tests. No Apple SDK, Metal device, physical camera or photographer review was available to this reviewer.

## Independent checks

| Area | Finding |
| --- | --- |
| Sphere intersection | The closest-approach formulation retains the direction-length term and the caller's near/far minimum semantics. It avoids the old subtraction of approximately 400-sized squared terms to recover a radius-squared quantity at most 0.0484. All production callers supply finite, nonzero normalized directions. The Double oracle is unchanged. |
| Point-source separation | `abs(length(source) - radius)` is the exact minimum distance from a point to a complete sphere surface, including a source inside the sphere. A distance above cutoff plus margin therefore certifies clearance in exact arithmetic. |
| Rectangle separation | Subtracting the sphere radius from the face point nearest its center, with a zero lower bound, cannot overestimate sphere/face separation. A rectangle's AABB encloses the complete emitting face. This may reject safe cases but does not omit a closer edge or corner. |
| Visible panel | The finite square is clipped against four side planes and the near plane. Each plane is expanded by the margin times its normal length. The enclosing box consequently contains the clipped receiver polygon. Distance between enclosing boxes is a lower bound on separation of the enclosed shapes. Direct projection checks below independently challenge this part. |
| Active sources | Positive-candela filtering matches sample and area-guard construction. Disabled sources still obey the existing relative-distance domain; they do not need a valid aimed emission frame because no samples are produced. |
| GPU validation | Production `render` enforces eligibility and complete `StudyComputeInput` validation before private compute. Startup validation uses the explicitly internal raw-fixture path, retaining the original relative 20 m limit and complete input validation. All six fixtures still exercise the GPU, including its invalid-mask fixture. |
| Per-scene fallback | The engine leaves a validated Metal backend intact when eligibility returns false. The new native normal → CPU → normal regression exercises this state sequence and checks the CPU image exactly. This is implemented, not executed native evidence. |
| Cancellation | The shared counter checks before pixel work, including background/unsupported pixels. There are at most eight pixel evaluations between calls to the cancellation callback. An external request immediately after a false callback can permit eight evaluations; the explicit regression covers that boundary. Final cancellation prevents publication of a completed stale image. |

## Independently executed panel-domain audit

The probe linked the actual already-built Release `LightingCore` static library on Debian 13 x86_64 with Swift 6.4.3. It did not acquire the shared SwiftPM build lane. It directly projected known panel points through `CameraFraming.project`, which uses the sensor equations rather than the eligibility helper's polygon clipping or AABB distance implementation.

Camera coverage comprises four yaws (0°, 37°, 90°, 179°), four horizontal distances (0.1, 1, 4, 19 m), five elevations relative to the subject (−0.209999, 0, 0.2, 2, 5 m), and four focal lengths (14, 35, 85, 200 mm), retaining configurations inside the valid study camera distance domain. The lowest camera is 1.0001 cm above the panel. Each camera projects a 25 × 25 grid over the actual 6 × 6 m panel.

For each projected point inside the view and near plane, the probe creates four valid single-source scenes: a point source 5.0999 cm above the panel, one the same distance below it, a point 4.9999 cm above, and a 0.6 × 0.6 m horizontal rectangle 15.0999 cm above. Those distances are inside the respective cutoff-plus-1-mm margin. Every generated scene is separately validated before its eligibility call. These cases must route to CPU even if the sphere occludes the panel point; the helper intentionally includes occluded panel regions in its conservative enclosure.

```json
{
  "cameraConfigurations" : 272,
  "examples" : [

  ],
  "nearFieldSceneChecks" : 345824,
  "visiblePanelPoints" : 86456,
  "wronglyEligible" : 0
}
```

**Result: 345,824 scene eligibility checks across 272 camera configurations, zero incorrect eligibility decisions.** This is finite geometry coverage, not 345,824 XCTest methods and not a measured GPU error bound. It does not test arbitrary emitter roll, every source dimension, or every point in a continuous scene space. Tilted and offset finite faces were separately inspected in the existing portable tests.

## Corrections and remaining limits

1. **P3 stale source comment, reported to root:** the comment above `StudyRenderEngine` still says CPU scans stop at each row. The implementation now polls by pixel count. Replace it with wording that states at most eight pixel evaluations between checks. No behavior change is needed.
2. **The 1 mm margin is empirical engineering policy.** Exact-arithmetic enclosure is not a proof that every native GPU's camera reconstruction or arithmetic stays within that margin. Device execution and further held-out numerical cases remain necessary. Neither the source nor review should claim universal Float32 parity.
3. **The complete raw boundary corpus remains 28/33 passing after the kernel correction.** Five exact cutoff-mask mismatches are retained; all measured ambiguous cases route to CPU. The strict eight far-camera/translation controls pass with a maximum allowed channel error of one, actually zero in the reported run. These are distinct statements. The guard is not a reason to remove the raw kernel regressions.
4. **Fallback cost remains unmeasured on devices.** The deliberate stress corpus routes 22/33 cases to CPU, including eight area controls that the corrected raw kernel can render accurately at the sampled resolution. This corpus is not a representative frequency estimate. Conservative fallback trades performance for avoiding a known unsupported-mask disagreement; normal startup scenes and the portrait scene remain eligible under the portable tests.
5. **Cancellation is a work bound, not a wall-clock SLA.** Setup before the first pixel, the cost of eight expensive pixels, submitted GPU commands and host scheduling can exceed a chosen delay. The retained measured full-render callback gaps of about 29.5 ms and 25.8 ms must remain visible. The reported faster cancellation probes do not establish the physical-device 20 ms p95/60 fps contract.
6. **Native readiness remains open.** Syntax parsing and shared C++ kernel execution cannot establish Metal shader compilation, actual GPU arithmetic, SwiftUI lifecycle behavior, device thermal performance or calibrated realism. No quality threshold or completion criterion was changed by this review.

The current `agent_cycle.py check` validates state structure and evidence references; `next` still selects M01 with `native_build` and `persistence_smoke` outstanding. This review does not promote either gate.

## Reproduction of the independent audit

Save the following probe outside the repository, build LightingCore in Release, and link it against that build. The exact invocation used with this environment's Swift 6 build layout was:

```sh
swiftc -O -I .build/out/Intermediates.noindex/LightingCore.build/Release-linux-x86_64/LightingCore-t.build/Objects-normal/x86_64/Modules panel-domain-audit.swift .build/out/Products/Release-linux-x86_64/libLightingCore.a -o panel-domain-audit
./panel-domain-audit > panel-domain-audit.json
```

```swift
import Foundation
import LightingCore

var cameras = 0, visiblePanelPoints = 0, tested = 0, wronglyEligible = 0
var examples: [[String: Any]] = []
let subject = Position(x: 0, y: 1.5, z: 0)
for yaw in [0.0, 37.0, 90.0, 179.0] {
    let angle = yaw * .pi / 180
    for horizontal in [0.1, 1.0, 4.0, 19.0] {
        for elevation in [-0.209999, 0.0, 0.2, 2.0, 5.0] {
            let distance = hypot(horizontal, elevation)
            guard distance > 0.27, distance <= 20 else { continue }
            let camera = Position(x: sin(angle) * horizontal, y: subject.y + elevation,
                                  z: cos(angle) * horizontal)
            for focal in [14.0, 35.0, 85.0, 200.0] {
                var scene = LightingScene(subject: subject, camera: camera, lights: [],
                                          cameraLens: .init(focalLengthMillimeters: focal))
                guard let framing = CameraFraming(scene: scene) else { fatalError("Expected camera") }
                cameras += 1
                // Direct sensor projection is independent of the helper's
                // polygon clipping and AABB source/receiver separation.
                for xi in -12...12 { for zi in -12...12 {
                    let receiver = Position(x: Double(xi) / 4, y: subject.y - 0.22,
                                            z: Double(zi) / 4)
                    guard let projection = framing.project(receiver), projection.isInsideFrame else { continue }
                    visiblePanelPoints += 1
                    for (kind, height) in [("point-above", 0.050999), ("point-below", -0.050999),
                                           ("point-inside", 0.049999), ("rectangle", 0.150999)] {
                        let position = Position(x: receiver.x, y: receiver.y + height, z: receiver.z)
                        let optics: LightOptics? = kind == "rectangle"
                            ? .init(kind: .rectangle, aimTarget: receiver, widthMeters: 0.6, heightMeters: 0.6) : nil
                        scene.lights = [.init(name: "Held-out panel receiver", position: position,
                                              candela: 100, kelvin: 5600, optics: optics)]
                        precondition((try? scene.validated()) != nil, "Probe generated an invalid scene")
                        tested += 1
                        if StudyFloat32Eligibility.supports(scene) {
                            wronglyEligible += 1
                            if examples.count < 10 {
                                examples.append(["yaw": yaw, "horizontal": horizontal, "elevation": elevation,
                                                 "focal": focal, "x": receiver.x, "z": receiver.z, "kind": kind])
                            }
                        }
                    }
                } }
            }
        }
    }
}
let summary: [String: Any] = ["cameraConfigurations": cameras, "visiblePanelPoints": visiblePanelPoints,
                             "nearFieldSceneChecks": tested, "wronglyEligible": wronglyEligible,
                             "examples": examples]
let output = try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(output)
print("")
if wronglyEligible != 0 { exit(1) }
```

## Source and evidence hashes

| File | SHA-256 |
| --- | --- |
| `Sources/LightingCore/StudyFloat32Eligibility.swift` | `2b5c3de52bb8c2b5667607e3d3eb38f5b580dcfc844f918bbb7291871f207c28` |
| `App/StudyKernel.h` | `ec67e54f98698741c15fddf543967bdeb1596aa183b488e7414cde4b397e33f7` |
| `App/MetalStudyRenderer.swift` | `a43387b69f2cd87ad57418abf21de018150e4a82d725c7b85bae5992c0fb330b` |
| `Sources/LightingCore/PortraitStudy.swift` | `74c4a484b6aee550808110db98b81f4ef725b62fc0b38a542dc35170f5dc54f6` |
| `Sources/LightingCore/ReferenceStudy.swift` | `da3f54a8dab3683b7f9cbbdadd924739a332fb6d4405e6c78c12dc0d512a42b9` |
| `.build/out/Products/Release-linux-x86_64/libLightingCore.a` | `ef7534809e921f2973eced89bfb535ed1fe9224071be60d8fcf8b51d183f64c5` |
| `panel-domain-audit.swift` | `6b11d8ee063598d4f240229dcfc2ba2b18f62ae85137719f895f0fba2d682a4f` |
| `panel-domain-audit.json` | `42efa0616178084a096c7506115108c3399e6941fa943b8cd5fe3bd1f05ac097` |

Raw standalone probe, executable and JSON are under `/workspace/scratch/73dcd6a65726/verification/w09-rendering-review/`; complete source and output are embedded above so the audit is reproducible after scratch expiry. Production code was not edited by this reviewer.
