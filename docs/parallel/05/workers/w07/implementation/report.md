# Wave07 implementation review

Source: `4e694bc377c4825d1d2dd52fcd7900e534c75072`; tree: `0f090891cb010ca03ef105fad808878b23f2eb16`. Read-only pinned-source review; no builds, probes or edits.

**Finding: no additional reproducible defect established.**

`App/SpatialPreview.swift:updateView` differs from tested 9725 only in guarding the early `lastCameraMode` assignment. Source tracing supports the existing repair: Orbit/Fit=0 → Camera (defined or unavailable) → invalid Orbit → valid Orbit/Fit=0 retains the last applied Camera mode until recovery, so `needsFit` remains true. `SpatialNavigationRecoveryTests` covers both variants, preserved user camera/target after same-mode invalid recovery, and initial empty-rig interaction.

Reviewed invariants:

- Invalid input hides content, disables interaction, clears callbacks/hit maps and detaches equipment; it consumes neither mode nor Fit. Valid recovery rebuilds equipment.
- Valid Orbit publishes its mode before deriving availability, including an empty rig. Same-mode recovery without a new Fit preserves the active camera/target. Camera mode suppresses interaction; unavailable framing clears `pointOfView`; valid framing restores the authored pose/lens.
- Identical scene/mode/selection/Fit refreshes or clears `onSelect` before the early return, preserving equipment and Orbit. Deletion/invalidity followed by the same UUID creates new nodes; `Coordinator.lightID(for:)` rejects detached old nodes. `SpatialSelectionLifetimeTests` directly exercises these boundaries, not delivered gestures.
- `updateContent` retains same-shape equipment through coincident aim, removes `source.light`, then restores its position/orientation/light on valid aim. `SpatialAimRecoveryTests` checks translated cardinal axes independently of the frame helper.

Evidence: `docs/parallel/05/validation/NATIVE-9725fb1.md` records 176 native/30 spatial passes and Debug/Release builds at 9725. The newer four navigation, three selection and one aim methods remain unexecuted in reviewed evidence. No RealityKit, device, VoiceOver, gesture-delivery or performance conclusion follows. Existing lane01 identity request remains unchanged.

Input blob SHAs:

- `App/SpatialPreview.swift`: `c2dd825e406c505ded8291120bc4121f7bf35b79` (9725: `86c7260b3532e00b08f11dc67731ede95bd2fe3a`).
- `NativeTests/SpatialNavigationRecoveryTests.swift`: `b3077e5f6c3d10e129dce4af78e71550419ed25a`.
- `NativeTests/SpatialSelectionLifetimeTests.swift`: `dcd46df3662461dc6ea3ec9a52c6a12fd1ad2635`.
- `NativeTests/SpatialAimRecoveryTests.swift`: `6fe6d784ed999ca193bea7cac1d946d2486dfa9d`.
