# Lane05 wave04 — navigation and continuity

## Outcome

Exactly **ten fresh contexts completed**: the acceptance lead plus nine children. At most two children were active alongside lead/root. Concurrency's exact-patch followup reused its original context. Canonical IDs, immutable inputs, actual checks, files, commits and report digests are in `ledger.json`; original reports are retained verbatim in `reports.md`.

One owned source defect was repaired and independently reviewed. One cross-lane first-save continuity defect remains an explicit lane01 request. No worker ran native tests, builds or toolchain installation.

## Integrated repair

The SceneKit transition **orbit/Fit0 → camera → invalid orbit → valid orbit/Fit0** previously published orbit mode before returning for invalid input. Recovery then saw no mode or Fit-token change and could retain the authored camera pose/lens, or nil point of view after undefined camera framing.

Candidate `b35671f971be2e2dd4d05d7531486a3de4ce25c2` conditionally publishes the mode only for valid scenes, before deriving interaction availability. This preserves pending mode-change Fit while retaining ordinary orbit through invalid/recovered scene content. Publishing valid mode before availability also preserves initial empty-rig interaction.

Only `App/SpatialPreview.swift` and new `NativeTests/SpatialNavigationRecoveryTests.swift` changed. Four regressions cover authored-camera recovery, nil-camera recovery, ordinary orbit preservation and initial empty interaction. Writer, acceptance, concurrency, root and independent source reviews found no source blocker. Independent review verified candidate blobs equal integrated `bc5b137e9717c9e20bfaf210d798bb7e4bb3836c` and preserved `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. The patch digest is in the ledger. **Compilation and execution remain unperformed by this wave.**

## Ten distinct outputs

| Context | Concrete result |
|---|---|
| Acceptance | Corrected source inventory176native/30spatial; independently matched four App source digests after recovery; defined execution boundary. |
| Geometry |96 scalar projection checks; conservative Fit distance <=490.652737m and bounded-state far margin >=52.200430m. Floor/grid intentionally excluded. |
| Interfaces | Exact first-draft-save generation/workspace identity trace and lane01 owner request. |
| Implementation | Minimal two-file repair, four native regressions, clean private-worktree commit; no native run. |
| Concurrency | Four mixed-mode and two same-mode source-model traces; exact patch ordering and regression review. |
| Resources | Source-held ownership matrix: RealityKit55fixed+24/light; SceneKit8explicitfixed+4/light. Framework internals excluded; no measured allocation/performance claim. |
| Interactions |144 independent pan projections plus orbit, pitch-limit, zoom-composition and Fit-token witnesses; no sampled sign defect. |
| Accessibility/privacy | Equipment-list alternative, disabled/custom gesture gates, unavailable feedback and nonAR source path; SceneKit native VoiceOver gating remains unobserved. |
| Platform/performance | Float/layout review; conditional fixed-far translation counterexample plus precise native controller-handoff observation plan. |
| Independent review | No candidate source blocker; exact integrated blob comparison and explicit geometry/recovery coverage limits. |

## Owner request and remaining observation

**Lane01, checkpoint966c9c21adbb685d82127e7f88981b74daf47e3d:** first draft save rotates generation while retaining workspaceResetID, but the 3D wrapper remains keyed by `.id(generation)`. Source lifecycle tracing predicts native coordinator replacement and viewpoint reset without Fit. Key its lifetime by `session.workspaceResetID`, retain generation-guarded selection callbacks, and cover first-save retention versus switch/reload reset. No composition file was edited by this wave.

The bounded far-plane proof applies to `SpatialOrbitState`; it does not constrain SceneKit's native free camera. If the controlled camera retains the manual fitted far plane, a1000m backward translation can clip the rig. Apple documentation distinguishes native pinch FOV changes from translation and describes a separate controlled camera. Active camera ownership, automatic range and effective native projection remain unobserved; **no unconditional native clipping defect or speculative repair is claimed**. `platform_performance/evidence.md` contains the exact observation packet.

The independent reviewer noted that new recovery tests omit orientation/projected containment, while the baseline Fit helper projects implementation-generated bounds rather than proving every displayed mesh is contained. Existing dimensions/transform checks and source-derived bounds narrow these gaps; they do not constitute RealityKit execution. SceneKit's custom selection VoiceOver gate does not prove native camera gestures are gated, nor does that asymmetry establish observed interference.

## Provenance and execution boundaries

Original source reads used956a3b1d70cb3d67ba136821d9828be80aee1c3b. An observed executor reset removed temporary storage; resumed reads used published9725fb1177a5c7afbdf798ffd627e65e604c75b1. Four owned App SHA256s independently matched retained original tool outputs; root additionally reported native-source identity. Geometry's successful reviewed-constant witness remains explicitly distinguished from post-reset source execution.

Baseline discovery is176native/30spatial; the candidate adds four methods, giving180/34. Historical68c83 unit execution171/25 is not promoted to candidate acceptance. Root most recently reported9725 run45826141504 core366Debug/366Release plus100tooling passed, with native176 queued; that status is parent-provided and source-specific. Separate historical UI failures/cancellations remain preserved by root. No device, manual VoiceOver, rendering-performance, privacy-network, calibration or release-readiness evidence is claimed.
