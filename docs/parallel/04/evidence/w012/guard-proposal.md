# Resolution-aware sphere-silhouette routing proposal

## Exact centered-camera reduction

Let `W` be the actual compute width, `H=2W/3`, `D=|camera-subject|`, `r=0.22`, `a=18/focal`, and `b=12/focal`. Validate the same compute resolution domain (`24...192`, multiple of three) before arithmetic. Also preserve `StudySetup`'s `D>r+minimumDepth` and camera-above-panel requirements; an invalid camera is not repaired by silhouette routing.

For sample centers, `px=(2(x+0.5)/W-1)a`, `py=(1-2(y+0.5)/H)b`, and `q=px²+py²`. With camera aimed at the sphere center and an orthonormal basis, the ray's closest sphere-center distance is `rho=D*sqrt(q/(1+q))`; its silhouette occurs at `q*=r²/(D²-r²)`. Equivalently the stable discriminant is `[r²-(D²-r²)q]/(1+q)`. This is only primary-ray sphere classification, not complete rendering/mask equivalence.

For each row, solve the positive half-image crossing:

`x*=0.5*(W*(1+sqrt(max(0,q*-py²))/a)-1)`.

`rho` is monotone in nonnegative `px`, so the minimum absolute distance to `r` is at the floor/ceil neighbors of `x*`, clamped to `[W/2 rounded down, W-1]`. When `py²>=q*`, the nearest central sample is the minimum. For engineering robustness to Double index rounding, inspect one additional column on each side; duplicates are harmless. This needs at most four candidates per row, constant storage, and at most 512 candidates at the maximum resolution. It also handles odd widths, whose center column has `px=0`. Evaluating both signed counterparts can avoid relying on bitwise symmetry of the Double pixel formula while remaining O(H).

## Broad margin and measured preservation conflict

A transparent engineering screen is reject if any candidate has `abs(rho-r)<=64*Float.ulpOfOne*D` (here epsilon is `2^-23`, not unit roundoff `2^-24`). This covers a broad meter-scale error budget for Float packing, ray generation, and closest-point arithmetic, but is not a proved Metal bound.

The private analytic probe shows why this is not ready as the sole eligibility rule. At the exact width24/focal161.27198111190464 case, clearance is `1.35681882396e-10 m`, well inside the `2.28881835938e-5 m` margin. However `.portrait()` at width192 has clearance `3.57368754983e-6 m`, so both `32εD` and `64εD` reject it despite the existing explicit eligibility assertion. Ordinary six-fixture camera configurations clear the64εD silhouette screen at widths48 and192; the near-field fixture still fails the independent existing light guard. No multiplier was reduced merely to restore portrait.

## Candidate tightening: bounded component intervals

A separate O(W*H), constant-storage guard can enclose the actual packed Float32 primary-ray calculation instead of applying the same isotropic meter error to every camera orientation:

1. Pack origin, basis, half-field widths, and radius exactly as `StudyComputeInput`; initialize intervals at those Float values promoted to Double. The original CPU geometry remains full Double and must not be replaced by these values.
2. Propagate intervals through the exact pixel expression, `forward+right*px+up*py`, normalization, `lengthSquared`, `centerT`, each component of `closest`, and the final `radius²-dot(closest,closest)`.
3. At every arithmetic operation, outward-round the interval and expand each finite result endpoint by an explicit engineering budget, e.g. `epsilon*max(abs(lower),abs(upper))+leastNonzeroFloat`. Preserve exact zeros when the operation is exact. For `normalize`, an independently selected/documented component error envelope is additionally required; a candidate such as eight epsilon relative error is an assumption requiring measurement, not a device guarantee.
4. Reject if the final discriminant interval contains zero, has a nonfinite endpoint, or has a definite sign disagreeing with the authoritative Double classification. Admit only definite same-sign results. Near-plane/sphere-versus-panel ordering needs its own checks if this is extended beyond the requested silhouette decision.

