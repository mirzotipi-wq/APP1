# M01 / independent M02 evidence: optics and camera — 2026-11-23

Base c0a735a5075fcfaebfd866a5b6de02fd8cb07e06; tested portable revision 6adcc366101356ba6eec674b278db035265a7f96; native integration d306e64f7e53a514e23f720bc3af3eb9e463be9a. Reviewer: assistant self-review, not independent. No parallel workers available.

## Portable verification

Repository package reconstructed from GitHub file contents in a local Debian GNU/Linux 13 x86_64 environment, Swift 6.2.1 RELEASE. Command: `swift test --jobs 2`. All package/source/test bytes checked with `git hash-object` against the recursive GitHub tree. No Xcode available.

- Baseline: 22 tests passed.
- Optics integration: 30 tests passed.
- Camera model: 37 XCTest cases, zero failures, zero skips, 0.441 seconds XCTest execution at 20:19:37 UTC.
- New coverage: legacy scene migration, invalid optics, aiming and right-handed basis, camera-facing lux, point/area reference agreement, near-field abstention, persistence of optics; full-frame FOV and coverage, projection inside/outside frame, orientation, invalid and near-behind camera, schema v1/v2 migration, lens persistence.
- 50 mm at 3 m: ideal subject-plane coverage 2.16 × 1.44 m; horizontal FOV approximately 39.60°, vertical 26.99°.
- Ten rectangular emitter analytic/numerical fixtures: max relative error 0.0678272%; bounded mathematical fixtures only. The original independent integration reference uses composite Simpson quadrature, not measured photographic ground truth.
- Test pass is portable domain evidence, not native UI performance, photographic calibration or production renderer evidence.

## Verified Git blobs

| Path | Git blob SHA |
|---|---|
| Package.swift | a574497006b00a96ee33d29439b1da5be8eb9363 |
| Sources/LightingCore/CameraFraming.swift | 7d2c50105bda390ca49cdaa75711380cc5047ae7 |
| Sources/LightingCore/LightingRecipe.swift | 3a14ee3dddd4243c7e3844e357357315738a2791 |
| Sources/LightingCore/Scene.swift | 0c0fa19eefea57bca0de1fa10dd14a60c6f6e5c7 |
| Sources/LightingCore/SceneCodec.swift | 477f03715b27d3869381779fd8d47a9f2c7c2433 |
| Sources/LightingCore/SceneFileStore.swift | e1298b1d459c2655b67430dd5638ec3e7caf2989 |
| Sources/LightingCore/StudioOptics.swift | 5ee90979dd96a18eff6609ac488a36513c35d3b9 |
| Sources/LightingCore/SurfacePhotometry.swift | b3e3098fd88bc1e995322242cdba38c971072fa6 |
| Tests/LightingCoreTests/CameraFramingTests.swift | 12da7cbc4a87e202d7863973c3a9d8e6077e892f |
| Tests/LightingCoreTests/PrototypeTests.swift | 60bc917c209564a03c8032a90feb839d1f68467f |
| Tests/LightingCoreTests/SceneFileStoreTests.swift | 5ad13f192b47f5f463e065d28f5b4bdb794ce4a4 |
| Tests/LightingCoreTests/SceneTests.swift | 02d777cf2b62231b9de4dc6f834a881ab898aa33 |
| Tests/LightingCoreTests/StudioOpticsTests.swift | 8a590db71dd9ac5db406c1f2e84a5430cbf65187 |
| Tests/LightingCoreTests/SurfacePhotometryTests.swift | 5a8442c2fec463b946259ad6c2a7da0212049458 |

## Native verification

Latest [run 45258658322](https://github.com/mirzotipi-wq/APP1/actions/runs/45258658322), source d306e64f7e53a514e23f720bc3af3eb9e463be9a. Jobs 137987129423 simulator and 137987130081 core queued, no executed steps, no artifacts. Earlier runs 45258427284, 45258000046, 45257582449, 45256267785 and 45256006750 also queued at inspection. [Run 45254550467](https://github.com/mirzotipi-wq/APP1/actions/runs/45254550467) concluded failure; both jobs 137972802092 and 137972802603 canceled without executed steps. Both job-log requests returned 404 BlobNotFound. No evidence of a compiler error. No native build or screenshot exists from this observation. Four UI smoke scenarios authored, execution pending.

## Limitations and release gates

SceneKit remains an illustrative stand-in (spot/omni lights and simplified subject); rectangle geometry and numeric finite-source estimates do not establish calibrated area shadows, skin, spectral color or exposure. Camera 3:2 viewport requests ideal FOV but its actual pixel output is unverified. No physical iPhone performance, thermal, accessibility or AR measurement. No rights-cleared reference or independent photographer evidence, customer validation, commercial readiness, privacy review or owner approval. M01 remains active; M02 remains pending. Do not declare release-ready. Follow HANDOFF for next executable packet.
