# Consumer coordination — lane 02

No scene-schema or public-signature changes are proposed. All calculations stay
pure, synchronous, value based and Sendable. Existing Optional/throw contracts,
SI units and ordinary preview compute parameters remain intact.

| Owner | Request | Reason / acceptance |
|---|---|---|
| 01 architecture | Keep point, directional and rectangle identities; `directional` means finite-distance one-sided cosine emission, not a parallel beam. Preserve nil as unsupported, zero as supported darkness. | Existing authored-scene contract; don't change intensity units or use RGB as lux. |
| 01 shared helper | Review Scene.swift `normalIlluminance(candela:100000,distanceMeters:1e155)`: r² overflow returns0 although1e-305 is representable. | Public helper admits this distance; scene positions cannot reach it. Prefer division ordering or explicit distance-domain bound. Source outside lane02 ownership; not changed here. |
| CPU / GPU rendering | Review per-cell intensity underflow in ReferenceStudy.swift; meter now integrates tiny output at1cd then scales once, while ordinary meter/renderer ordering is preserved. | Extreme subnormal output only; no physical brightness claim. Do not remove invalid masks or replace independent rendering gates with diagnostic meter agreement. |
| CPU / GPU color | Colorimetry finite huge XYZ path analytically cancels scale before tone mapping; normal-range arithmetic and computeParameters stay identical. | GPU Float32 input eligibility must remain explicit; huge Double API inputs are not an expanded Float32 rendering domain. |
| inference | Solve each light's contribution independently; target lux is not total rig lux or a measured lamp setting. Check forward result and return uncertainty. | One-to-three-source additivity before display; no inverse-photo reconstruction claim. |
| inspector / accessibility | Present `LightOutputAdjustmentError` localized descriptions and keep rejected targets editable. Treat .outputOutOfRange as either physical output range or unrepresentable numerical accuracy. | Error string now explains both; retain labels/units and non-color-only unsupported state. |
| export | Preserve SI / camera-facing receiver assumptions, explicit unsupported states and ideal-model disclaimer. | No schema fields or physical calibration claims added. |
| 19 CI / 20 integration | This branch is based on requested f150f98; retain later main b0d25ee native CGFloat measurement fix during integration. | Native baseline build failure was already documented on main9e0e2ba; lane02 does not own App source or CI. |

## Numerical regression semantics

The old rectangle test expected the smallest-positive-lux target to fail because
per-cell division erased its output. With integration at unit intensity that
target is actually attainable and must forward-evaluate to that exact positive
Double. The test now asserts exact achieved lux. A separate5cm point fixture
retains rejection of a truly unrepresentable positive target whose required
candela is smaller than Double.leastNonzeroMagnitude. No tolerance was loosened;
maximum.nextUp rejection, zero-off behavior, source validity and1e-9 forward
solver acceptance are unchanged. The original failed expectation is retained
in evidence/candidate-obsolete-underflow-expectation.log.
