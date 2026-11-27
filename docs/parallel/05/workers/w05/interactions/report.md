# Wave 05 — interactions
Worker: /root/w05_acceptance/interactions. Frozen source: deffb5e3c93b507ceb4189a414a4ff0e3cf19395. Pinned git show review includes AGENTS.md/lane-05 PLAN. No source edits, builds, installation, or native execution.

## Finding
SceneKit consumes only hitTest(...).first. Its resolver walks visible ancestors to a registered fixture/stand directly under content, checking current UUID membership. An indicator reaches its fixture; a first non-equipment hit returns nil without searching behind it (App/SpatialPreview.swift:141,150,367,405).

RealityKit uses entity(at:), then enabled ancestry to the identical registered root under its anchor; the handler rechecks membership (App/RealityStudioPreview.swift:273; App/StudioEntityGraph.swift:127). Only point/housing/stand/feet receive collision components; face/outline/aim markers and subject/camera/floor do not (StudioEntityGraph.swift:25,177,220,243). Resolver success therefore does not prove screen acquisition or depth parity.

Live UUID continuity intentionally preserves roots across edits. Deleted/invalid-scene roots are detached and unregistered; reintroducing their UUID creates replacements (SpatialPreview.swift:232,349; StudioEntityGraph.swift:69,100).

## Coverage
SpatialEntityUpdateTests:47 directly asserts fixture/indicator/stand resolution and stand reuse/detachment. SpatialInteractionTests:19,50,67 directly invokes onSelect and checks removal/recovery identities. The three private SpatialSelectionLifetimeTests methods at 3d5338dc81000d1316c4d966cdb5eb7211ce4622 extend callback refresh/clearing and retained-node rejection. These tests do not deliver taps or establish non-equipment depth behavior.

## Bounded native plan
Root-owned execution: active, attached 360×280-point host, VoiceOver off; separately identify SceneKit simulator and RealityKit-capable physical device. Deliver three XCUI coordinate taps per target.

1. Isolated point/rectangle: body/face, selected outline-only edge outside housing, stand midpoint; additionally RealityKit feet. Record screenshots, acquired ancestry, callback UUID/count. Acquired current equipment requires one callback; nil/non-equipment requires zero.
2. Rectangle successively occluded by subject, camera, and floor: verify projected depth, tap overlap and exposed control. Record whether RealityKit selects through visible non-equipment and whether outline-only taps differ. No parity claim without execution.
3. Repeat body taps after metadata edits, deletion, and same-UUID reinsertion: current selection survives edits, deletion gives zero callbacks, replacement selects once.

Disposition: source review only. Supplied deff discovery: 180 native/34 spatial, unexecuted. Historical 68c83 simulator 171/25 passes and captures are fallback evidence; they do not establish this gesture matrix or RealityKit device execution.
