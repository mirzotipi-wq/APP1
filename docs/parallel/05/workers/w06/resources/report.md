# Wave06 lane05 — resource lifecycle

Reviewer: `/root/w06_acceptance/resources`  
Frozen source: `bc08f3b8cd72b9d40bf86ea42a132c685b69d6d9`  
Candidate: `e66319bf8ee54925ae2121154adfbc4a6bbd099c`

Read AGENTS, architecture/design, both adapters and matching tests. Source review only.

**Concrete trace:** one selected rectangular UUID, fixed 1.2 × 0.7 m dimensions and 2.1 m height; valid aim → coincident aim → valid aim → zero candela.

| Resource | Coincident aim | Valid recovery | Zero candela with valid aim |
|---|---|---|---|
| SceneKit fixture/source/stand/indicator nodes and existing shapes | Retained | Retained | Retained |
| SceneKit attached `SCNLight` | Set to nil | Newly constructed | Retained, intensity zero |
| RealityKit lamp entities and shared meshes/shapes | Retained | Retained | Retained |
| RealityKit authored light components | Both types removed | New spotlight component set if shading eligible | Both types removed |

SceneKit creates lamp nodes only for a missing UUID. Fixture/outline shapes change initially, on kind changes, or rectangle dimension changes. The cylinder is created lazily above y > 0.05, detached at/below that threshold, and reused when raised. Aim/output changes mutate pose/material properties without replacing these shapes. For this single-light trace, ambient intensity also becomes zero at coincidence/off. [S]

RealityKit constructs box/sphere meshes and collision shapes once per graph; lamp construction creates the hierarchy and 12 outline entities. Aim changes mutate transforms/enabled flags; coincidence disables face/aim markers. `sourceChanged`—position/optics/subject, candela, Kelvin, or shading eligibility—constructs replacement face/point materials and sets/removes light components. Only the first seven eligible emitters receive components; the neutral display fill remains. [R]

UUID deletion or whole-scene validation failure removes lamp hierarchies in both adapters. SceneKit dismantling additionally clears base nodes; RealityKit rejection disables its anchor while retaining base resources. [S, R]

Candidate changes rectangle `face.scale` and adds one recovery test; allocation policy is unchanged. Its `SpatialAimRecoveryTests` asserts retained nodes/shapes plus nil→spot recovery. Frozen `SpatialEntityUpdateTests` covers zero-output identity and stand reuse. Assertions were inspected, not executed; RealityKit runtime remains unverified. No allocation, memory, frame-rate, or performance measurements were made.

**Source anchors:** [S] `App/SpatialPreview.swift` 95–133, 232–236, 344–460, 475–481. [R] `App/StudioEntityGraph.swift` 12–20, 55–77, 100–121, 170–343.
