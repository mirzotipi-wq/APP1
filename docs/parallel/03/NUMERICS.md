# Tiny-output CPU correction

The Study now integrates positive emitters with subnormal per-sample candela at unit intensity and restores their output once per emitter. Rectangle sampling remains bounded at 64/1024 samples. Ordinary emitter accumulation keeps its previous arithmetic and order. The private scale is not added to the GPU ABI: packing restores candela before conversion to Float32.

The unchanged W42 probe was compiled and executed with Swift 6.2.1 on Linux. Original code failed 56 of 166 checks; the correction passed all 166. Five XCTest methods cover point/directional grazing material response, full and clipped rectangles at both qualities, mixed emitter order, positive-tiny near-field rejection versus true zero, and exact packed rows. The complete current portable suite passed 391 Debug and 391 optimized Release tests.

Release used per-file optimization (-O, no whole-module optimization) and one compiler process after the ordinary build was killed by signal 9. Original failed/empty retry logs and the test-only ambiguous-pow compile failure are retained. Explicitly typing that analytic constant as Double resolved the compile error without altering production arithmetic.

## Scope of the numerical result

This repairs early intensity underflow when rounded candela/sampleCount is below Double.leastNormalMagnitude. It preserves a finite, nondegenerate unit-intensity evaluation. It does not promise exactness for every positive binary64 input. Normal sample intensity followed by an extremely grazing cosine or clipped weight can still underflow. Final subnormal quantization remains unavoidable.

W50 preserved copied-arithmetic witnesses for inherited half-vector normalization underflow and a separately overflowing extreme BRDF intermediate. Those are Python challenges, not actual Swift reproductions. They require a separate bounded reproduction before changing geometric or material math. The current patch does not change these paths. See workers/W50-independent-review.md and its evidence for values and proof levels.

Tiny positive Double output can pack to Float32 zero and display as RGB8 black. Positive tiny sources nevertheless retain their geometric guards and invalid masks. True-zero sources retain the existing inactive-light behavior. The frozen six parity fixtures, eight precision cases and required image scenes remain unchanged.

No lane02 photometry, lane04 engine/cache, shared composition or CI implementation was edited. Lane02 requested this numerical review; W47 recorded both owners' exact contract receipts. Lane04's separate width24 silhouette counterexample remains open and is not hidden by this correction.

