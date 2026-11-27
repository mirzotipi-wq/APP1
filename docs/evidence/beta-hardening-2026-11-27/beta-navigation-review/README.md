# A089 — remaining beta route geometry preflight

No fixed-navigation misclassification was found. `closeBetaFeedback` belongs to the Form heading, so the scrolling path is appropriate. Preview Back, recovery Done and alert actions explicitly select the fixed-control path. Their enabled-state, live hittability, 44-point target and application-frame checks remain in place.

Compiled the actual `StudioViewportGeometry.swift` with an isolated synthetic witness on Linux Swift 6.0.3. Compilation and execution exited zero; 15 assertions passed. Cases covered Form Close with/without keyboard and assistant strip, partial keyboard/horizontal clipping, lazy search, fixed Back/Done requiring the fixed path, and foreground report ownership versus covered undo controls. No shared SwiftPM build was used.

## Unverified recovery boundary

The adapter recognizes `undo` and `projectLibraryDone` as fixed clipping obstacles, but not `closeLibraryRecovery`. The recovery view uses `safeAreaInset`; its actual Form frame and live target hittability have not been captured by this worker. A deliberately hypothetical full-height Form plus overlapping footer shows the geometry helper has no implicit knowledge of that footer. This is not a confirmed app or harness defect, and no fix is proposed without the actual hierarchy. Inspect those frames when the fresh beta accessibility route reaches recovery.

## Evidence limits

All witness frames are synthetic, not historical or new native snapshots. No Apple build, UI method, tap, keyboard transition, screenshot gate or beta acceptance is claimed. The exact source hashes and commands are in `receipt.json`. Keep `main.swift`, `compile.log`, `probe.log` and this receipt; the `probe` executable is reproducible scratch output and should not be committed.
