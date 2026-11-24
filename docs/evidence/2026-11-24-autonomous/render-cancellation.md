# CPU render cancellation responsiveness — measured correction

## Scope and source

The first experiment began at main `0fce248b4e61bace88002b40f6c56fddedb19c8a`, with other unrelated working-tree work in progress. The two renderer source files were copied before editing. Changes are limited to a shared internal cancellation checkpoint and its use before each pixel in the sphere and mannequin loops. Photometry, sample counts, BRDF, geometry, color conversion, output allocation and unsupported-pixel handling are unchanged.

Baseline renderer SHA-256:

- `PortraitStudy.swift`: `daef90e14efbf5085fae910d1e9ce246519f83ec9715447332e4db195be58568`.
- `ReferenceStudy.swift`: `c6f313b5371cb004bfca47bb5d3e736d0eae279ef2ef56f43c70e6c9e8eb28f7`.

Source hashes from the original runs are listed below. A documentation comment was relocated after the optimized timing run; the executable statements were unchanged. That source then passed the targeted Debug and Release suites. A subsequent review clarified the test wording and added one deterministic regression; its separate result and updated test-file hash are also recorded below.

## Concrete defect and change

A whole scanline is not a useful cancellation work bound when each pixel evaluates many area-light samples and shadow rays. In a legal close-up scene, the old loop allowed a cancellation deadline to be exceeded by **51.111 ms** for the mannequin and **45.068 ms** for the high-sample sphere reference renderer in the recorded probes.

`StudyPixelCancellation` now checks the supplied cancellation callback before the first pixel, with **at most eight pixel evaluations between polls**. A request arriving immediately after a callback returns false can therefore permit all eight evaluations before the next poll observes it. Both CPU renderers use the checkpoint, including for background and diagnostic pixels. Existing final cancellation checks still prevent a completed frame from being published after cancellation. Public API and callback semantics are unchanged; the native engine continues to supply actual `Task.isCancelled`.

This is a cooperative **work bound**, not a hard real-time guarantee. One pixel, setup/lazy geometry initialization, operating-system scheduling and caller/UI task delivery remain outside a wall-time guarantee.

## Measurement method

Environment: shared Debian 13 x86_64, AMD EPYC 9V74, Swift 6.4.3 with `swiftc -O`; not an iPhone or GPU. Monotonic `DispatchTime` measures synchronous renderer callbacks, not asynchronous task scheduling.

Fixture: portrait subject `(0,1.5,0)`, camera `(0,1.5,0.45)`, full-frame 85 mm lens. Twelve distinct light IDs repeat the three portrait lights four times with quarter intensity; each source is a 0.8 × 1.0 m rectangle. The close-up covers much of the image with illuminated geometry. This is a demanding declared fixture, not proof of the global worst case over all valid scenes.

Three supported modes use their maximum legal width: mannequin interactive 144 × 96; sphere interactive 192 × 128; sphere reference 96 × 64. Interactive quality uses 8 × 8 source samples per rectangle; reference quality uses 32 × 32.

For each mode and implementation, one full render captures raw RGBA, total time and callback intervals. That first full render can include lazy setup. It is followed by three cancellation repetitions at each requested deadline of 2, 15 and 50 ms, in that order. The deadline becomes observable through the real callback; cancellation probes therefore run after the complete render has warmed the code/geometry. No sample is excluded. All **54 cancellation probes** returned `StudyError.cancelled`.

### Maximum requested-deadline-to-return delay, ms

| Mode | Before | After | Callback count in complete render |
| --- | ---: | ---: | ---: |
| bust-interactive144 | 51.111 | 1.713 | 98 → 1730 |
| sphere-interactive192 | 5.186 | 0.234 | 129 → 3073 |
| sphere-reference96 | 45.068 | 3.466 | 65 → 769 |

The full-render maximum callback intervals were 44.467 → 29.471 ms for the mannequin, 6.520 → 1.957 ms for the interactive sphere, and 109.688 → 25.790 ms for the reference sphere. These larger full-render gaps show why the warm cancellation-probe maxima must not be represented as universal latency limits. They include setup or scheduling effects as well as pixel work; the experiment does not identify the cause of each individual gap.

