# W09-04 — native Observation regression

Actual fresh context **84**, frozen input `f33a399f8ba21618320ce50aed7981450a9703a7`; reviewed correction `8b18366c1c718c2c81f6b275d66140f6dc9d49c9`. Published `bed58c338f9f53758c611b8642241c3ec7697505` has no differences from frozen input across App, Sources, Tests, NativeTests, UITests, Package.swift or project.yml. Later writer `d3946bc5369bb00459c161e4397d9364dccba2bc` inspected for scope only.

Root approved the concrete design before coding. Commit **`d2768d571afc2ff2b49bc8499dc1e5d8e2e294d7`** adds only `NativeTests/StudioObservationTests.swift`: one XCTestCase, three Darwin-only tests using actual `withObservationTracking` subscriptions. They check computed scene edit/undo, feature open/nested retirement/removal, and busy reservation/completion while task installation/removal emit no notifications. A lock-protected Sendable recorder counts callbacks; state assertions occur after mutation. Existing executor injection gives deterministic completion without sleeps, production hooks or source-text matching.

`agent_cycle.py check` and `next` exited 0 (state structure only); staged diff whitespace validation passed. Worktree is clean. No builds, Swift typechecks, runtime tests, UI execution or pushes performed by this worker. Prior forced Linux macro checks and syntax receipts remain limited evidence; Apple runtime acceptance is **unverified**. Root owns Package membership, integration and fresh runtime validation. The three methods are absent from ordinary Linux inventory. Private operationTaskID is not directly observable through this test API. Existing Void-producer limitations remain.

Committed patch and exact hashes/commands are preserved in sibling `source.patch` and `receipt.json`.
