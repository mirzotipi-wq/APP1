# W01R03 — Public photometry/color interface audit

## Scope and evidence

- Reviewed revision: `f150f98e35dd735927075aac4d2f8b02295c6a67` (confirmed with `git rev-parse HEAD`). Worktree: `/tmp/keyfill02-workers/w01r03`.
- Assigned source: `SurfacePhotometry.swift`, `Colorimetry.swift`, `LightOutputAdjustment.swift`, `StudioOptics.swift`; traced adjacent scene validation, codec, guided rig and Study consumers, and actual XCTest source.
- Read `AGENTS.md`, `agents/OPERATING_PROTOCOL.md`, `docs/QUALITY.md`, and `docs/ARCHITECTURE.md`. Root owns startup/integration. No source edits, Swift/toolchain runs, builds, installations, network writes, commits or pushes. No child agents.
- Evidence is static source analysis plus an explicitly labeled Python binary64 transcription. Existing Swift tests were **read, not executed**. No ordinary-scene defect was found in this bounded review.
- Prioritization: both findings below are low-severity numerical API edges. They do not establish a practical rendering or major-workflow failure. Root should obtain native Swift witnesses before integration.

## Explicit interface map

| Boundary | Meaning and accepted domain | Result / rejection |
|---|---|---|
| `Position` (`Scene.swift:3–17`) | World metres; finite coordinates in −100…100 | Mutable value; `isValid`, no eager throwing initializer |
| `StudioLight` (`Scene.swift:20–37`) | `candela` is on-axis luminous intensity, 0…100,000; blackbody Kelvin 1,000…20,000 | Validation includes name, position and optional optics; admits every positive subnormal candela |
| `UnitDirection` (`SurfacePhotometry.swift:3–18`) | Dimensionless normalized finite nonzero vector | Failable init; scale-first normalization avoids squared-length overflow/underflow |
| `LambertianRectangle` (`SurfacePhotometry.swift:27–50`) | One-sided uniform emitter, width/height 0.05…4 m; **total on-axis cd**, not lumen or watts; right × up is emission axis | Failable init; orthogonality tolerance 1e−8; immutable validated fields |
| `Photometry.pointIlluminance` (`SurfacePhotometry.swift:81–92`) | cd and SI positions plus normalized receiving normal; inverse-square × receiver cosine | Optional lux; rejects separation under 0.05 m; backside is supported zero |
| `Photometry.rectangularIlluminance` (`SurfacePhotometry.swift:94–197`) | Lambertian integration; radiance factor cd/area, area weights cancel to the intended total cd | Optional lux; minimum absolute plane depth max(0.05 m, longest side / 4); full-face midpoint vs clipped quadrature branches |
| `LightOptics` / `EmitterFrame` (`StudioOptics.swift:16–95`) | Optional target is absolute world metres; absent target follows subject; roll degrees −180…180; right-hand rotation | Mutable configuration with `isValid`; frame init rejects coincident aim and bad ranges; roll zero preserves legacy basis |
| `StudioPhotometry` (`StudioOptics.swift:97–138`) | Subject-centre **camera-facing plane** illuminance; directional means one-sided cosine falloff with inverse square | Optional normal/frame/lux; only selected light and relevant geometry validated; no promise of whole-scene validation |
| `PreviewSettings` (`Colorimetry.swift:3–21`) | Relative exposure stops −6…6; multiplicative 2^stops; WB Kelvin 2,000…10,000 | `isValid`; optional scene setting defaults explicitly |
| `RelativeXYZ` / `blackbody` (`Colorimetry.swift:23–67`) | Scene-linear XYZ; blackbody color normalized Y=1; chromaticity unitless | XYZ initializer stores arbitrary doubles; blackbody rejects out-of-range/nonfinite Kelvin; chromaticity optional |
| `PreviewColorTransform` / `DisplayRGB` (`Colorimetry.swift:43–48,97–140`) | Bradford adaptation, stop scaling, luminance tone mapping, gamut compression, then display-encoded sRGB [0,1] | Failable settings init; optional display rejects nonfinite/negative input and bad adapted output; signed intermediate RGB retained |
| `NeutralCardPreview` (`Colorimetry.swift:143–166`) | Sum direct lux-weighted XYZ; incident Y equals lux; 18% card scaled by 1000-lx relative reference before display | Failable init validates complete scene, distinguishes off sources from unsupported positive sources |
| `LightOutputAdjustment` (`LightOutputAdjustment.swift:23–96`) | Inverts one source’s **individual** camera-facing-plane lux contribution; leaves other fields unchanged | Throws distinct target, light, geometry, range errors; zero explicitly turns source off; positive result checked against forward model to 1e−9 relative |

