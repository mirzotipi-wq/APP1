# W06 independent exact-patch review

Reviewer: `/root/w06_acceptance/independent_review`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`  
Commits: `d112069f8c4fa4a1770c130fe6c8491fe9c21817` → `e66319bf8ee54925ae2121154adfbc4a6bbd099c`

**APPROVE for source integration. No concrete required revision to this exact patch.**

The supplied aggregate matches the commit-chain diff byte-for-byte, with exactly two changed paths and one new test method. Captured sources match the private writer tree; `git diff --check` passes. No implementation files were edited.

Independently checked Core's contract: `StudioSceneBounds.swift:3–6,27–34` defines emitting-face corners, explicitly excluding housing; `StudioOptics.swift:131–136` passes the same dimensions to the photometric rectangle. `LightOptics.dimensionRange` is 0.05…4 m, enforced before graph updates. With `generateBox(size: 1)`, the corrected rectangle scale supplies those full extents. The former 1.2×0.7 m face lost 2.697143% area; the 0.05 m square lost 42.24%. Directional inset, face depth 0.006 m, center z=−0.003, front plane, frame/roll and source orientation are byte-unchanged. The existing viewport envelope includes half-width/height plus 0.03 m and z=−0.15…0.08, enclosing the enlarged face throughout the valid dimension range.

The literal test bases are correct: −Z/+90° gives fixture right/up = +Y/+X; +Y/−90° gives +Z/+X. Source right reverses while local −Z still maps to the emitting normal. Assertions retain UUID resolution, child identities, fixture/outline/stand geometry and selection through coincidence, require actual light removal, then check restored spotlight pose/output and translated stand position. Existing 2e−5 m position and 1e−6 axis/dimension tolerances are preserved. `project.yml` includes `NativeTests` in `KeyAndFillTests` and the test scheme.

Evidence limits remain explicit: the geometry witness uses scalar formulas, its recovery trace is source interpretation, and its Float errors exclude native quaternion/transform arithmetic. The comparison table's rectangle row omits the former RealityKit housing/face distinction and SceneKit's 0.012 m chamfer: outer box dimensions/front-center anchors do not establish tessellated flat-face corner parity with Core. This SceneKit recovery test does not execute the RealityKit scale correction; historical native passes do not execute this candidate. Native tests, compilation and type checking are **UNRUN**; no RealityKit visual, calibration or performance acceptance is claimed.
