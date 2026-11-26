# W08-05 concurrency review — context 75

No new concurrency defect found within the reviewed scope. Source remains unchanged at `46a161c`; inspected implementation/test/build inputs match root-tested `7bdea15c`.

`StudioSession` is `@MainActor` on both platforms. Darwin additionally compiles Observation macros; Linux omits them. Session reservation precedes edit termination and task creation. The session retains its task through receipt adoption; request-matched cleanup releases it. `ProjectStore` checks cancellation before synchronous actor work and never after a commit. The core transaction lock protects compare-and-replace across store instances.

Root logs independently show **431/0 Debug** and **431/0 per-file Release**, including 35 session/feature/Plan methods. Default Release remains a compile failure with signal 9; the passing retry disables whole-module optimization.

The observer-cancellation session test uses an injected receipt. Actual-disk postcommit cancellation, queued cancellation and actor-responsiveness methods are in `ProjectStoreOperationTests`, excluded from portable execution. Real store conflict/recovery is covered separately by session tests.

`project.yml` specifies Swift 5.0 without explicit strict-concurrency/default-isolation settings. Current Apple typechecking, Observation, native sheets/windows and UI execution remain unverified. Three Void producers still consume rejected drafts.

Both agent-cycle checks exited 0. No build, source edit or new test ran here. Receipt contains hashes and evidence limits; the source patch is empty.