No candela/lumen substitution, stop/linear scaling confusion, display/scene-linear RGB confusion, or degree/metre misuse was found along these source paths. `incidentXYZ` has a photometric weighting unlike the normalized blackbody color, but its Y=lux relationship is explicit in consumers/tests (`ColorimetryTests.swift:38–49,64–81`). Equality compares stored values exactly; absent/default optics or roll can therefore differ structurally despite equivalent behavior. That is not a correctness defect. Optional fields are migrated/validated by `SceneCodec` and `LightingScene.validated`; no Codable invariant bypass was found along the codec path.

## Unsupported-input propagation assessment

Scene validation (`Scene.swift:62–80`) establishes schema, ranges, counts and IDs; it deliberately does not require source-target or camera-subject separation. Thus a valid persisted scene can have an unsupported photometric configuration.

- `NeutralCardPreview` validates the whole scene at line 152, skips exactly off sources at 157, and propagates any positive-source `nil` or color transform failure through its own `nil` (158–163). Off light at subject versus on light at subject is covered in `ColorimetryTests.swift:97–109`; duplicate/excess lights are covered at 112–117.
- `LightOutputAdjustment` validates source and entire scene (37–40). Target zero returns an off source before sampling (43–45). Positive requests require unit contribution, actual maximum, and achieved-value confirmation (50–94). `LightOutputBoundaryTests.swift:82–109` explicitly tests unsupported-zero behavior and subnormal inverse handling.
- `StudioPhotometry` is a per-source diagnostic primitive. It can return a number on a scene with an irrelevant invalid lens/exposure/schema because it does not validate the whole scene. Its checked higher-level consumers do validate. No actual silently wrong ordinary output caused by this narrower validation was identified.
- `StudyLighting` validates the whole scene and omits off lights (`ReferenceStudy.swift:232–265`); receiver violations throw `invalidSurface` (288–307). Rendered unsupported surfaces use explicit masks, not ordinary black (`ReferenceStudy.swift:373–407`; tests 103–117 and 148–156). Study uses finite-face distance guards; diagnostic rectangle uses stricter plane separation. That declared domain difference is not an output-value defect.
- Huge XYZ values can overflow intermediate display conversion, but the result is `nil`, not a fabricated valid color (`Colorimetry.swift:119–126`). This is fail-closed.

## Findings

### R03-1 — Valid positive rectangular intensity can silently become supported zero lux

**Priority:** Low / extreme-only numerical correctness. It is reachable through a valid scene, but its magnitude is far below practical lighting levels.

`SurfacePhotometry.swift:183` divides intensity by 1024 before applying geometry. A representable positive intensity can round to zero at that division even when the final illuminance is representable. `Scene.swift:33–36` accepts these values. `NeutralCardPreview` does not omit them as off sources, but accepts the returned zero (`Colorimetry.swift:157–160`). The Study preparation has the same issue at `ReferenceStudy.swift:249`.

Minimal unrun Swift witness:

