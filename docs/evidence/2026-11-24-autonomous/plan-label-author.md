# KF-036: isolated overhead caption candidate

## Status and scope

Candidate only, based on main `5cd7eb4181251d22a3a182c2cb3b04968cf26dd6`. No live repository source, protected contracts, state, evidence ledger or history was edited; no staging, commit or remote write. Integration is not complete. Exact candidate file hashes and the live StudioView source hash are in candidate-manifest.json.

The genuine source-9 recovery screenshot was opened with view_image and the independent visual review read before design. Screenshot path: docs/evidence/2026-11-24-autonomous/source9-library-visual/recovery.png, SHA-256 `4b92de7bad25d72a9322b14911d1dccfa0a084c4e3cff154da96de14355e0919`, 1206x2622 pixels. The observed Light 1 caption partly covers the Fill icon. The old code centers a 34pt icon + 3pt gap + caption VStack at the world point; a 14pt caption therefore also shifts its icon up by 8.5pt. The regression uses the actual four-light recovery geometry and 342x280-point viewport with conservative raster-sized captions to demonstrate both defects. It is not a measurement of UIKit text metrics.

## Implementation

- App/StudioPlanMarkers.swift separates fixed 44pt marker controls from captions. The visible 34pt icon is centered inside that control; its center is therefore the exact unchanged projected point. Subject, camera and light geometry do not move.
- A single @ScaledMetric caption size supplies both UIFont measurement and explicit SwiftUI system-font rendering. This avoids applying Dynamic Type twice. NSString provides actual native string dimensions at runtime, bounded to a 128pt single-line caption; shortened captions have an bounded selected-name fallback.
- Sources/LightingCore/StudioPlanLabelLayout.swift handles at most fourteen markers. It tries eight adjacent placements and a fixed 9x7 fallback grid, ordered deterministically by distance. Captions respect the header reserve, viewport margin, every marker's 44pt rectangle, other captions and a 4pt gap. Selected captions are placed first. Equipment anchors never change.
- Displaced captions use leader lines. If a caption cannot fit, it is omitted rather than clipped onto equipment. Coincident/overlapping equipment remains at its real coordinates; the selected icon draws on top.
- The bounded selected-light display name wraps beneath the viewport. When the retained legacy name differs from its safe display label, a short light ID is visible. A concise notice directs users to the existing light list to select lights in crowded positions when marker controls crowd, captions are shortened or a caption cannot fit.
- App/StudioView.swift retains the original world projection, geometry Canvas, camera action and editCamera accessibility identifier. Light selection still uses the same generation-aware sceneAction closure and selected accessibility trait. Existing storage actors, transaction generations and edit history are untouched. Captions themselves are noninteractive; the fixed 44pt marker controls and existing light list provide selection.

## Actual verification

Toolchain: Swift 6.4.3, x86_64-unknown-linux-gnu. CPU timing worker was consulted before compiling.

- `swift test --jobs 2`: 6/6 portable tests, zero failures, process exit 0. Raw output layout-debug.log.
- `swift test --configuration release --jobs 2`: 6/6 portable tests, zero failures, process exit 0. Raw output layout-release.log.
- `swiftc -frontend -parse App/StudioPlanMarkers.swift App/StudioView.swift`: success. Raw output native-parse.log is empty. Linux parse is not Apple SDK type checking.

Tests cover the demonstrated recovery collision, exact anchor preservation, pairwise caption/marker and caption/caption separation, deterministic layouts over 160/240/342/700-point widths and four text-size cases, fourteen coincident markers with selected-label priority, omitted oversize captions, malformed inputs, count bounds and tiny/empty canvases. The minimal temporary package contains only the new layout helper and its tests, so these results are focused tests rather than the full application suite. The isolated build cache was removed after preserving logs to recover space.

No new UI test was added. The existing successful full-library recovery scenario already captures the affected diagram and can provide the next actual native screenshot after integration.

## Limits and review requirements

Actual UIFont measurement, SwiftUI layout, VoiceOver, pointer/touch handling, UIKit/SwiftUI SDK compilation and new native screenshots were not available locally. Large-text tests use supplied dimensions and verify algorithm behavior; they are not native Dynamic Type screenshots. The helper is a deterministic bounded greedy placement, not an optimal packing solver. Dense layouts may omit unselected captions and show the explicit fallback. Marker overlap is retained as real equipment geometry; it is not cosmetically separated. No performance or accessibility release gate is claimed.

Next: review the four-file candidate, apply it only if the live StudioView hash still matches or integrate the narrow patch, run the full existing portable suite and native SDK checks, then inspect a genuine recovery screenshot and narrow/large-text states. Do not close KF-036 on portable evidence alone.

## Independent copy correction

The independent reviewer found that the original notice promised full names although the light list uses the same bounded display label. Root corrected only that notice to “Use the light list below to select lights in crowded positions.” The selected bounded identity and short legacy ID are unchanged. Focused numerical results predate this copy-only change; no new execution is claimed.