The component bound is naturally tighter for an axial camera: large cancellation lies in the forward component, while tangential components stay near the sphere radius. It does not specially recognize portrait or the reproduced fixture. A cheap broad O(H) screen could allow clearly separated cases immediately; uncertain cases could use the full O(pixels) interval fallback. No interval implementation was run in this task, so preservation under this alternative is unresolved.

Unproved assumptions: exact packed input representation, ordinary finite Float32 operation bounds and contraction behavior, `normalize` component accuracy/common scaling behavior on shipped Metal, subnormal handling, and agreement between the centered-camera analytic Double reduction and shipped Swift near cancellation. CPU Double oracle and actual Metal must ultimately verify any admitted domain; Python arithmetic does not supply that acceptance evidence.

## Execution and files

Private run `w012-silhouette-analytic-001`:

`python3 /tmp/keyfill04-2987b1ee980d/results/w012/silhouette_guard_probe.py > /tmp/keyfill04-2987b1ee980d/results/w012/silhouette_guard_probe.log`

The exhaustive-versus-row comparison used52 camera/width combinations; maximum minimum-clearance difference `3.885780586188048e-16 m`. Bounded row scans additionally inspected57 legal widths for six camera configurations. This is Python analytic Double arithmetic only, not C++ shared Float32, transcribed C++ Double rendering, shipped Swift, or Metal.

The existing baseline evidence is a separate recorded run of the shared C++ Float32 kernel against transcribed C++ Double geometry: two mismatched pixels, fraction above four `0.005208333333333333`; it was read, not rerun here. Shipped Swift oracle and actual Metal remain unrun. No product files, contracts, fixtures, tolerances, harnesses, or ABI changed; no builds, commits, branches, or publishing occurred.

## Focused ambiguous-pixel count follow-up

Run `w012-ambiguous-counts-002` used `python3 /tmp/keyfill04-2987b1ee980d/results/w012/ambiguous_pixel_counts.py`, with output in `ambiguous_pixel_counts.json/.log`. Both the 32εD and 64εD screens produce:

| Camera/setup | Width 48 | Width 192 |
| --- | ---: | ---: |
| portrait (active lights) | 0 | 8 |
| hard (active point lights) | 0 | 0 |
| soft (active area lights) | 0 | 0 |
| warm-rotated (active area/directional lights) | 0 | 0 |
| dark (no lights) | 0 | 0 |
| near-field (existing light guard rejects) | 0 | 0 |
| translated (active area lights) | 0 | 0 |

For the confirmed no-light width24/focal161.27198111190464 setup both screens flag16 of384 pixels. This shell is conservative; the baseline recorded only two actual shared-kernel versus transcribed-Double mismatches.

A future count budget can avoid rejecting every flagged pixel while preserving fixed aggregate thresholds: for N ambiguous pixels among P, the worst possible RGB mean contribution is `255*N/P`, and the worst fraction of channels above four is `N/P`. For portrait192 these are `0.0830078125` and `0.0003255208333333333`, respectively. For the confirmed width24 shell, the fraction alone is `0.041666666666666664`, above the fixed0.005 threshold. Admission based on counts additionally needs a justified, explicitly reserved error budget for all remaining pixels and separate exact invalid-mask protection. It cannot establish the strict maximum-channel-error≤1 contract: any ambiguous pixel may violate that maximum. No count rule, margin, fixture, or tolerance was changed here.

Coordinator-proposed future wave3 policy (not implemented): a 32εD shell with ambiguous-pixel allowance `min(floor(P/510),floor(0.0025*P))`, reserving half of both unchanged aggregate budgets. Allowances at widths24/48/96/192 are0/3/12/48. This admits portrait’s eight shell pixels and rejects the confirmed scene’s16. The32εD multiplier remains an engineering assumption; counting cannot substitute for exact masks or the strict maximum-error gate.