Full-frame durations are retained in the raw data but no render-throughput speedup is claimed. This correction targets responsiveness to cancellation, not cheaper lighting or fewer samples.

## Correctness verification

- **3/3 complete raw RGBA comparisons were byte-identical** before and after, with zero unsupported pixels in every image.
- **19/19 targeted Debug and 19/19 targeted Release tests passed in the original run**: three new cancellation tests, seven existing portrait tests and nine existing reference renderer tests. The additional review regression is recorded separately below.
- The original deterministic checkpoint test raises cancellation only at completed-pixel boundaries, at all sixteen positions across two eight-pixel intervals. That trigger allows fewer than eight additional evaluations. It does not cover a request arriving after a false poll and before its guarded pixel executes; the general bound is at most eight.
- Renderer integration tests cover widths 24 and 27, both sphere quality modes and the mannequin, minimum polling density, exact image equality when callbacks do not cancel, and immediate unwinding after a cancelling callback.
- A final-checkpoint test verifies that cancellation suppresses publication even after all pixels are complete.
- `git diff --check` passed. No native SDK, GPU, physical-device, thermal, battery, FPS or release-gate pass is claimed.

- `bust-interactive144.rgba`: `ca21e86c7a57ac98ca204b8723f77a0784cd83f3a1c5178b02decd6ab238c0a6`; complete bytes equal before/after, unsupported pixels 0/0.
- `sphere-interactive192.rgba`: `2a69aaee0b05392eae0f2ffb5a700fe7723a53f3ec3635dd3d5393d68342e2a6`; complete bytes equal before/after, unsupported pixels 0/0.
- `sphere-reference96.rgba`: `95d48c8cb4b387caa24785dfa5f5c33932086ad3434793ddad62f5a15237c853`; complete bytes equal before/after, unsupported pixels 0/0.

## Follow-up review: the poll-boundary case

The review found a precision issue in the description, not a defect in the production counter. The original test requests cancellation at completed-pixel boundaries and correctly observes fewer than eight further evaluations. An external request can instead arrive immediately after a false poll, before its guarded pixel executes; that first pixel plus seven subsequent pixels can then run before the next callback.

`testCancellationImmediatelyAfterFalsePollStopsAfterEightPixelEvaluations` models that sequence without threads or timing assumptions. It lets one callback return false, sets the request before evaluating that pixel, and counts work until the next callback throws. The observed total is exactly eight pixel evaluations and two callback invocations. The original test's name, comments and assertion message now describe its narrower completed-pixel trigger explicitly.

Only `swift test --jobs 2 --filter StudyCancellationTests` was run for this follow-up: **4/4 Debug tests passed**, zero failures, 0.140 seconds of XCTest execution (6.00 seconds to build). This is additional evidence, separate from the original 19/19 Debug and Release runs. The new test has not received a separate Release run in this review. No production source, benchmark samples or timing measurements changed.

- Updated `Tests/LightingCoreTests/StudyCancellationTests.swift` SHA-256: `9814bc07ca04ecd34d4046dc59a87990305f71a581dca48375aa6c8fcc5c4806`.
- Follow-up `review-tests-debug.log` SHA-256: `82277329fffe8109d634e71c79570c77352a17f646e95d4b848f967a86f42663`.
- Log location at review: `/workspace/scratch/73dcd6a65726/verification/w08-cancellation/review-tests-debug.log`.

## Commands

Build a before binary against the copied pre-change core sources, and an after binary against the updated core sources. Save the probe below as `probe.swift` in a temporary working directory.

```bash
swiftc -O baseline-sources/*.swift probe.swift -o baseline-probe
./baseline-probe baseline > baseline.json
swiftc -O Sources/LightingCore/*.swift probe.swift -o after-probe
./after-probe after > after.json
swift test --jobs 2 --filter 'StudyCancellationTests|PortraitStudyTests|ReferenceStudyTests'
swift test -c release --jobs 2 --filter 'StudyCancellationTests|PortraitStudyTests|ReferenceStudyTests'
```

Local raw logs used the host clock (approximately eight hours behind connector UTC), preserved unchanged. Test execution time was 4.394 s Debug and 0.306 s Release; compilation is excluded from those XCTest totals.

## Source and evidence hashes from the original runs

