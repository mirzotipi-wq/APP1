# W10 interactions — bounded review

Source: `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; documentation: `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`. Inspected interaction source/tests and receipts; actually viewed all three original PNGs. No builds, installs, native execution or integration edits.

**Visual findings.** In `docs/parallel/05/captures/ordinary-4e694bc.png` and `crowded-4e694bc.png`, represented rigs remain inside the frame. Crowded foreground panels occlude the bust and other fixtures; the rightmost selected rectangle has a visible outline. Thin stands, dark floor and small camera remain difficult to distinguish. The ordinary selected-point cue is subtle at this scale.

Root’s newer `captures/full-app-fit-feet-60059a0.png` and `receipt-full-app-60059a0.json` show selected 3D with a checkmark, the ordinary rig and readable preview note. Fit/footer is partly covered at the captured scroll position; the test tapped Fit earlier, so this frame does not demonstrate an unreachable control. All PNG hashes match their receipts.

**Execution boundary.** Predecessor `validation/NATIVE-4e694bc.md` establishes 184/38 native/spatial passes. Current 185/39 remains inventory: root’s 16:40:42 UTC observation still has native execution in progress; historical 16:23:18 and 16:30:01 pending observations remain preserved. Current studio-export accounting is nine passes/one failure. Passed `StudioSmokeTests.testSettingsFeet3DFitAndSimulatorARManualFallback` (`UITests/StudioSmokeTests.swift`, 62–137) taps 3D/Fit and checks selected mode/manual feet, without camera-pose assertions or orbit/pan/pinch delivery. Native Fit/selection tests manipulate cameras and callbacks directly.

**Disposition/dependencies.** No new demonstrated source defect warrants an edit. On a supported RealityKit runtime/device, record before/after Fit poses; deliver one-finger orbit, two-finger pan, pinch and selection taps in ordinary/crowded rigs; verify foreground-hit behavior, selection/list agreement and preview-versus-parent scrolling in both orientations. Lane 01 must integrate its presentation identity change, then verify first-save retention and replacement with overlapping UUIDs. Check manual VoiceOver and maximum Dynamic Type separately.

Four executor interruptions and wave-01 summary-only recovery remain explicit. No deallocation, renderer-thread atomicity, FPS/device or manual-accessibility acceptance claim is made. Detailed paths/provenance are in `evidence.json`.
