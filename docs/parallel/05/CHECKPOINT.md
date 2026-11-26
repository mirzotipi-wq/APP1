# Lane 05 coordinator checkpoint

## Source and recovery

Campaign baseline f150f98e35dd735927075aac4d2f8b02295c6a67. Published source68c83cca75f9ef8fd41fe6a33358b00e0790c45a and treeeba89a0fc2a4e500c40404235ba5fe96b672d871 were verified remotely. Parent main9e0e2ba carries its existing native compilation repair. Follow-up source is preserved in GitHub commits9218740173e718efe928ee18dfe5da844c2f2179 (clipping/aim bounds) and35283bed09c609be424df80f36b42391aec19f74 (Float projection boundary). The first source checkpoint completed native execution; the recovered follow-ups are ready for the next serialized source checkpoint.

The execution environment interrupted and returned with empty temporary storage. Source and latest regression files were recovered byte-for-byte from GitHub, checked against pre-outage SHA256 values. See RECOVERY.md. Original unpublished worker files were lost; recovered report blocks are labeled accurately.

## Implementation

Viewport-only bounds include housings, undefined-aim rectangles, stands, busts, camera symbols and aim-marker volume. Pure orbit state retains Double calculations until native upload. RealityKit guards disabled/invalid/inactive input and current hits. SceneKit preserves continuing UUID nodes, invalidates discarded identities, shows unavailable-camera feedback, and represents its authored camera lens. Core geometry, AR, Study, Plan UI and shared composition are unchanged.

## Workers and budgets

Waves 01–03 completed exactly 10 fresh contexts each: 30 actual workers, all fork_turns:none. Same-context followups and failed spawn attempts add no credit. Wave 03 contributed three focused SceneKit transition tests from a private worktree, independently reviewed before integration. Current native inventory is 176 methods, including 30 spatial; these five additional methods are not covered by the earlier 171-method execution. Root integrates sequentially. Brief/context/report limits are task targets; actual token telemetry and enforceable per-worker context settings are unavailable. Ledgers distinguish source review, transcribed math and execution.

## Validation

Eight actual Linux viewport XCTest methods passed at68c83; a ninth clipping regression passed in the local successor. The ten-test marker rebuild compiled production/test modules, then generated-runner compilation ended with signal9 before tests ran. It has no ten-test pass. Local parsing of changed Apple files passed; that was not Apple type checking.

GitHub run45817222487 passed366 Debug/366 Release package tests and100 tooling checks. Native test-bundle builds passed. Studio-optics UI runner initialization failed with AX-loaded timeout; app-accessibility failed to reveal light-Key in Plan mode. Logs/owner requests retain failures. The simulator job completed successfully: 171 native methods, zero failures and zero skips, including all 25 spatial methods at 68c83. Unsigned Debug/test-bundle and Release builds succeeded. Two genuine SceneKit snapshots (ordinary and crowded twelve-light rigs) were retrieved from artifact 15119450593, archive digest verified and originals visually inspected. See captures/receipt-68c83.json. This is x86_64 simulator fallback evidence, not RealityKit or physical-device execution.

Next: finish ten waves and actual ledgers; integrate focused transition regressions; review native spatial outcomes/genuine captures; publish follow-ups and exact current evidence; finish HANDOFF.md. No main update or milestone/release promotion.
