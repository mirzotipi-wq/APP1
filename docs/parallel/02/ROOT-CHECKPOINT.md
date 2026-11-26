# Root checkpoint

Source baseline f150f98e35dd735927075aac4d2f8b02295c6a67; published setup
277aea9203f6c61d2a66d1e7f484acb2c0cb1839 (tree matches local setup commit).
Shell push has no credential; authenticated GitHub connector publishes coherent
Git trees/commits, followed by shell fetch and ls-remote verification. No main writes.

Portable Swift6.0.3 Ubuntu24 toolchain runs on Debian13. Installed only in /tmp;
removed own unused embedded/debugger tools after extraction exhausted tmpfs.
Own minimal toolchain962MiB; package debug build62MiB. All builds jobs1, serialized.
Baseline command: `/tmp/keyfill02-toolchain/usr/bin/swift test --scratch-path
/tmp/keyfill02-build --jobs 1`. Actual366 tests passed, zero failures,14.768s test
execution (build excluded). Full log preserved. No Apple-native execution.

Wave1 active; nine children managed by W01R01 plus acceptance role itself gives
exactly ten wave workers. Root code integration remains serial. Reports stored
per wave; don't call planned workers executed. Initial independent rectangles
remain below5%; no ordinary scene photometry defect established yet.

Confirmed production Swift boundary reproducers: RelativeXYZ(max,max,max)
chromaticity/display return nil; finite nonzero tiny rectangle intensity1e-321
returns0 while centered analytic result3.00313e-319; intensity1e-320 error16.225%.
These are extreme numeric cases, not typical lamp settings. Proposed tiny-output
fix must preserve ordinary summation/renderer behavior, solve by forward-check,
and transparently update obsolete computational-underflow expectations only.

Primary references: PBRT4ed radiometric area integration; Wyman/Sloan/Shirley
JCGT2013 analytical CMFs; CIE2019 standard observer DOI10.25039/CIE.DS.xvudnb9b
with official CSV md5 17cca777db64b17170f06f67ce9d3ab7 verified after download
from https://files.cie.co.at/Publications-datasets/CIE_xyz_1931_2deg.csv.
CIE data licenseCC BY-SA4.0: derived reference tables need attribution/license;
production approximation is distinct. Current blackbody maximum xy discrepancy
against1nm CIE full360–830nm integration is~0.0109364 at1000K; at3200K~0.00102328.
This is approximation characterization, not equipment calibration.

Next: finish wave1; wave2 independent fixtures; wave3 point/orientation regressions;
wave4 rectangle fix; wave5 solver robustness; wave6 color; wave7 consumers;
wave8 sweeps; wave9 challenge; wave10 deliver. Keep protected thresholds.
