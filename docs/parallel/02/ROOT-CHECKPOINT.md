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

## Second root checkpoint

Wave01 complete10/10 and preserved at verified remote5579b4f. All recorded
artifact hashes checked against remote commit before removing its10owned
worktrees. Wave02 active. Root independently discovered that raw rectangle
cross-product normals can be short byoneULP after roll; exact minimum-depth
receivers then incorrectly returnnil. Current candidate normalizes that cross
product; strict nextDown separation rejection preserved.26targeted tests pass.
1504point/rectangle cases pass against independent spherical-edge integration;
120unexpectednil rows in prior source are retained. Maximum area error0.215683%.
W02R04 independent rolled-oblique Simpson fixture integrated for full validation.

Remote f75 run45816637769 core job139897956193 passed372Debug+372Release,
100tooling tests and existing shared-kernel parity checks. macOS core372passed.
Simulator build failed existing UITests/StudioAppAccessibilityUITests.swift:95
ambiguous greatestFiniteMagnitude from f150; this is main's b0d25ee fix and is
outside lane02ownership. Original failure excerpts retained, no AppleUI pass.
Current source changes require their own validation; no automatic carryforward.
