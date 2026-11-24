# M02 independent numerical evidence: grazing incidence (2026-11-24)

Current exact tested executable revision: [a13d8c96](https://github.com/mirzotipi-wq/APP1/commit/a13d8c96aabee2ef2ffd7a38c4119efcfb197d41). [Core job 138254104603](https://github.com/mirzotipi-wq/APP1/actions/runs/45337859919/job/138254104603), [raw artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45337859919/artifacts/14894921441), Ubuntu 24.04, Swift 6.4.2, portable Debug and Release **132/132**, zero failures. Actual source checks, reference rendering and shared Float32 kernel parity passed. No independent reviewer or physical device.

## Observed defect and method

The ideal uniform one-sided rectangular emitter computes incident illuminance in lux. For a receiver at positive plane depth d, local sample displacement r, and nonnegative receiver projection q, integrate d*q/|r|^4 over emitting area, multiplied by on-axis candela/area. The positive receiver projection is affine across the face. A 32x32 midpoint grid can miss an illuminated sliver narrower than one cell. A local independent Python numerical experiment (not production Swift or native measurement) found 0 lx from the old midpoint scheme for the 1 mm strip in the declared 1 x 0.6 m fixture at 0.25 m depth.

The first source [71a15b08](https://github.com/mirzotipi-wq/APP1/commit/71a15b08ba44c438ebb706b54f27b2f2edc9b1ad) clipped the face and integrated all contributing regions, but exact-source [Debug run](https://github.com/mirzotipi-wq/APP1/actions/runs/45337556264/job/138253131547) failed the existing renderer adapter equality: 358.3559956565057 vs 358.3295433291197 lx, tolerance 1e-8 lx. 130/131 tests passed, including both new grazing tests. Preserve this failure. Current correction retains the original ordered midpoint grid for fully front-facing receivers; for partially facing rectangles, clips the polygon against the positive-incidence half-plane, triangulates the convex polygon, and integrates with positive barycentric interpolation and 12x12 Gauss-Legendre quadrature per triangle. At most five vertices/three triangles/432 samples in the partial case. Fully back-facing receiver returns zero. No near-field, occlusion, reflection, modifier transmission, spectral or real-world accuracy claim. Minimum plane separation unchanged: max(0.05 m, longest side/4). Zero-area tangent contact is not a positive illuminated area.

## Exact Swift CI results

Existing six parallel analytic fixtures and four independent off-axis Simpson fixtures retained. Eight new positive strip/corner fixtures use a separately implemented composite Simpson vertical-slice reference on the known contributing region.

| Fixture | Actual lux | Reference lux |
|---|---:|---:|
| Strip cut 0.45 m | 1.4589925586052157 | 1.4589925588055537 |
| Strip cut 0.48 m | 0.20856348150096382 | 0.2085634815302207 |
| Strip cut 0.499 m | 0.00048664642096451474 | 0.0004866464210327955 |
| Strip cut 0.49999 m | 4.8492374775812255e-08 | 4.8492374783183897e-08 |
| Corner cut 0.6 m | 1.8821458448778798 | 1.8821458452128712 |
| Corner cut 0.79 m | 0.00012630964555215244 | 0.0001263096455522049 |
| Corner cut 0.799 m | 1.2289461851570823e-07 | 1.2289461851568804e-07 |
| Corner cut 0.79999 m | 1.225259851916436e-13 | 1.2252598519258684e-13 |

- Max logged relative error among 18 positive area fixtures: 0.00023334691793906986 (0.0233347%); eight grazing fixtures max 1.7798374596233513e-10 relative. These are declared mathematical test cases only, not a bound over the entire model or measurements of a physical modifier.
- Existing exact adapter comparison passed at 1e-8 lx tolerance. New mirrored strip, tangent/dark and minimum-depth partial/full transition (<0.2% test tolerance) assertions passed. No existing tests relaxed or removed.
- Point analytic, nine rotated reference-study convergence cases (max relative error 0.0032798081798638967 between 8x8 and 32x32), and existing CPU/Float32 shared host comparisons passed.

## Limits and follow-up

The study renderer uses precomputed 8x8 or 32x32 samples for visibility, direct shading and CPU/Metal parity; the numerical meter's clipped grazing estimator is distinct. It is not an exact full renderer or calibrated skin/portrait solution. KF-025 tracks renderer grazing consistency. Physical device, calibrated scenes, independent photographer review and performance remain unverified; M02 remains pending behind M01.

Commands on repository source: `swift test --jobs 2`; `swift test --configuration release --jobs 2`; CI reference rendering and shared Float32 verification steps. Raw output linked above. No paid compute or store publication.
