# Wave 03 — interactions review

- Canonical ID: `/root/w03_acceptance/interactions`
- Input SHA: `35283bed09c609be424df80f36b42391aec19f74`
- Scope: read-only review of current selection/update behavior; no product edits, builds, toolchains, or test execution.
- Outcome: **no source defect identified in the scoped update paths; current native behavior remains unexecuted.**

## Findings

1. **Selection survives name/output/roll edits.** SceneKit retains the UUID-keyed lamp and indicator; name/output/roll changes do not replace the fixture node. The indicator remains its child, so the complete aim/roll basis and housing offset carry the outline. Selection visibility is reapplied after content updates. References: `App/SpatialPreview.swift:204–269,356–409,430–440`.
2. **Kind/size changes preserve selection ownership.** SceneKit replaces fixture/outline geometry only when kind or rectangular dimensions change, retaining both nodes and updating the outline margin. RealityKit retains its lamp root, fixture and selection children; shape switches alter enabled geometry and dimensions, while selection remains under the oriented fixture. References: `App/SpatialPreview.swift:371–400`; `App/StudioEntityGraph.swift:107–124,228–245,249–279,346–364`.
3. **Aim markers and source pointing are coherent by inspection.** RealityKit recomputes aim endpoints on geometry changes, disables both markers for point/degenerate/Float-short aims, and applies selection visibility even without geometry changes. Its emission child reverses local +Z for spotlights. SceneKit uses the complete frame with a right-handed -Z light conversion. References: `App/StudioEntityGraph.swift:240–241,292–308`; `App/SpatialPreview.swift:292–300,411–424`; `Sources/LightingCore/StudioOptics.swift:107–110`.
4. **Same-scene selection and viewpoint persist.** Both adapters include selection in their update guards. SceneKit refreshes callbacks before its guard and leaves orbit/controller state untouched except initial/mode/explicit Fit changes. RealityKit refreshes callbacks, retains orbit state, and only requests Fit on its fit token; ordinary edits keep the UUID set and do not cancel gestures. References: `App/SpatialPreview.swift:204–269`; `App/StudioEntityGraph.swift:69–80,306–308`; `App/RealityStudioPreview.swift:189–205,228–245`.

## Actual checks and limitations

Read pinned `AGENTS.md`, operating protocol, lane PLAN, architecture/design, three adapter files, and all four existing spatial native test files using `git show`; searched native tests and core frame definition using `git grep`. Existing assertions cover metadata/output identity, callback refresh, selection-only visibility, initial roll/aim alignment and orbit retention. Optional patch `44550b6837656e86f4fa7b588ac4cfe7a9b1c361` was read: its three tests add SceneKit kind/size transition and stand-threshold coverage, including indicator-parent/hit identity. No RealityKit graph transition tests were found in the current native suite. Neither pinned source nor patch was executed here. Parent-reported successful CI at source `68c83` is earlier-source evidence only. No native or visual pass is claimed for `35283`/`44550b`.
