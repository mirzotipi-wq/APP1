# Wave 05 — independent review

Worker: `/root/w05_acceptance/independent_review`  
Frozen input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`  
Candidate: `NativeTests/SpatialSelectionLifetimeTests.swift`, exact two-part source supplied by the lead; three test methods.

**Verdict: accept the candidate source without correction.** This is source review only. No file write, commit, compilation, or native execution is established.

Read AGENTS.md, docs/parallel/05/PLAN.md, docs/DESIGN.md, SpatialInteractionTests.swift, SpatialEntityUpdateTests.swift, Scene.swift and [SpatialPreview.swift at the frozen revision](https://github.com/mirzotipi-wq/APP1/blob/deffb5e3c93b507ceb4189a414a4ff0e3cf19395/App/SpatialPreview.swift).

- **Callback coverage:** the initial render establishes the unchanged scene, selected UUID, orbit mode and Fit request 0. Both A→B and B→nil therefore reach the early-return guard with all change predicates false. A is invoked before replacement; subsequent assertions establish B delivery, no further A delivery, and callback removal. Top-level node identities, indicator identity, camera identity, camera position and controller target are checked after both updates. This adds the unchanged-scene replacement/removal case absent from the existing metadata-edit test.
- **Deletion and invalid recovery:** all four original node objects remain strongly retained. Fixture, stand and source roots must detach; the indicator may remain under its detached fixture. Each old object must reject resolution before and after same-UUID reconstruction. Replacement identities differ, all three roots attach to current content, and current fixture/indicator/stand resolve to the UUID with a visible selection indicator. Source attachment is checked without falsely asserting that a source node is selectable.
- **Fixture and typing checks:** the single point light at height 2 produces one omni source and one cylinder, matching the helper filters. Scene validation accepts an empty rig and rejects the duplicated UUID. Closure unwrapping/invocation, Float array comparisons, object-identity checks and MainActor usage are plausible and consistent with existing native tests; this is not compiler evidence.

**Material residuals:** run these three methods on the restored Apple test target and verify target inclusion. Direct callback/resolver calls do not establish actual gesture delivery, VoiceOver behavior, cross-project composition identity, device performance or release readiness. No production change is requested.

