# Lane 03 integration contracts

## Lane 01 — composition

The public `ReferenceStudyPreview(scene:subject:)` entry point will remain usable
without StudioView wiring changes. Preview request/generation state stays with
the preview. Study subject selection remains session-only and does not modify a
saved scene. Any new shared composition request will be recorded here before use.

## Lane 02 — numerical model

Retain SI coordinates, light frames, existing color transforms, guarded near-field
semantics and material definitions. The verified near-tangent defect is within
`PortraitHeadMesh` intersection geometry. It does not require changes to
`SurfacePhotometry`, `Colorimetry`, `LightOutputAdjustment` or `StudioOptics`.
Changes to direct-light sampling or response require explicit fixture evidence
and an updated contract note; do not silently alter the diagnostic meter model.

## Lane 04 — GPU and cache

The sphere packed ABI remains six parameter rows, three rows per light sample and
three rows per area, with the existing camera-relative Float32 semantics. Keep the
six parity scenes, eight precision scenes, exact per-pixel masks and current error
limits. Mannequin stays CPU-only at width <=144. Lane 03 will not edit the shared
Metal kernel, backend routing or cache implementation. Geometry-only fixes must
not be represented as mannequin Metal parity.

## Lane 19 — tooling and native execution

No CI files are edited by this lane. The final handoff will list new source-specific
native tests requiring execution and any test-inventory or tooling requests.
Portable evidence probes under this lane's evidence directory are reproducible
diagnostics, not replacements for native execution or changes to acceptance gates.

## Lane 20 — integration

Only this feature branch is pushed. Merge with newer main changes under the campaign
integration owner; retain original failures and exact source/test provenance.
Lane 03 reports its evidence without promoting canonical milestones.
