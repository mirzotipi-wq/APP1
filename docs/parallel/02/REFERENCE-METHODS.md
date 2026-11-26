# Independent reference methods and supported domains

These are ideal calculations, not measurements or physical equipment calibration.
Point acceptance remains <=1% relative error; the declared rectangular test
matrix remains <=5%. Source output is on-axis candela, positions/meters, result/lux.

## Point reference

Scalar inverse-square times receiver cosine: `E=I*max(0,cos(theta))/r²`.
The deterministic matrix contains64cases: distances0.05,0.1,0.5,1,2,5,10,50m;
receiver angles0,15,45,60,89,90,120,180degrees;1375cd. The standalone Swift probe
calls production `Photometry.pointIlluminance`; expected values use Python
scalar trigonometry rather than its vector helper. Tilted directional sources
and transformed coordinates are independently covered by worker probes/tests.

## Rectangle boundary-integral reference

Production evaluates the surface integral using a32×32 midpoint grid or clipped
12×12 Duffy/Gaussian triangle quadrature. The independent sweep instead projects
corners onto the unit sphere about the receiver, clips that spherical polygon
to the positive receiver hemisphere and integrates its edges.

For unit spherical edge endpoints `a,b`, let `theta=atan2(|a×b|,a·b)`.
The vector-area identity gives the cosine-weighted solid angle as
`abs(n·sum(theta*(a×b)/|a×b|))/2`. Multiply by radiance `I/(width*height)`.
The identity follows from Stokes' theorem: the spherical surface integral of
its outward vector equals half the boundary integral of `omega×d(omega)`.
On a great-circle edge this cross product has constant direction and its
integrated magnitude is the arc angle. Winding determines the sign; the
one-sided front-facing fixture orientation selects the positive magnitude.
This edge sum does not reuse production sample grids, Gaussian nodes, triangle
maps or area-integration code. Hemisphere clipping is mathematically necessary
in both methods; separate worker Simpson-on-slices references challenge it.

Declared rectangle matrix:1440cases at1375cd. Dimensions0.05×0.05,0.1×4,
0.6×0.9,1×1,4×0.05,4×4m. Plane separation is max(0.05m,longestSide×factor),
factor in0.25,0.5,1,3. Rolls0,37,90,179degrees. Receiver planar offsets are
(0,0),(0.3width,−0.2height),(0.8width,0.5height). Receiver tilt is0,35,80,100,130
 degrees with0.7rad azimuth. Emitters are centered at the origin and face+Z.
This includes minimum separation, aspect ratios80:1, grazing and fully dark
faces; it is a declared test matrix, not an error proof for every floating input.

For relative-error aggregation, expected lux must exceed1e-7. Other rows use
absolute error<=1e-8lx because relative error at zero is undefined. All415 dark
rectangle rows returned exactly zero. All point nearzero/dark rows agreed
exactly. Thresholds are not applied to fabricated epsilon denominators.

At f75aa27 the same sweep returned120unexpected unsupported rows due to the
unnormalized emitter cross product. The original failure cases are preserved
in evidence/spherical-reference-before-failures.json. Normalizing the emitter
normal removes these failures without widening the physical separation domain;
new nextDown regressions retain strict rejection below the limit.

Current candidate sweep:64point/1440rectangle, zero unexpected unsupported;
maximum point relative error2.220446049250313e-16 (2.22e-14%);
maximum rectangle relative error0.0021568264589441055 (0.2156826459%).
The worst rectangle is4×0.05m,1m separation, zero roll, offset(3.2,0.025)m,
normal tilt0: reference34.08463164138468lx; Swift34.01111700601718lx.
Exact raw rows are in evidence/sweep-rows/*.csv.

## Reproduction

From repository root, build the package with Swift5.9+ (measured Swift6.0.3):

```sh
swift build --jobs 1
build_path=$(swift build --show-bin-path)
swiftc -I "$build_path/Modules" docs/parallel/02/reference/production_probe.swift \
  "$build_path"/LightingCore.build/*.swift.o -o /tmp/keyfill-photometry-probe
python3 docs/parallel/02/reference/reference_sweep.py --fixtures /tmp/keyfill-fixtures.json
/tmp/keyfill-photometry-probe /tmp/keyfill-fixtures.json > /tmp/keyfill-actual.json
python3 docs/parallel/02/reference/reference_sweep.py --actual /tmp/keyfill-actual.json \
  --report /tmp/keyfill-reference-report.json
```

Temporary outputs are private to the invocation; choose unique paths for
parallel runs. Module/object paths shown are SwiftPM layouts measured on Linux;
this executable is not an Apple GPU or device test.

## Color references and limits

Production retains the Wyman/Sloan/Shirley analytic observer approximation,
380–780nm at5nm steps, normalized to photopicY=1. Worker CIE references integrate
the separately published1nm CIE1931 2° table over360–830nm, using Planck's law.
Observer approximation and integration-range error remain distinct from finite
arithmetic defects. White balance is ideal Bradford adaptation; relative
exposure must preserve lux and incidentXYZ. Neither CCT nor ideal blackbody
spectra establish LED color rendering or camera spectral response.

Primary sources:

- [PBRT4e, Working with Radiometric Integrals](https://pbr-book.org/4ed/Radiometry,_Spectra,_and_Color/Working_with_Radiometric_Integrals), area/projected-solid-angle definitions. Edge identity above is explicitly derived here.
- [Wyman, Sloan & Shirley2013](https://jcgt.org/published/0002/02/01/), analytic CIE matching-function approximation.
- [CIE1931 2° dataset](https://www.cie.co.at/datatable/cie-1931-colour-matching-functions-2-degree-observer), CIE2019, DOI10.25039/CIE.DS.xvudnb9b, CC BY-SA4.0. Download metadata and checksum are recorded with derived reference tables; production source does not embed the table.
- [W3C CSS Color4](https://www.w3.org/TR/2026/CRD-css-color-4-20261008/), independent color-conversion/Bradford conventions.
