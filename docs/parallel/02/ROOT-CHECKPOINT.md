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

## Restored-execution checkpoint

Verified remote47de6afe6afe24a7822f4276950f70bd3db9f57d preserves completed
wave02. There are26completed actual contexts and29created (wave03R07–09
active); six-of-ten wave03 checkpoint is persisted. No planned worker is counted.
Root schedules wave03 directly; future R01 acceptance workers may coordinate
nine children, max two active, to keep four total contexts and bounded root
context. All remain fresh and isolated. Coordinator helper writes only its own
private ledger, root harvests into the campaign ledger. Exact token accounting
is unavailable; working targets and60% role checkpoints are operational limits.

Restored repo/tmp/keyfill02-r2, toolchain/tmp/keyfill02-r2-toolchain, private
build/tmp/keyfill02-r2-build, immutablev1 module/tmp/keyfill02-r2-snapshots/v1
(source1b28688, same production as58b3). Worker trees/tmp/keyfill02-r2-workers.
Helpers/tmp/keyfill02-r2-{state,harvest,team-record,probe,publish}.py. Build/probe
lock/tmp/keyfill02-r2-build.lock. At latest measurement/tmp2.3GiBfree and RAM
3.7GiBavailable; packagejobs1. No shared/other-lane cleanup.

One reviewed directional regression integrated (actual24lx from independent
1250/25*(3/5)*(4/5)); targeted package XCTest passed1/1. Production unchanged.
Official8-temperature CIE1nm comparison is now complete, max Euclideanxy error
0.01539329771842178 at1000K; old component-based maxima are historical.
Current source CIcore374Debug/374Release passes; simulator/app-accessibility
failed inherited ambiguity in UITests. Original excerpts retained.
Lane01 contract966c9c21 inspected; no signature/schema change required; route
admission remains lane01's pending work. Consumer requests updated.

## Wave04 recovery and source checkpoint

Second executor reset erased/tmp duringW04. Verified remote047803c preserved
all30 earlier role reports and the new directional test. Restored same paths,
Swift6.0.3 andv1module (built047803c; all Sources identical1b28688). All affected
W04 checks regenerated actual second-executor logs in SAME contexts, no new
worker count. tools/resumed-* preserve state/harvest/probe/publish helpers and
briefs. RESET-RECOVERY.md records exact losses and recovery. Do not claim lost
original logs were recovered.

Verified remote928ca0eafa6330742114c2e0ac184789c2f17752 preserves reviewed tiny
clipped-face regression, targeted1/1 package pass and W04R01–08 evidence. W04R09
now completed;R10independent grazing is active.40created/39completed actual.
W05ten worktrees already prepared at928ca0e (not counted as contexts).
Root resumed direct scheduling forW04R06–10 to bound coordinator recoverycontext.
Later waves can use freshR01coordinator plus9children, max2atonce.
Latest/tmp free2.0GiB, RAM available2739MiB; keep one-job package builds and
serializedprobecompilation. Keep shared SDK intact. Public API/source math still
58b3; only two new focused regressions added since that core374 CI pass.
