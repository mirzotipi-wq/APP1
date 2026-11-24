# Conservative Float32 near-field routing

## Decision and limits

The independent [Float32 boundary audit](float32-boundary.md) found that the shared host-executed kernel can disagree with the Double renderer's unsupported-pixel mask when a source lies within micrometers of the 5 cm cutoff. The kernel's stable sphere correction fixes a separate far-camera intersection error; it cannot recover input precision lost while packing source geometry into Float32.

`StudyFloat32Eligibility` now routes potentially ambiguous near-field geometry to the Double CPU renderer. This is a portable geometry check, without a per-pixel render or an additional light-sampling pass. The existing 20 m domain remains **camera and source distance relative to the subject**, including scenes translated to large valid world coordinates. Neither rendering cutoffs nor parity thresholds changed.

The 1 mm padding is a conservative **engineering margin**, larger than the measured cutoff drift. It is not a mathematically proved bound on every GPU's arithmetic error. The helper and source-level routing are verified here; Apple SDK compilation, execution on actual Metal hardware, and GPU performance remain unverified. This work does not establish universal Float32 parity or physical rendering accuracy.

## Geometry used by the guard

The helper uses the actual `StudyGeometry` sphere radius and finite panel dimensions, `CameraFraming` basis and near depth, the 36 × 24 mm sensor and current focal length, and `StudioPhotometry.frame` for directional and rectangular emitters. Only sources with positive candela contribute near-field guards, matching `StudyLighting` and the packed compute input. The original relative-distance rule still applies to every source center.

- For a point or directional source, the distance to the entire sphere surface must exceed 5 cm plus 1 mm. Its separation from the visible panel bound must exceed the same threshold.
- For a rectangular source, the closest point on its finite emitting face supplies a lower bound on sphere separation. The guard is the actual `max(0.05, longestSide / 4)` meters plus the margin, not a fixed 5 cm approximation.
- The finite panel is clipped against the camera's four side planes and actual near plane. Each plane receives a padding of `margin * length(normal)` so its padding is measured consistently in meters. The resulting polygon's enclosing axis-aligned box is a conservative receiver bound.
- Rectangle-versus-panel separation uses enclosing boxes for the actual oriented face and clipped panel. Box distance is a lower bound on true shape separation. This can select CPU for additional safe corner or rotated cases; it cannot certify clearance using a distance greater than the shapes' separation.

Using the camera-visible panel avoids penalizing ordinary close-up rigs for source proximity to a distant panel region outside the view. The whole sphere remains a conservative bound, including its invisible side. No source radiance, guard threshold, receiver position or stored scene is modified by eligibility.

## Production and validation API

The new portable API is `StudyFloat32Eligibility.supports(_:)`, with `maximumRelativeDistanceMeters` and `surfaceMarginMeters` documenting its constants. `MetalStudyRenderer.supports(_:)` delegates to it. Production `render(scene:width:)` checks eligibility and constructs a validated `StudyComputeInput` before its private compute method can submit work.

The explicitly internal `renderValidationFixture(scene:width:)` bypasses only near-field routing, retaining the original relative-distance limit and complete compute-input validation. Startup validation and the native parity test use this method for **all six real fixtures**, including the deliberately unsupported near-field fixture. This preserves the raw GPU invalid-mask check; no fixture is replaced by a CPU result during GPU validation.

The engine already treats unsupported scene geometry as a per-scene CPU choice. It does not downgrade a validated Metal backend merely because this eligibility test returns false. A new native regression requires normal Metal → guarded CPU → normal Metal on the same engine, with exact CPU fallback-image equality. This native test has been syntax-checked but has not run here.

## Portable results

Debian 13 x86_64, Swift 6.4.3, working changes based on `0fce248b4e61bace88002b40f6c56fddedb19c8a`:

| Check | Result |
| --- | --- |
| `swift test --jobs 2 --filter StudyFloat32EligibilityTests` | 6 tests passed, 0 failures; 0.003 s test time |
| `swift test -c release --jobs 2 --filter StudyFloat32EligibilityTests` | 6 tests passed, 0 failures; 0.103 s test time |
| `swiftc -frontend -parse` on the helper, portable tests, Metal renderer and native renderer tests | Passed; syntax only |
| `git diff --check` | Passed |
| Native GPU routing/parity test execution | Unavailable; not a pass |

The six portable tests cover all startup fixture eligibility, both exact measured cutoff failures, both sides of the cutoff, source disabling, no scene mutation, exact 20 m distances, positive and negative large translations, narrow/wide views, four camera yaws, the size-dependent area guard, a large offset emitter face, tilted area extent, and invalid active versus inactive emitter frames.

The complete 33-scene JSON fixtures from the independent boundary probe were also decoded and passed through the compiled helper:

| Fixture group | Eligible for Float32 | Routed to Double CPU |
| --- | ---: | ---: |
| Six ordinary startup fixtures, checked separately | 5 | 1 deliberate near-field fixture |
| Cutoff probes at 1 m and 20 m, seven offsets each | 0 | 14 |
| Far-camera area controls at 19, 19.999999 and 20 m | 0 | 6 |
| Positive/negative translations of the far area control | 0 | 2 |
| No-light silhouette-tangent controls | 9 | 0 |
| Point-source distance controls at 19.999999 and 20 m | 2 | 0 |
| **Held-out 33-scene total** | **11** | **22** |

All measured cutoff-mask failures are therefore excluded from production Float32 routing. The eight far area/translation controls are also excluded even though the corrected host kernel passes them: their broader visible panel contains near-field receiver regions, and the conservative continuous bound does not distinguish a harmless pixel layout from a nearby ambiguous one. The ordinary close-camera soft fixture and `LightingScene.portrait()` remain eligible. The raw host-kernel tests for those excluded fixtures remain useful and unchanged.

## Evidence locations and exact hashes

Scratch evidence is under `/workspace/scratch/73dcd6a65726/verification/`: `float32-eligibility-debug.log`, `float32-eligibility-release.log`, and `float32-eligibility-fixtures.json`. The standalone sweep source is `float32-eligibility-probe.swift`; it uses the boundary audit's complete scene JSON files and calls the compiled portable helper. The fixture generator is retained in the repository as `scripts/precision-boundary.swift`.

| Source or evidence | SHA-256 |
| --- | --- |
| `Sources/LightingCore/StudyFloat32Eligibility.swift` | `2b5c3de52bb8c2b5667607e3d3eb38f5b580dcfc844f918bbb7291871f207c28` |
| `Tests/LightingCoreTests/StudyFloat32EligibilityTests.swift` | `f334b6619116d0fc316e78bdbb9d2969647e682b6f650c3d8ea10290ac653833` |
| `App/MetalStudyRenderer.swift` | `a77319cd481141a1f94c68eab162ba7619eb5077077d6d8b109d6c588afc43fd` |
| `NativeTests/StudyRendererTests.swift` | `e0b3bfca7d4b8098f783319cf076052b4ebd9a552561898460800d72ac005e30` |
| Debug log | `0064366f4cbb832439c73fc553bc2166c8b68c9beff39db308d4a4f11eaa6e44` |
| Release log | `8ad697ac9e2f229827ea0740c110a712997eef4a48a6a00e4356b42a70961e31` |
| Complete fixture routing JSON | `dee07086fbdad314e50db732baaf6256eef38a7f728802de48b18ec482540b56` |