```swift
let source = StudioLight(
    name: "Subnormal", position: .init(x: 0, y: 0, z: 0.05),
    candela: 1e-321, kelvin: 5600,
    optics: .init(kind: .rectangle, widthMeters: 0.05, heightMeters: 0.05))
let scene = LightingScene(subject: .init(x: 0, y: 0, z: 0),
                          camera: .init(x: 0, y: 0, z: 3), lights: [source])
_ = try scene.validated()
// Static reasoning + Python transcription predicts .some(0), not nil:
let actual = StudioPhotometry.illuminance(for: source, in: scene)
```

Python transcription results for this 5 cm square at 5 cm depth:

| Input cd | Existing operation order, lux | Centered analytic reference, lux | Relative error |
|---:|---:|---:|---:|
| 1000 | 300965.80523483234 | 300909.8753816429 | 0.0186% |
| 1e−320 | 3.497293e−318 | 3.009067e−318 | 16.225% |
| 1e−321 | 0 | 3.00313e−319 | 100% |
| least subnormal | 0 | 1.487e−321 | 100% |

Moving intensity multiplication after the ordinary unit-intensity midpoint sum gives `3.00367e−319` for 1e−321 cd. Agreement with the independent centered-rectangle analytic expression establishes that the failure is early underflow, not insufficient quadrature. The existing `LightOutputBoundaryTests` protect the inverse against underflow and preserve already achieved subnormals, but do not enforce forward-model accuracy on these values. A repair should either retain the signal by delaying scaling or explicitly abstain; do not silently turn positive supported emission into dark output.

### R03-2 — Chromaticity loses scale invariance for finite large coordinates

**Priority:** Low public API edge, not reachable via bounded scene-generated XYZ.

`Colorimetry.swift:30–31` sums first. For `RelativeXYZ(x: 1e308, y: 1e308, z: 1e308)`, each coordinate is finite/nonnegative, but their sum overflows and `.chromaticity` returns `nil`. The equivalent normalized input `(1,1,1)` yields `(x: 1/3, y: 1/3)`; those answers are representable for the large input as well. Max-component scaling before summation fixes the numerical issue while preserving nil for zero, negative or nonfinite values. Python output confirms `0.3333333333333333` for both coordinates after scaling.

For the same triple with default WB/exposure, adapted XYZ remains finite but XYZ→RGB matrix products overflow; `display` returns `nil` via its explicit nonfinite guard at line 125. Recorded as a fail-closed limitation, not another silently wrong color finding. `UnitDirection` correctly handles both least-subnormal triples and `(1e308,1e308,0)` in the transcription.

### Adjacent API boundary note, not an assigned-file integration request

`Scene.swift:96–99` accepts any finite distance ≥0.05. At `candela=100000`, `distanceMeters=1e160`, squaring distance overflows, producing 0 lux although `(candela / distance) / distance` is representable as `1e−315`. This cannot occur through bounded scene positions. It is recorded in the probe artifact for completeness; do not treat it as a practical scene failure.

## Commands and artifacts

Read and inspection commands actually run are listed in `commands.txt`, including two initial incorrect assumed paths (`LightingScene.swift`/`Photometry.swift`, `App`) that produced file-not-found diagnostics before discovery of `Scene.swift` and the available core-only tree. Some large combined outputs were truncated and the relevant source files were read again. No missing-path command is represented as successful evidence.

Numerical command, run twice while extending the bounded probe:

```sh
python3 private-output/probe_interfaces.py
```

Both invocations exited 0; Python assertions passed. This is **not** a Swift test pass. Outputs:

- `private-output/report.md` — this report.
- `private-output/probe_interfaces.py` — complete numerical transcription, ordinary reference and adversarial fixtures.
- `private-output/probe-results.json` — machine-readable observed Python results.
- `private-output/commands.txt` — read/inspection command record.

Recommended follow-up: root reproduce R03-1/R03-2 in the already authorized native toolchain run; preserve ordinary 32×32 sample-order parity if fixing finite-emitter arithmetic; add targeted scale-invariance tests. No broad test or further review run was performed here.
