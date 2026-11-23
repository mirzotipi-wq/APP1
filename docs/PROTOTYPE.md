# Prototype 0.1 — native studio

This prototype is intended as a usable single-project lighting editor on iOS 17+. It is not a release candidate.

- Choose one of four editable portrait recipes, select lights in the plan or rack, edit position, intensity and temperature, add/remove lights, undo/redo and save.
- Switch Plan / 3D to inspect illustrative geometry in a native SceneKit viewport. The intensity mapping is artistic; it is not calibrated. SceneKit is a temporary adapter; production RealityKit/Metal remains the target.
- Share text settings via the system share sheet. Corrupt saved data blocks writes.
- Charcoal workspace, amber selection, one-meter grid, readable system surfaces, visible units, native navigation and accessibility labels.

Open Actions > iOS Prototype. The macOS workflow runs package tests, generates the Xcode project, builds the unsigned simulator app, exercises the UI and uploads test evidence. Download the simulator app artifact after a successful build; unzip the archive and use xcrun simctl install booted KeyAndFill.app.

The simulator app is not a signed IPA. Native build and UI smoke are unverified until CI completes. Reference inference, calibrated rendering, AR, PDF export, project library, commerce, manual accessibility and real-device tests remain outstanding.
