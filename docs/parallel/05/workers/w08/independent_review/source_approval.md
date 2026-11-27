# Wave 08 independent source approval

Decision: APPROVE the exact two-file private candidate for integration; no blocking source finding.

Frozen source: 4e694bc377c4825d1d2dd52fcd7900e534c75072.
Patch SHA256: 8fdf2042441591771b1a19b109a2e600758f461bdfb5f33599079991ea77dcbe.
App/SpatialViewportGeometry.swift SHA256: 465edc50d458fcfca860d3ecfdbb0887721150c89692e2a6184afb43fc4c3d94.
NativeTests/SpatialViewportStateTests.swift SHA256: 7a15a02aec47fce75cc87d3a69cb563453a2786352c4042d958fb8925ba3fc0b.

The complete candidate files differ from frozen source only by outward Float field-of-view quantization and one native-state regression. Read AGENTS.md, ARCHITECTURE.md, DESIGN.md and m02-m03-code-v2.

Independent Python standard-library scalar checks confirm all six accepted cases. 360×240 and 600×120 retain exact 48°. 120×600 gives half-angle 24.0000024688° and 1×1000 gives 24.0005316912°. At 0.0003×3000, nearest Float would give 20.5808366887°; one outward ULP gives 36.9060819550°. At 0.0002×3000, nearest Float is already outward and gives 26.5952111183°. At 0.0001×3000, old nearest Float gives only 14.0539879075°; the enclosing Float is 180°, so candidate rejects. Existing 0.00001×1000 rejection remains.

For portrait viewports, nearest Float is retained if at least the ideal Double; otherwise nextUp selects the smallest representable enclosing angle. Accepted angles round-trip through Float without narrowing and remain below 180°. The new test directly checks the returned/uploaded angle, smaller-axis tangent and rejected edge. It fails against old source, including the materially narrowed 0.0003×3000 case and wrongly accepted 0.0001×3000 case.

The sole production caller is RealityStudioPreview.layout(size:); it uploads Float(fieldOfView) and already returns on nil. Landscape output, fit/navigation state, actor ownership, callback lifetime and public API remain unchanged. No new caller regression found.

Limits: these checks model Float32 degree quantization with Double trigonometry; they do not execute Swift, RealityKit, a native camera matrix, or device rendering. The lead reports frozen-source run 45838950713/job 139980771221 successful with 184/184 native methods and 38 spatial, Debug and Release passing; this is not candidate execution. Candidate's added regression is unexecuted at this source-approval point.

Final wave review remains open until all nine other role reports are retained and the lead supplies the final packet.
