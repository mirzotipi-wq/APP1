# Independent scalar reference

Emitter: origin, XY plane, right +X, up +Y, width and height 4 m. Receiver: (0,0,1) m, normal (1,0,-1)/sqrt(2). The emitting normal is +Z and the 1 m depth equals the supported minimum. Receiver incidence changes sign across x=-1, so the contributing region is x in (-1,2], y in [-2,2], exactly 75% of the face.

For d=1, a=b=2 and x0=-1, the unit-intensity coefficient is

`C = (Jx + Jz)/(16*sqrt(2))`, where

`Jx = integral integral d*x/(d*d+x*x+y*y)^2 dy dx`

`Jz = integral integral d*d/(d*d+x*x+y*y)^2 dy dx`.

With `F(x) = atan(b/sqrt(d*d+x*x))/sqrt(d*d+x*x)` and `h=sqrt(d*d+b*b)`, direct integration gives `Jx=d*(F(x0)-F(a))`. The planar identity `div((x,y)/(d*d+x*x+y*y))=2*d*d/(d*d+x*x+y*y)^2` gives `Jz=a*F(a)-x0*F(x0)+(b/h)*(atan(a/h)-atan(x0/h))`. This expectation shares no production clipping, triangle quadrature, normal helper, or full-face midpoint grid.

Use `I=8*Double.leastNonzeroMagnitude`. The separately rounded `I/16` is zero, whereas `C*I` rounds to one least-nonzero lux step. Relative error is computed as `abs(actual/expected-1)` to avoid an underflowed absolute tolerance.

## Scalar calculation actually performed

A functions.exec JavaScript Math calculation of the equations above returned:

| Quantity | Value |
|---|---:|
| Jx | 0.34916672997902104 |
| Jz | 2.3570247185911692 |
| C, lx/cd | 0.11959789527956421 |
| I/16 | 0 |
| C*I, least-nonzero lux steps | 1 |

The first Swift attempt was interrupted by executor replacement; execution-status.log preserves that failure. On the restored second executor, the Swift production probe completed successfully against immutable v1. It returned unit intensity 0.11960250634721419 lx, relative error 3.8554755827258091e-05 (0.0038554755827258091%). Tiny actual and expected were both 4.9406564584124654e-324 lx, bit pattern 1, relative error zero. These measured Swift results are retained in probe.log. The XCTest candidate remains unintegrated and was not run as a package test.

The 1% point and 5% area contracts remain unchanged; this ideal software fixture establishes no calibration or physical-device result.
