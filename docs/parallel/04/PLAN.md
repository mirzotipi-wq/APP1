# Lane 04 — Metal and render resources

Base: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Main observed at startup: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`; no lane20 baseline was present on fetched branches. Only `finish/04-metal-cache` is published. Preserve later main changes for lane20 integration.

## Scope and fixed acceptance

Own MetalStudyRenderer.swift, ReferenceStudy.metal, StudyKernel.h, StudyFloat32Eligibility.swift, StudyFrameCache.swift and corresponding tests. Preview UI/oracle belong to03; photometry to02; composition/build configuration to01; harness/CI to19. Route proposals instead of editing their ownership. CPU Double remains authoritative. Keep exact invalid-mask parity, mean RGB error <=1 and fraction >4 <=0.005; strict precision maximum <=1. Cache: four frames, 262144 RGBA bytes, 65536 mask bytes. Reject failed/cancelled work and evict incompatible Metal frames on downgrade.

## Execution

Ten waves of ten actual fresh-context workers, three concurrent workers plus coordinator. Roles per wave: acceptance, invariants, interface, implementation, concurrency, resource-lifetime, consumer-integration, accessibility/privacy, platform/performance, independent-review. Wave themes follow the user order: trace, reproduce, eligibility, arithmetic, cancellation/adoption, cache, startup/downgrade, matrices, adversarial recovery, final evidence. Each worker has a detached sparse worktree and private results/build directory. Integration and expensive builds are serialized. Budgets are targets (brief<=2000, working12000, report<=800, coordinator24000); checkpoint at60%. Exact runtime token caps cannot be set by these tools. IDs and completed reports are counted honestly.

## Environment and preservation

Linux x86_64; g++ available. No Swift, clang or Xcode on PATH at startup. Ordinary workspace had ~99MB free and full checkout failed. A sparse checkout excluded archived docs/evidence without changing tracked files. Concurrent work then filled /tmp. Our own 77MB tree moved to /dev/shm with original /tmp path preserved by symlink; no other work was removed. Tests requiring unavailable toolchains remain unrun unless exact remote execution is recovered. Host C++ is not Metal. Push and verify wave checkpoints before worktree cleanup.

## Initial hypotheses

1. Precision routing may miss discontinuities at camera/panel, emitter, or arithmetic boundaries.
2. Cancellation checks and cached-return admission may leave stale scheduling windows.
3. Backend downgrades need deterministic engine-level tests in addition to pure-cache tests.
4. Byte accounting, exact cache identity, and zero-cost/overflow behavior must remain bounded.

Source tracing and targeted regressions determine implementation; preserve numerical fixtures and thresholds.
