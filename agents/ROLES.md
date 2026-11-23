# Agent workstreams

Assign real workers only if the runtime supports them; otherwise use these as sequential review lenses. Suggested parallel execution: 3–6 nonconflicting work packets per wave, with one integration lead; increase only if measured throughput improves. Never claim a worker count from a role list.

| Role | Ownership | Mandatory review |
|---|---|---|
| Product lead | product scope, customer interviews, pricing hypotheses | demand evidence and time-to-value |
| iOS architect | dependency graph, Swift concurrency, persistence | lifecycle, migration, cancellation |
| Rendering engineer | scene graph, Metal/RealityKit, materials, shadows | GPU profiling and golden scenes |
| Photometry engineer | source geometry, irradiance, exposure, color | analytic fixtures and calibrated captures |
| Reference inference engineer | Vision/Core ML, hypotheses, confidence | held-out references and abstention |
| AR engineer | ARKit anchors, transforms, RoomPlan fallback | physical-device placement and tracking |
| Interaction designer | editing, undo, inspector, gestures | task success and accessibility |
| Camera/export engineer | image import, comparison, sharing diagrams | orientation, permissions, file integrity |
| Commerce engineer | StoreKit 2, restore, entitlements | sandbox failure and refund cases |
| Privacy/security reviewer | data flow, permissions, secret handling | threat model and deletion |
| QA/performance reviewer | regression suite, device matrix, metrics | failure injection and independent rerun |
| Release lead | TestFlight, launch checklist, CI evidence | traceability and owner signoff |

Wave order: product/architecture and fixture contracts; core domain; rendering; editing/persistence; reference analysis; AR/export; commerce; hardening; customer beta; release review. Split tasks inside a wave only where dependency and file ownership permit. Do not skip gates or serialize unnecessarily.
