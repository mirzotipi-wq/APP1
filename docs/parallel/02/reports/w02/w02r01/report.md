# W02R01 — independent acceptance audit

**Input:** `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b`; frozen LightingCore v1. Actual agent `/root/w02r01`.

One tiny Swift probe executed six fixed fixtures. Independent scalar dot products supplied two point references; a closed-form rectangle integral supplied two centered references; direct world-space ray-cosine Simpson integration supplied oblique and partially illuminated references. The latter used 80/160 panels per axis to check convergence without production clipping or Gaussian quadrature.

| Fixture | Reference lx | Swift lx | Error % |
|---|---:|---:|---:|
| point_diagonal | 106.066017178 | 106.066017178 | 1.33981223e-14 |
| point_three_axis | 22.2222222222 | 22.2222222222 | 0 |
| rectangle_centered | 912.245356256 | 912.403080956 | 0.0172897236 |
| rectangle_minimum_depth | 1342.56437448 | 1342.75228913 | 0.0139966954 |
| rectangle_oblique | 512.052135954 | 512.109534426 | 0.0112094976 |
| rectangle_partial | 90.898342749 | 90.8983427302 | 2.06721052e-08 |

**Result:** 6/6 pass. Maximum point error 1.33981223e-14% against unchanged 1%; rectangle error 0.0172897236% against unchanged 5%. Every relative-error denominator is the positive independent reference lux. Simpson refinement changed references by at most 3.1009876e-07%.

Exact commands in `commands.txt`; probe, formulas, full fixtures, source provenance and raw/results JSON retained. No production edits or package builds. These fixed ideal-model fixtures do not establish a global error bound, renderer equivalence at grazing incidence, equipment calibration or iOS performance.
