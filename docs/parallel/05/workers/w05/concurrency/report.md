# Wave 05 — concurrency review

Worker: `/root/w05_acceptance/concurrency`  
Frozen input: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`  
Disposition: no concrete ordering defect found; source review only.

One bounded review covered late selection against scene replacement/deletion, disabled or inactive state, window removal, invalid input, and camera/orbit transitions. Read pinned GitHub files plus lane 05 PLAN; no source edits, builds, or test execution.

Both coordinators and their update/gesture methods are MainActor-isolated and synchronous. Selection resolves the current hit and invokes the current callback without an intervening suspension. SceneKit refreshes `onSelect` before its geometry-equality return (`App/SpatialPreview.swift:204–213`); RealityKit refreshes before graph update, whose own equality return therefore cannot retain an old callback (`App/RealityStudioPreview.swift:189–205`).

Changed UUID sets cancel gestures before graph reconciliation. Invalid SceneKit content disables interaction, clears callbacks/equipment, and resets the scene; RealityKit clears `currentScene` and disables interaction; graph bounds failure independently clears ownership. SceneKit publishes the valid camera mode before computing interaction availability, clears the camera-mode callback immediately, and refreshes gesture dependencies after changing camera control (`SpatialPreview.swift:223–250`). Its environment gate follows `updateView` synchronously, so a queued tap cannot execute between those two calls.

Delivery checks current enabled/content/mode/window state in SceneKit (`SpatialPreview.swift:136–145`) and rendering/enabled/current-scene/window state in RealityKit (`RealityStudioPreview.swift:154–186,273–278`). RealityKit window removal also detaches anchors and cancels gestures; both dismantlers remove targets and callbacks. Ownership resolvers reject removed/detached equipment (`SpatialPreview.swift:150–162`; `App/StudioEntityGraph.swift:100–136`). A direct resolver call is only identity resolution: it does not prove a gesture callback can run while disabled or outside a window.

Same-UUID project generation protection was outside this bounded check, as independently reviewed by the parent. Native residual: exercise pending taps through UUID changes, window removal/reattachment, and competing camera gestures on Apple platforms. No native, RealityKit, VoiceOver, or performance execution is claimed; the supplied 180-native/34-spatial counts are discovered coverage only.

