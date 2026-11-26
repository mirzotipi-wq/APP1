# Wave 08 — Interfaces

Canonical ID: /root/w08_acceptance/interfaces
Input SHA: 4e694bc377c4825d1d2dd52fcd7900e534c75072
Baseline SHA: f150f98e35dd735927075aac4d2f8b02295c6a67
Status: completed_source_review

**No blocking interface defect found.** Reviewed the requested directives and immutable source. Assigned Core files are unchanged from baseline.

**Schema:** Authored coordinates/manual targets must be finite within ±100 m; dimensions are 0.05–4 m, roll ±180° (Scene.swift:4–12,62–80; StudioOptics.swift:16–42). Manual targets translate with equipment; completed transforms revalidate (SceneTransform.swift:119–129,433–435). Derived face corners may exceed ±100 m (StudioSceneBounds.swift:27–34). CameraFraming.project accepts authored positions, not arbitrary derived corners (CameraFraming.swift:71–76).

**Bounds:** Core includes centers, aimed targets and defined emitting faces; it excludes stands/housing (StudioSceneBounds.swift:3–35). App adds bust/camera, point outlines, transformed housing, aim markers and stand bases (SpatialViewportGeometry.swift:25–61). Its local envelope ±(width/2+0.03), ±(height/2+0.03), z=[−0.15,0.08] encloses both adapters’ housings/outlines under arbitrary valid aim/roll (SpatialPreview.swift:379–443; StudioEntityGraph.swift:260–305,348–365). Authored faces remain at local z=0. Floor/grid are excluded.

**Cases:** Empty/sparse rigs retain bust/camera bounds. Translation by (80,0,75) preserves radius while translating center, provided every authored position/target stays valid. Coincident 4×4 m modifiers omit the undefined Core face but retain non-emitting, identity-oriented display housing bounded by ±2.03 m. A 100 m stand includes y=0; vertical translation intentionally changes Fit. Undefined camera direction disables authored preview while orbit remains available (SpatialPreview.swift:223–231,253–265).

**Fit:** d=1.12·max(0.8,r)/sin(24°), using 48° on the smaller viewport axis (SpatialViewportGeometry.swift:88–118; SpatialPreview.swift:274–288; RealityStudioPreview.swift:228–244). Valid equipment gives r<180 m, so the 1500 m cap never truncates Fit; near/far margins encompass it.

Source review only: no builds/tests. Current 184 native/38 spatial are inventory; prior 176/30 does not certify this SHA. CI 45838950713 remains lead-owned.

