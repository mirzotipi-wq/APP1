# W02R10 — independent CIE/Planck reference

**Finding:** production blackbody chromaticity differs measurably from the official tabulated observer, principally because of its documented analytic observer approximation.

Revision `1b286885cb803ba17e159713651515ab119e17f1`, immutable snapshot `v1`, Swift 6.0.3, x86_64 Linux. Actual `PreviewColorimetry.blackbody` results were captured at 1000, 2000, 2856, 3200, 5600, 6500, 10000, and 20000 K. All eight returned finite XYZ/xy with Y = 1.

The independent reference integrates physical Planck radiance against official CIE 1931 2° data from 360–830 nm using 1 nm trapezoids, exact defining SI constants, and compensated summation. Both required file hashes match; provenance is in `table.json`.

Maximum Euclidean xy difference is **0.0153932977184 at 1000 K**: reference `(0.652750643305, 0.344461708107)`, Swift `(0.641917863605, 0.355398092273)`. At 2000 K the difference is 0.003675246138; at 6500 K, 0.000290008780.

Across these same eight cases, component maxima are: analytic observer **0.015353496136**; wavelength truncation **0.000124833987**; 5-to-1 nm integration-step difference **0.000006747370**; radiation-constant rounding **7.94e-11**; Python/Swift arithmetic **2.78e-16**. Signed components telescope exactly within 1e-15; their norms are not additive. The analytic diagnostic intentionally mirrors production coefficients; the official-data reference does not.

Reproduce using the two commands in `run.log`; sources are `probe.swift` and `reference.py`. `probe.log`, `table.csv`, and `table.json` retain actual results. The official CSV is fetched in memory and is not shipped.

These eight ideal spectra establish no perceptual, device, or calibration accuracy. The step-size comparison is not a rigorous quadrature bound. Existing 1% point / 5% area illuminance gates are unchanged and do not define an xy tolerance.

Derived table: **CC BY-SA 4.0**, adapting CIE 2019, DOI [10.25039/CIE.DS.xvudnb9b](https://doi.org/10.25039/CIE.DS.xvudnb9b); full attribution and license in `ATTRIBUTION.md`.
