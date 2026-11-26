# Integration and owner requests

## Lane 01 — composition

The three viewport adapters retain existing call sites. A distinct project/session identity is not currently an input to either renderer. Current callbacks are refreshed on each representable update. If composition retains the same representable across project replacement using overlapping light UUIDs, provide a stable project generation (or view identity) so in-flight gestures can be canceled across that boundary. Lane 05 will reject detached/deleted hit objects and changes it can observe without changing scene schema.

## Lane 06 — core geometry

`StudioSceneBounds` explicitly excludes stand bases, subject body and housing. Lane 05 must include its own represented equipment in Fit without redefining the core/Plan bounds contract. Viewport-only helpers will consume `StudioSceneBounds`, `EmitterFrame` and `CameraFraming`; no core geometry file is modified. Preserve right-handed meter coordinates, emitter +Z and camera -Z conventions.

## Lanes 19/20 — native execution and baseline

The requested `f150f98` baseline contains a known unrelated Swift ambiguity in `UITests/StudioAppAccessibilityUITests.swift` (`greatestFiniteMagnitude`). Current main has the explicit-`CGFloat` repair in `b0d25ee`. Keep this repair when integrating and testing the viewport branch; do not weaken or remove that test. Lane 05 source changes need current Apple compilation and SceneKit runtime regressions; Linux/source-only checks cannot satisfy those claims. Existing CI is used unchanged.

## Evidence boundary

No new physical-device, manual VoiceOver, thermal or photographic calibration evidence is claimed. Original acceptance thresholds, failed histories and other workstreams' ownership remain intact.
