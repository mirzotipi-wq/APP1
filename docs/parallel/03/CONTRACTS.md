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

## Received owner notes

The published lane 01 `INTERFACES.md` keeps asynchronous feature ownership with
presentation/project/revision identities. Lane 03's preview does not mutate the
scene or adopt a feature result into editing history; its public scene/subject
call remains unchanged.

Lane 02 `CONSUMER-REQUESTS.md` identifies possible subnormal per-cell candela
underflow in Study sampling. Review this separately from ordinary-range image
behavior. Any correction must preserve GPU sample semantics and unsupported masks;
no meter change is copied into Study without its own evidence.

Lane 04 `OWNER_REQUESTS.md` at `9d8bb0b` reports a host Float32 silhouette mismatch
at width 24 and focal length 161.27198111190464 mm for an unlit sphere. Its initial
reference is a C++ Double transcription. Lane 03 will supply a shipped Swift
reference probe during fixture synchronization. Width-aware eligibility belongs
to lane 04. The note confirms existing preview task-cancellation guards; adding
controlled completion tests is a coverage improvement, not proof of a current
stale-frame bug.

Lanes 02 and 04 also identify later main's native CGFloat correction `b0d25ee`.
It is outside this lane's source ownership and remains for integration. A native
failure on the fallback baseline must retain that exact provenance.
