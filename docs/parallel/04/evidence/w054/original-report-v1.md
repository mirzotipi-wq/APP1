# Worker 054 — core cache lifetime regressions

Canonical agent: `/root/w051/w054`. Role: implementation/core-cache lifetime test writer, wave 06, Key & Fill lane 04. Input revision: `5934f291b8e78e378a96ec3e4d294521c79839d0`; campaign baseline: `f150f98`. The parent supplied this authoritative revision because wave packet `2d556afeca3be2fe717b6cfb23d793431264b34e` has a null input SHA.

## Scope and artifacts

Owned source: `Tests/LightingCoreTests/StudyFrameCacheTests.swift`. Input blob `98f01603ac6ab2f5f8a06f46b51f8c174d4dac84` becomes candidate `af6a0a4d81bb7bf9ebaeffb717f8f0871f7981de`. Evidence: `docs/parallel/04/evidence/w054/source-review.json`, blob `28d656cb171e8e584c01fcc724c16840a88dde6c`. The complete source and evidence are immutable GitHub blobs awaiting root reconstruction and integration.

The planned worktree `/tmp/keyfill04-2987b1ee980d/workers/w054` and results directory `/tmp/keyfill04-2987b1ee980d/results/w054` were not created or used. Actual work used immutable GitHub snapshots and isolated functions session state. All ten mandatory startup files were read at the exact input revision. The current brief governs scope; older main-branch handoff directions were historical context.

## Change and source findings

Preserved all twelve original tests verbatim and added four focused lifetime regressions. Oversized pixel and mask replacements must release the rejected object, retain the original and unrelated value, and preserve eviction order. Successful replacement must release only the original, retain the new value, and make it most recent. Independent pixel/mask budget pressure must release both removed objects while preserving surviving and admitted objects. Selective invalidation must release both Metal-tagged fixtures, retain both CPU-tagged fixtures through a nonmatching removal, and release those survivors when cleared.

The immutable fixture class uses checked Sendable conformance. Its insertion helper returns only a weak observer, with no escaping value capture. Observations do not look up values or preserve a cache snapshot across mutation; synchronous lifetime barriers keep only the current cache alive while assertions inspect observers. Labels describe generic selection fixtures, not real rendering.

Source inspection found the rejection guard precedes replacement removal and every removal path subtracts costs through the same helper. No concrete cache defect was demonstrated, so implementation and arithmetic assertions remain unchanged.

## Evidence and limits

Executed checks were immutable reads, JavaScript preservation/method-inventory/observer checks, and exact UTF-8 roundtrip comparison of the saved source. All passed as source checks only. Sixteen methods are authored; none was compiled or executed here.

Local git status/branch/HEAD/history, agent_cycle check/next, hash-object, Swift builds and Debug/Release tests were unavailable. No execution probe or SDK installation occurred. These tests measure generic value ownership when executed; they establish no mock backend, shared-kernel, simulator Metal, physical-device, GPU-memory, RSS, or actual frame-payload result. Frozen acceptance remains unchanged.

Next: independent review, root reconstruction/hash verification, then `swift test --filter StudyFrameCacheTests` and its `-c release` counterpart in a capable approved environment. Swift/ARC runtime acceptance remains CI-pending. Root alone integrates and pushes; this worker wrote no refs or commits.
