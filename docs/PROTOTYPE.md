# Prototype 0.1 — native studio

This prototype is intended as a usable single-project lighting editor on iOS 17+. It is not a release candidate.

- Choose one of four editable portrait recipes, select lights in the plan or rack, edit position, intensity and temperature, add/remove lights, undo/redo and save.
- Switch Plan / 3D / Camera to inspect illustrative geometry in a native SceneKit viewport; tap the camera marker to edit its position and 14–200 mm full-frame lens. Coverage and field-of-view values use the tested ideal projection model.
- Choose bare point, directional or rectangular softbox, adjust aim target and modifier dimensions, view ideal direct lux on the camera-facing subject plane. Overhead view displays aim and footprints. Source types and lens settings participate in undo/redo and versioned local saves.
- Open Light meter & test card for combined direct lux, ideal 18% neutral-card color, balance and relative exposure. Controls change the diagnostic card only, not SceneKit shading.
- The intensity mapping is artistic; it is not calibrated. SceneKit is a temporary adapter; production RealityKit/Metal remains the target.
- Share text settings via the system share sheet. Corrupt saved data blocks writes.
- Charcoal workspace, amber selection, one-meter grid, readable system surfaces, visible units, native navigation and accessibility labels.

Open Actions > iOS Prototype. The Ubuntu job runs portable debug/release tests and native Swift syntax parsing; the macOS job retains package tests, generates the Xcode project, builds unsigned Debug and Release simulator configurations, runs UI smoke and exports XCTest attachments and logs. Download the simulator app artifact after a successful build; unzip the archive and use xcrun simctl install booted KeyAndFill.app.

The simulator app is not a signed IPA. Native build and UI smoke are unverified until CI completes. Reference inference, calibrated rendering, AR, PDF export, project library, commerce, manual accessibility and real-device tests remain outstanding.


### Numerical lighting study
Choose Study to render a neutral sphere and panel from the current camera. Emitter geometry, aiming, finite-source visibility, output, color temperature, relative white balance/exposure and lens affect the image. This is an ideal diagnostic direct-light simulation, not a calibrated portrait or camera exposure. The backend label identifies CPU reference or Metal compute. A device must pass six runtime parity fixtures before Metal is selected; CPU fallback remains available. Unsupported surface samples are marked magenta and counted. Native UI execution is pending.