- `Sources/LightingCore/PortraitStudy.swift`: `74c4a484b6aee550808110db98b81f4ef725b62fc0b38a542dc35170f5dc54f6`.
- `Sources/LightingCore/ReferenceStudy.swift`: `da3f54a8dab3683b7f9cbbdadd924739a332fb6d4405e6c78c12dc0d512a42b9`.
- `Tests/LightingCoreTests/StudyCancellationTests.swift`: `720dc1d50ac70aaa334c7d51dd60a3c5d44988813e4dd2c029b233e21884eca9`.
- `baseline.json`: `fc06f2c3f9f665ba0e675d554e4c7370892a5ec936a84fb20bc2ced660e2fbac`.
- `after.json`: `fc6e25cf7fc42306e13ef89a156e16706420c3b4749fa4aacaad0c7aab03a85c`.
- `tests-debug.log`: `0b3f16e3d8a22be0e3634ca01cc392aa36bd6ee17d2e90044283d956d0141cc4`.
- `tests-release.log`: `e8a28c27ffe4e73784d7bdd6a8ee0d1fa65cdb454fcb45902ccbfe27425bb2f0`.

## Raw before results

```json
[
  {
    "delaysMS": [
      28.606323,
      31.697029999999998,
      51.110796,
      27.367123,
      13.238653,
      13.650905000000002,
      6.195458000000002,
      5.852029000000002,
      6.117924000000002
    ],
    "fullRenderMS": 2491.658761,
    "largestFullRenderPollGapMS": 44.46730199999999,
    "name": "bust-interactive144",
    "observedGapsMS": [
      30.062667,
      33.422994,
      51.20507,
      39.439633,
      28.066478,
      28.477197,
      28.237501999999996,
      27.378528,
      27.875765
    ],
    "polls": 98,
    "unsupported": 0
  },
  {
    "delaysMS": [
      3.941108,
      3.702364,
      5.185742,
      2.8649650000000015,
      1.510466000000001,
      2.9002359999999996,
      1.9294340000000005,
      2.8012060000000005,
      1.2749340000000018
    ],
    "fullRenderMS": 722.462493,
    "largestFullRenderPollGapMS": 6.519845999999994,
    "name": "sphere-interactive192",
    "observedGapsMS": [
      5.731668,
      5.593953,
      7.079636,
      5.567705,
      5.471561000000001,
      5.630155999999998,
      6.154783999999999,
      6.192940999999998,
      5.9681580000000025
    ],
    "polls": 129,
    "unsupported": 0
  },
  {
    "delaysMS": [
      0.31015499999999996,
      44.777478,
      45.067698,
      40.646966,
      40.880122,
      42.015646,
      2.922106999999997,
      44.763056000000006,
      43.208209999999994
    ],
    "fullRenderMS": 3046.178878,
    "largestFullRenderPollGapMS": 109.68822199999977,
    "name": "sphere-reference96",
    "observedGapsMS": [
      2.307731,
      46.595887999999995,
      46.751879,
      55.208225999999996,
      55.470334,
      56.545128,
      52.500822,
      45.805316000000005,
      46.481747999999996
    ],
    "polls": 65,
    "unsupported": 0
  }
]
```

## Raw after results

