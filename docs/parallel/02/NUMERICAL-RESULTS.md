# Numerical results — ideal model only

Frozen requirements remain **≤1% supported point** and **≤5% declared area**.
Results below measure numerical agreement against independent references. They
are not physical calibration, device/GPU execution, or camera-response accuracy.
Production is58b3ca4 (identical mathematics in1b28688 and current lane checkpoints).

| Case set | Cases | Maximum relative error | Percent | Required limit |
|---|---:|---:|---:|---:|
| Scalar inverse-square/receiver cosine sweep |64|2.220446049250313e-16|2.22045e-14%|1%|
| Spherical-edge rectangle sweep |1440|0.0021568264589441055|0.2156826459%|5%|
| Translated independent directional double cosine |1|0|0%|1%|
| Independent arbitrary off-axis directional fixture |1|2.8716355540e-16|2.87164e-14%|1%|
| Rolled oblique37degree Simpson fixture |1|2.65807e-10|2.65807e-8%|5%|
| Held-out -63degree grazing Simpson fixture |1|2.528440804957476e-12|2.52844e-10%|5%|
| Clipped-face scalar antiderivative, unit output |1|3.8554755827258091e-5|0.0038554756%|5%|

The1440-case rectangle matrix formerly produced120 unexpected unsupported
results; normal normalization removes those failures. The maximum error case
is a4x0.05m rectangle at1m depth and offset(3.2,0.025)m: reference
34.08463164138468lx, Swift34.01111700601718lx. Relative-error aggregation uses
40positive point and1025positive rectangle rows. The24+415 dark/nearzero rows
have exactly zero absolute discrepancy. See REFERENCE-METHODS.md for complete
sizes, distances, rolls, receiver orientations and denominator rules.

Tiny clipped regression: eight least-nonzero candela steps produce one
least-nonzero lux step; intensity/area first would round tozero. This is a
floating-point boundary fixture, not a practical lamp-output claim.

## Blackbody approximation characterization

Official CIE1931 2degree,1nm Planck integration is independent of the production
analytic observer approximation. The xy distances are not illuminance errors,
perceptual color differences, or an invented pass/fail gate.

| Kelvin | CIE x | CIE y | Swift x | Swift y | Euclidean xy difference |
|---:|---:|---:|---:|---:|---:|
|1000|0.652750643|0.344461708|0.641917864|0.355398092|0.015393298|
|2000|0.526677484|0.413297008|0.524052126|0.415868958|0.003675246|
|2856|0.447535165|0.407428325|0.446233562|0.408660537|0.001792349|
|3200|0.423359620|0.398951684|0.422336341|0.399924630|0.001411992|
|5600|0.330197984|0.339079658|0.329979912|0.339416111|0.000400944|
|6500|0.313526035|0.323628662|0.313419162|0.323898261|0.000290009|
|10000|0.280633785|0.288288414|0.280720438|0.288463467|0.000195326|
|20000|0.256457507|0.257631688|0.256662281|0.257771174|0.000247767|

Across these eight cases, successive-reference diagnostic distance maxima are:
observer approximation0.015353496136; wavelength cutoff0.000124833987;
5nm versus1nm integration0.000006747370; radiation-constant rounding7.94e-11;
Python/Swift arithmetic2.78e-16. These components are not independent additive
error bars. Full scalar vectors, source hashes, commands and attribution are in
reports/w02/w02r10. Maximum totalxy distance is0.0153932977184 at1000K.

Derived CIE table: CIE2019, DOI10.25039/CIE.DS.xvudnb9b, CC BY-SA4.0.
See reports/w02/w02r10/ATTRIBUTION.md. No official dataset is embedded in product
source. Retaining the documented analytic approximation avoids conflating
observer approximation with the separately corrected arithmetic overflow.

## Evidence locations

- Main matrix: evidence/sweep-rows, evidence/spherical-reference-summary.json.
- Directional witnesses: reports/w03/w03r04 andw03r10.
- Grazing and tiny clipped references: reports/w04/w04r10 andw04r04.
- Regression execution: evidence/w03-directional-test.log andw04-tiny-clipped-test.log.
- Domain, error-state and deterministic probes: per-role reports/ledgers.

Additional wave08/09 challenge results will be recorded separately so they do
not silently change the original declared matrix or its denominator.
