# Visible identity correction

## Finding and scope

Wave 9's independent iOS review found a residual display issue after the invisible-name validation change. A valid retained legacy name such as U+200C produces an empty `StudioDisplayName.display` value. Projects and Recovery already supply a contextual fallback, but the active studio, editable-copy sheet, light controls and manual-room headings passed that empty value directly to native text. The import success message also displayed empty quotation marks. This is a visible identity and accessibility defect; no data loss was observed.

The report model had a separate sanitizer that retained invisible-only names. Consequently its existing `Portrait setup` and numbered-light fallbacks were not reached for these names.

Base revision: `0fce248b4e61bace88002b40f6c56fddedb19c8a`, main, with the existing invisible-name and edit-history patches already in the working tree. This correction preserves those patches.

## Correction

- `StudioDisplayName.label(_:fallback:)` applies the same bounded sanitizer to a supplied name and a visible contextual fallback. It does not mutate either input.
- The active project heading, editable-copy title and successful-import message use `Unnamed project` when the retained name has no visible content.
- Studio light plan markers, selection accessibility labels, rack rows, row identifiers and inspector titles use a numbered `Light 1`, `Light 2`, etc. fallback. A short stable ID is available if a supplied light is absent from the scene.
- Manual-room measurement headings use the corresponding scene light number, with Subject and Camera retaining their existing labels.
- `LightingPlan` delegates its text sanitizer to `StudioDisplayName.display`, activating its existing contextual report fallbacks and keeping the bounded Unicode policy consistent with the studio. The original `scene` in the report and the editable project document retain their original names.

The Projects and Recovery identity helpers already handle empty labels and remain unchanged. The room-note export already includes numbered entries and a kind fallback. Project rename fields intentionally expose an empty edit field for invisible legacy names so the user can choose a valid new name. Duplicate/recovery suggestions retain visible suffixes; this change does not silently rename any existing project or light.

## Verification

Actual environment: Swift 6.4.3, Linux x86_64. Commands from the repository root:

```sh
PATH=/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin:$PATH swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/visible-identity-build --filter 'StudioDisplayNameTests|LightingPlanTests'
PATH=/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin:$PATH swiftc -frontend -parse App/StudioView.swift App/ProjectBackupView.swift App/ProjectLibraryView.swift App/ManualRoomPlacementView.swift
git diff --check
```

Debug: **24 tests passed, zero failures**, including 2 new tests. Name tests cover invisible-only fallback selection, ordinary Persian/emoji/accent preservation and bounded fallback strings. The report regression verifies numbered visible lights, the existing visible title fallback, unchanged scene names and byte-identical re-encoding of the editable document. The native files parsed successfully. Parsing is not Apple SDK type checking or native UI execution.

Raw test log: `visible-identity-debug.log` in this directory. SHA256: `f1c5b356a16dd260940267281d6f3cc9d4b19d700665653405322aad68af6260`. Its raw host timestamp differs from the connector clock; it is retained without alteration.

Reviewed source hashes:

| File | SHA256 |
|---|---|
| `Sources/LightingCore/StudioDisplayName.swift` | `4e257e8ac1924093cafa2a1046b52fa3581f709a9a4ec8bc80ff37f515bdba63` |
| `Sources/LightingCore/LightingPlan.swift` | `099c94268ca31af5e1311b5fc570833967bec61f54674115b7f3ad0188580b8e` |
| `Tests/LightingCoreTests/StudioDisplayNameTests.swift` | `98abca03ccdbfecc65d24441227f06682f402423723128e04a536c4a62d12e61` |
| `Tests/LightingCoreTests/LightingPlanTests.swift` | `b5b7ea1e45f4ef278ba6871820cb2acc9f8f5784d44a97ebda01e5e658618ae5` |

## Remaining evidence

The integration lead must run the full exact-source Debug and Release suites. Current native screenshots, VoiceOver reading, Dynamic Type layout, PDF rendering and real file-provider flows remain unverified for this correction. No accessibility, export, native-build or release gate is promoted by this packet.
