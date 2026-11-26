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

## Interrupted review follow-up

W02R08 executed a standalone Swift probe of all four error descriptions. All
are fixed literals without private-value interpolation. It found a clear action
for invalidTargetLux, and requested more specific recovery steps for invalidLight,
unsupportedGeometry and outputOutOfRange. This is a source-text finding, not a
native accessibility audit. No further wording changes were made after the
execution environment became unavailable; review during the remaining solver/
consumer waves. The returned assessment is retained in
reports/w02/w02r08/recovered-handoff.md; original local probe files were not
verified recovered remotely.

## Resumed lane 01 contract inspection

Inspected lane 01 commit `966c9c21adbb685d82127e7f88981b74daf47e3d`,
`docs/parallel/01/INTERFACES.md` and its handoff. Both lanes retain baseline
f150f98. Its target-lux admission requires the exact light UUID and snapshot,
plus live presentation/generation/revision ownership. Lane 02 returns a new
valid light, preserving identity and all non-output fields; source and scene
remain unchanged. No new signature/schema is needed. Native route admission
is still pending in lane 01; this is compatibility review, not an acknowledgement
or claim that the route integration has shipped.

W03R06 found that constant numeric-kernel work must not be generalized to the
whole `StudioLight.isValid` wrapper: trimming/counting arbitrary names depends
on input bytes, and an 80-grapheme bound is not a byte bound. Lane 01 already
plans typed scalar commands that avoid revalidating unchanged imported names.
Retain complete validation for imported/adopted scenes and consider an explicit
byte bound only in the schema/validation owner's change. No Scene.swift edit here.

Current-source CI45819324337 simulator and app-accessibility jobs fail the same
inherited ambiguous `.greatestFiniteMagnitude` test compilation; original excerpts
are retained under evidence/ci-current-139909706814-failure-excerpts.log and
ci-current-139909706998-failure-excerpts.log. Core remains successful. Later-main
CGFloat correction remains an integration dependency, not a lane02 code fix.
