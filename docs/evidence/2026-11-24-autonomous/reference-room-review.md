# Independent reference and room workflow review — 2026-11-24

Reviewer: real specialist `w06_guided_review`, independent of the guided-basis and room-note implementers. Scope: numerical truthfulness, observation/assumption provenance, committed versus draft measurements, signed coordinate/precision handling, exported data, bounded names and source immutability. This is a source and existing-test-evidence review, not native execution, physical measurement or release approval.

## Outcome

No additional production-blocking defect was established in the reviewed final files. The guided-basis data accurately describes the candidate construction, and the room export captures a read-only text snapshot of the committed validated placement. Native sheet presentation, sharing, accessibility and actual Files/provider behavior remain unverified.

The reviewer observed an intermediate room-name test using more than 80 graphemes, which violates the existing `StudioLight.isValid` rule. The room-core specialist had already corrected that fixture before the review message was received. The final fixture uses a scalar-heavy grapheme with short suffixes, which is valid under the existing scene contract and genuinely exercises bounded display. Do not attribute that pre-existing correction to this reviewer or present the intermediate test issue as a remaining production defect.

## Guided candidate findings

- `GuidedRigBasis.observations` keeps a value copy of the original four categorical answers. Unknown softness, fill and rim remain unknown in both candidates, even where the near/far choices differ. An explicit absence/minimal-fill answer remains distinct from an unknown answer.
- Numeric distance, azimuth, elevation, key-plane lux and source temperature are recorded from the same constants used to construct the candidate. These are chosen model values. The UI labels them as starting values and states that exact geometry, power and color remain assumptions.
- The camera-relative construction uses its right/up/forward orthonormal basis. Its distance is 1.5 or 2.25 m, azimuth is −35/0/+35 degrees, elevation 25 degrees and nominal key illuminance 400 lx; the basis reports these values rather than world yaw or photographic exposure. White balance and exposure remain independent scene preview settings.
- A user saying “Soft edges” or “Restrained fill” supplies a categorical cue, not measured modifier dimensions or a measured 4:1 ratio. API comments and the final UI maintain this distinction. No probability or confidence claim is introduced.
- Changing observations clears the old candidates and selection. Successful photo replacement clears prior guided choices; cancellation retains the prior photo and choices. Applying a selected rig remains an explicit confirmed operation; the candidate retains the source camera, subject, lens and preview settings, and the studio's existing history path handles undo.
- The comparison sheet's study actually uses the default sphere subject, consistent with its neutral-sphere description. No automatic reconstruction or portrait identity claim is introduced.

## Manual room export findings

The existing mapping is an orthogonal horizontal transform:

`X = subjectX + cos(yaw) * deltaX + sin(yaw) * deltaZ`

`Z = subjectZ - sin(yaw) * deltaX + cos(yaw) * deltaZ`

Therefore positive 90 degrees maps scene +Z toward room +X and preserves horizontal distance. The new notes copy the actual validated plan's points and footprints; they do not recompute a different orientation or rescale values. Heights retain their declared studio-floor convention.

- The UI captures `plan.textSummary(locale:)` into an immutable `NotesSnapshot` when Review and share notes is pressed. The preview and ShareLink receive the same string. Neither the notes view nor the formatter holds a mutable scene binding or changes the library.
- Measurement fields keep their draft strings separate from committed room values. The entry point explicitly tells the user to press Set to include a changed entry. Invalid drafts therefore cannot leak into an otherwise valid placement export. The native regression checks rejected width 2 against committed width 6, then the changed committed width 2 after a valid subject move.
- Coordinates remain signed. The formatter preserves a sub-micrometer nonzero value as an interval/threshold description rather than 0.00 m. Existing plan snapping is limited to 1e−9 m numeric boundary residuals. A negative center and a positive wall overhang are separately and correctly labeled.
- Modifier availability is checked before inside/crossing claims. A degenerate aim produces an unavailable projection and no invented clearance. Projected wall clearance applies to the ideal emitting face; notes explicitly exclude complete fixture, stand, boom, cable, ceiling and collision checks.
- Names pass through `StudioDisplayName.display`; explicit line/control and bidi-formatting characters cannot add new note rows. Numbered entries disambiguate equal or truncated names. A fully sanitized-away name falls back to its point kind, avoiding an empty heading. The formatter never rewrites stored names.
- The plan bounds the output to at most 14 center entries: subject, camera and at most 12 lights. Name display is additionally bounded by grapheme, scalar and byte limits. Exported content is scene/room text only: no reference image, source URL, photo identifier, EXIF, library identity, undo history or credentials are available to this formatter.
- User-entered room dimensions and offsets are presented with calculated-display precision, with an explicit statement that display precision is not measurement accuracy. The saved lighting project still does not persist room measurements; the notes make that distinction clear.

## Evidence inspected

- Existing `/workspace/scratch/73dcd6a65726/verification/guided-basis-debug.log`: 4 new guided-basis tests plus 6 existing guided tests, **10/10 passed**, zero failures. The tests cover 108 categorical combinations / 216 candidates, both camera frames, generated numeric basis and immutable observations.
- Existing `/workspace/scratch/73dcd6a65726/verification/room-notes-debug.log`: **5/5 passed**, zero failures, including quarter-turn coordinates, signed tiny values/overhang, unavailable aim, bounded/injection-safe names, French formatting and unchanged source values.
- Root reported exact source `5ac2d1e2e8e8762c84ababa93e1982ec914fbef8` passed 201 portable tests in both configurations. That revision contains guided-basis work; the room files reviewed here were still pending integration. Do not apply that 201-test count to the later room source.
- `git diff --check` passed during this review. This reviewer did not repeat already-passing portable suites or execute an Apple SDK, simulator, system share destination, VoiceOver or real room trial.

## Remaining required native/device checks

Execute the expanded ReferenceComparison and ManualRoomPlacement UI scenarios at their integrated revision. Inspect the genuine basis and notes screenshots, verify far/near selection and apply/undo, invalid-draft review, dismiss-with-session-retention, actual share cancellation and destination text, Dynamic Type and VoiceOver. Physical room measurement accuracy, AR tracking, complete equipment clearance and reference reconstruction remain outside this implementation and unverified.

## Reviewed working-file hashes

The integrated guided source was based on main `5ac2d1e2e8e8762c84ababa93e1982ec914fbef8`; room files were uncommitted at review. Hashes identify the source snapshot without claiming a later revision was tested.

| File | SHA-256 |
| --- | --- |
| `Sources/LightingCore/GuidedLighting.swift` | `1eb40d88a25c9651582f3f859ea6b95cbbb2a5beddb6bce311a6483d198e7883` |
| `App/ReferenceComparisonView.swift` | `73113361780e6fbbe7d805a03e7a9fb0151f0d562fea604aab34c83c51ee9bb0` |
| `Sources/LightingCore/RoomPlacementText.swift` | `fe0b4c4764790e533e773a94df25cb2b6489cc7756e25eaf2f46b86d294df56d` |
| `App/ManualRoomPlacementView.swift` | `34e32418bbcf585a66583c302a570fbab45a13465a51a70a58e8138c7ba3a753` |
| `Tests/LightingCoreTests/RoomPlacementTextTests.swift` | `5b9111c9ea4bde5ede586273a965cb9a12030a64087c3e7d55d20433f3277f08` |
| `UITests/ManualRoomPlacementUITests.swift` | `051be740a970f291fd01ec0befd2e54ef16de8e0176317bf3182c692fc684928` |
