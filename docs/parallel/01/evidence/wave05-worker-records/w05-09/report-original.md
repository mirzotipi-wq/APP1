# W05-09 — platform and payload review

## Identity and outcome

- Worker: `/root/w05_acceptance/w05_09_platform`; same context resumed after interruption, no children.
- Tree base: `ea83fa165916aaa2f55ddb88f6430b8a59ce5565`.
- Reviewed source: `363a7149e4eb6f195f478b3ce0210e33e8ac7ed0`, inspected through exact `git show`/`git diff` reads.
- Worktree: `/workspace/scratch/e08d5190f17c/workers/w05-09/tree`.
- Commit: none. No blocking defect found within this platform/payload review. Native integration remains pending.

## Findings

**Target membership and real implementation.** `Package.swift` selects the actual `App/StudioSession.swift`, `ProjectStore.swift`, and `ProjectLibraryOperation.swift` for `StudioComposition`. Its test target explicitly includes `NativeTests/StudioFeatureSessionTests.swift`. `project.yml` includes all `App` and `NativeTests` sources and links the `LightingCore` product, whose default source discovery includes the new presentation contract. The feature tests instantiate the actual session; injected executors and actor gates control storage timing without mirroring session admission logic. The final difference from `721186e` is 35 added test lines; production is unchanged.

**Isolation and portability.** `StudioSession` is always `@MainActor`; its operation task explicitly resumes on that actor, and feature admission/application/receipt updates are synchronous. `@Observable` and `@ObservationIgnored` are conditional on Darwin. Consequently Linux execution exercises actual orchestration without native Observation expansion. Neither that execution nor syntax parsing establishes Apple SDK typechecking, macro behavior, SwiftUI invalidation, focus, or native presentation lifecycle. `project.yml` specifies Swift 5 language mode; a Swift 6.0.3 compiler receipt is not a strict Swift 6 concurrency-mode claim.

**Value boundary and lifetime.** Destination, context, receipt, and presentation are `Equatable, Sendable` values containing UUIDs and `LightingScene`; no image bytes, native views, AR objects, or persistence conformance are added. Live admission consults the parent optional and UUID identities, rather than comparing complete scenes. A captured value remains independent, as documented and tested. One parent-owned presentation slot retains its immutable opening scene after retirement; matching teardown, successful document reset, or replacement after retirement releases that slot. First save preserves logical identity. External captures and existing history can retain additional snapshots, so one slot is not a global memory bound. Dismissed receipts cannot advance.

**Costs and bounds.** Admitted scenes have at most 12 lights; light names allow 80 Swift characters. History caps each direction at 60 entries and can also retain a transaction start. Array/string copy-on-write can share storage initially; staged editor changes, light mutation, and history updates may copy buffers. Structural equality and arbitrary-scene validation still traverse values and strings. Optional-representation normalization searches the starting light array for each current light, giving quadratic light-count work, bounded here by 12 lights. The 80-character rule is not a UTF-8 byte ceiling, and public value constructors do not validate arbitrary payloads themselves. Scene decoding caps input at 1 MiB; library storage caps total encoded input at 8 MiB. These storage bounds are not RSS limits. No allocation, FPS, latency, or memory benchmark was performed or inferred.

**Integration limit.** Exact-source `StudioView` still uses legacy feature routes and generation/equality guards. The new session policies are preparation for wave 6; native host wiring and focus were neither changed nor accepted here.

## Actual checks and interruption

Read required startup, product, architecture, roadmap, quality, design, and lane interface/handoff documents. On the detached base, `python3 scripts/agent_cycle.py check` and `next` exited 0; they establish structure only and report M03 gates outstanding.

Before interruption, worktree creation and sparse initialization/configuration succeeded; checkout failed when the environment disappeared. The resumed probe confirmed base HEAD with no checked-out files. Completing the original checkout succeeded and produced clean status; no tree recreation or source overwrite occurred.

Inspected retained `wave05-final` command/native-syntax receipts and raw Debug log: source matches the reviewed commit; 430 tests passed with zero failures, including all 16 actual feature-session methods and the dismissed-receipt guard. Independently matched seven relevant exact-source SHA-256 values against the 173-entry manifest. Raw Debug SHA-256: `d1657413c96e3445178c3af06ffe266e9c2287e4a813efa12fd957e76b0c2576`. The 80-file parse receipt explicitly covers syntax only.

No builds, test executions, benchmarks, repository edits, pushes, or tree deletion were performed. The assigned build directory was unused.
