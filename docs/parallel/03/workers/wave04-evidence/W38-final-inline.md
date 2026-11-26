## W38 — Accessibility/privacy static review

**Runtime ID and canonical path:** `/root/wave04/accessibility_privacy`
**Input:** `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`
**Result:** The inspected clipped-exit error route preserves meaningful camera guidance and cannot publish an unsupported-pixel warning. This is a bounded source finding, not native accessibility acceptance.

### Findings

- `StudyPreviewPipeline` maps `.invalidCamera` to **“Move the camera above the panel and away from the subject.”** It publishes `image: nil`, `unsupportedPixels: 0`, and no backend label. The view then presents **“Study unavailable,”** the explanation, and **“Retry light study.”** These are actual visible `Text`/`Button` contents, not identifiers alone. The decorative error icon is accessibility-hidden; retry has a 44-point minimum height and the error content sits in a `ScrollView`.
- Successful current frames with positive unsupported counts present **“N unsupported pixels (magenta). Move the lights farther away.”** A warning triangle accompanies the text. Status therefore has count, words, and icon cues beyond color. The image has a descriptive accessibility label; a previous image additionally announces **“Previous render…”**, while progress has label **“Updating light study”** and value **“Showing the previous scene.”**
- In `PortraitStudyRenderer`, a nearest geometric face facing away from the camera throws `.invalidCamera` **outside and before** the `catch StudyError.invalidSurface` block that increments the mask/count. This remains true with zero lights: no emitter evaluation occurs before that rejection. The wrapper propagates the thrown error without retaining a completed image. Thus **the clipped-exit condition detected by this pinned source cannot become a near-emitter warning**.
- Genuine emitter rejection occurs through the area-separation guard or point-sample squared distance `< 0.0025`, producing `.invalidSurface`, a mask byte, magenta pixels, and a count. However, `.invalidSurface` also covers normal/display failures; the UI wording alone does not prove an emitter caused every unsupported pixel. Root’s additional camera-depth refinement was unavailable and was not reviewed.

### Privacy

The reviewed path receives scene parameters and a synthetic subject, produces RGBA data, and displays constant descriptive strings. No photo input, persistence, upload, identity inference, or identifying UI interpolation was found. The reviewed cache-key code removes light display names. UUID request tickets serve cancellation/publication ordering. This is source-scoped evidence, not observed runtime storage or transport behavior.

### Evidence

Immutable GitHub blobs:

| Source | Blob SHA |
|---|---|
| `App/ReferenceStudyPreview.swift` | `4b1e283efcb65e890e439c05cacd93fdac293a41` |
| `Sources/LightingCore/PortraitStudy.swift` | `8784480e13099dffbffaad8c8e9ad837316e5ab9` |
| `Sources/LightingCore/CameraFraming.swift` | `7d2c50105bda390ca49cdaa75711380cc5047ae7` |
| `Sources/LightingCore/ReferenceStudy.swift` | `ace5e59027b6a05484e129be233928b85a3e7a7b` |
| `App/MetalStudyRenderer.swift` — engine excerpt | `a1d60cd94d0b016bb7e06e5e1a8ad7231135865d` |

Seven JS source assertions matched; a separate position assertion confirmed camera rejection precedes the mask-catching block. Bounded privacy API scans found no matches. These are static checks, not compiled tests.

**Limitations:** Execution unavailable; precreated private tree `/tmp/keyfill03-7f4b/workers/W38-accessibility-privacy` was not verified. No builds, native VoiceOver/layout checks, mutation, or persistence performed. Mandatory protocols and bounded startup documents were read; local status and agent-cycle commands remained unavailable. Return this report for parent preservation at `docs/parallel/03/workers/W38-accessibility-privacy.md`.