```json
[
  {
    "delaysMS": [
      0.10951600000000017,
      1.7127219999999999,
      1.6987100000000002,
      0.5830280000000005,
      1.159903,
      0.7290849999999995,
      0.9436200000000028,
      0.2544290000000018,
      0.27882999999999925
    ],
    "fullRenderMS": 2384.044605,
    "largestFullRenderPollGapMS": 29.470755,
    "name": "bust-interactive144",
    "observedGapsMS": [
      1.116344,
      1.748661,
      1.74197,
      2.1178679999999996,
      2.109606000000001,
      2.137027,
      1.823863000000003,
      1.9040509999999955,
      2.0574980000000025
    ],
    "polls": 1730,
    "unsupported": 0
  },
  {
    "delaysMS": [
      0.233819,
      0.18443699999999996,
      0.14300500000000005,
      0.17663600000000024,
      0.22485700000000008,
      0.0825370000000003,
      0.0812919999999977,
      0.016294999999999504,
      0.21388900000000177
    ],
    "fullRenderMS": 749.252379,
    "largestFullRenderPollGapMS": 1.9573000000000036,
    "name": "sphere-interactive192",
    "observedGapsMS": [
      0.23756200000000027,
      0.24083699999999975,
      0.225093,
      0.2251840000000005,
      0.22515399999999985,
      0.2400859999999998,
      0.22485300000000308,
      0.24144700000000086,
      0.23582999999999998
    ],
    "polls": 3073,
    "unsupported": 0
  },
  {
    "delaysMS": [
      2.204802,
      1.8799109999999999,
      1.8598409999999999,
      0.35717200000000027,
      0.8937069999999991,
      0.34066699999999983,
      3.379407999999998,
      2.8160230000000013,
      3.465516000000001
    ],
    "fullRenderMS": 2982.014576,
    "largestFullRenderPollGapMS": 25.78957899999989,
    "name": "sphere-reference96",
    "observedGapsMS": [
      3.746352,
      3.701957,
      3.689899,
      3.7783099999999994,
      3.7551360000000003,
      3.832229999999999,
      3.8282039999999995,
      3.6983609999999985,
      4.0275199999999955
    ],
    "polls": 769,
    "unsupported": 0
  }
]
```

## Reproduction probe

```swift
import Dispatch
import Foundation

@main struct CancellationProbe {
    struct ResultRow: Codable {
        let name: String
        let fullRenderMS: Double
        let largestFullRenderPollGapMS: Double
        let polls: Int
        let unsupported: Int
        let delaysMS: [Double]
        let observedGapsMS: [Double]
    }
    static func now() -> UInt64 { DispatchTime.now().uptimeNanoseconds }
    static func ms(_ start: UInt64) -> Double { Double(now() - start) / 1e6 }
    static func fixture() -> LightingScene {
        var scene = LightingScene.portrait()
        scene.camera = .init(x: 0, y: 1.5, z: 0.45)
        scene.cameraLens = .init(focalLengthMillimeters: 85)
        let original = scene.lights
        scene.lights = (0..<12).map { i in
            var light = original[i % 3]
            light.id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", i + 1))!
            light.name = "Area \(i + 1)"
            light.candela /= 4
            light.optics = .init(kind: .rectangle, widthMeters: 0.8, heightMeters: 1.0)
            return light
        }
        return scene
    }
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let scene = try fixture().validated()
        let modes: [(String, (()->Bool) throws -> StudyImage)] = [
            ("bust-interactive144", { try PortraitStudyRenderer.render(scene: scene, width: 144, isCancelled: $0) }),
            ("sphere-interactive192", { try ReferenceStudyRenderer.render(scene: scene, width: 192, isCancelled: $0) }),
            ("sphere-reference96", { try ReferenceStudyRenderer.render(scene: scene, width: 96, quality: .reference, isCancelled: $0) })
        ]
        // Construct the geometry value; lazy mesh initialization may occur in the first full render.
        _ = PortraitGeometry(center: scene.subject)
        var results: [ResultRow] = []
        for (name, render) in modes {
            let start = now()
            var previous = 0.0, largest = 0.0, polls = 0
            let image = try render {
                let time = ms(start)
                largest = max(largest, time - previous)
                previous = time
                polls += 1
                return false
            }
            let elapsed = ms(start)
            try image.rgba.write(to: output.appendingPathComponent(name + ".rgba"))
            var delays: [Double] = [], gaps: [Double] = []
            for target in [2.0, 15.0, 50.0] {
                for _ in 0..<3 {
                    let start = now()
                    var last = 0.0, straddling = 0.0, didCancel = false
                    do {
                        _ = try render {
                            let time = ms(start)
                            if time >= target { straddling = time - last; return true }
                            last = time
                            return false
                        }
                    } catch StudyError.cancelled { didCancel = true }
                    guard didCancel else { fatalError("Expected cancellation: \(name)") }
                    delays.append(ms(start) - target)
                    gaps.append(straddling)
                }
            }
            results.append(.init(name: name, fullRenderMS: elapsed, largestFullRenderPollGapMS: largest,
                                 polls: polls, unsupported: image.unsupportedPixels,
                                 delaysMS: delays, observedGapsMS: gaps))
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        FileHandle.standardOutput.write(try encoder.encode(results))
        print("")
    }
}
```
