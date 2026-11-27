# Quality and release contract (protected)

These are initial engineering targets, not measured achievements. Record actual numerical results with device/toolchain, build configuration, workload, sample size, revision and raw artifacts. If target proves infeasible, owner must approve an explicit tradeoff; agents cannot weaken it. A missing tool or unrun test is unverified, never pass.

## Owner-authorized M02/M03 scope: m02-m03-code-v2

On 2026-11-25 the owner explicitly directed development to remove requirements dependent on unavailable outside factors and proceed through M02, then M03, by working on the code. The six M02/M03 gates below now use [the versioned code acceptance contract](acceptance/m02-m03-code.md). Physical scene collection/calibration, photographer review, physical-device performance/thermal measurement and manual device accessibility are removed from these two milestones. Apple-provided `.all` accessibility audits remain opt-in diagnostics with their actual outcomes preserved. App accessibility semantics, layout, contrast and functional workflows remain required.

This revision changes acceptance scope; it supplies no passing evidence. Prior failures and unperformed physical checks retain their original meaning. Completing these milestones means code acceptance only. M01 and M04–M07, release approval and distribution requirements are unchanged by this revision.

| Gate | Acceptance criteria |
|---|---|
| core_tests | swift test clean; analytic fixtures, invalid inputs and round-trip cases; no skipped required tests |
| native_build | generated Xcode project builds unsigned for iOS simulator; capture command, Xcode version, SDK |
| persistence_smoke | create/edit/save/relaunch; corrupt file surfaced, never silently overwritten; smoke evidence |
| photometry | inverse-square and cosine analytic cases <= 1% error in supported point model; area model compare against numerical reference <= 5% on declared test cases; document limits and units |
| rendering | m02-m03-code-v2: twelve synthetic image fixtures with zero unsupported pixels; six CPU/shared-kernel parity fixtures with exact invalid masks, mean RGB channel error <= 1 and fraction with error > 4 <= 0.005; eight precision fixtures with maximum channel error <= 1; geometry/color/visibility regressions and actual output review; see the code acceptance contract |
| performance | m02-m03-code-v2: tested rendering/cancellation/cache bounds and optimized reproducible host benchmark; four cached frames, <= 256 KiB RGBA plus <= 64 KiB masks, mannequin width <= 144, cancellation observed after at most eight further pixel evaluations; no physical FPS/thermal/RSS claim |
| editing | precise units, undo/redo, stable selection, valid gesture transforms, no lost edits, 10 repeatable core workflow runs |
| accessibility | m02-m03-code-v2: app accessibility labels/values/actions, Dynamic Type layout, contrast, non-color-only cues, exact numeric editing and reduced motion; app-level checks and functional workflows; Apple-provided audits are separately reported diagnostics, not substitute passes |
| persistence | migrations, atomic writes, malformed/oversized data, interruption, project library round-trip, deletion/recovery; no data loss in required tests |
| inference | held-out 30+ controlled authorized examples, document ambiguity, uncertainty, calibration and failures; at least 80% of cases contain a practically usable rig in top 3 by two human reviewers; abstain on unsupported inputs; never claim exact setup |
| reference_privacy | local processing by default; no unexpected network transfer; import/delete tested with permissions denied/limited |
| ar_device | physical devices, 10 trials each across 3 room conditions; placement median error <= 10 cm within 1–3 m under normal tracking; disclose p95 and failures, degrade gracefully, no false accuracy guarantee |
| export | readable diagrams at standard sizes, correct units/positions/labels, actual PDF/share open test, no private reference embedded unless requested |
| commerce | verified StoreKit sandbox purchase, restore, cancellation, pending, revoked/refunded, offline; correct free/pro functionality, no dark patterns |
| customer_validation | 30 real interviews, 50 beta users target, at least 20 explicitly willing to pay proposed price; record real opt-in feedback (not synthetic), no fabricated demand |
| privacy | permissions, app privacy disclosures, data deletion, threat model, dependency/licenses, no keys or unapproved uploads |
| regression | unit/integration/UI suites green, zero unresolved P0/P1 bugs, release build, crash-free required scenario matrix |
| device_matrix | actual tests on agreed baseline, modern non-LiDAR and LiDAR iPhones; simulator separately; low storage, interruption, permission denied, airplane mode, dark/light and accessibility |
| release_review | independent reviewer checks product promise, visual quality, App Store guidelines, privacy/support materials, no misleading claims; no missing mandatory evidence |
| owner_approval | explicit owner signoff on release, pricing, name clearance, signing, privacy and distribution |

Severity: P0 data loss/security/payment integrity or widespread crash; P1 major workflow broken or misleading output; P2 material but nonblocking usability/performance bug; P3 minor polish. Release cannot proceed with unresolved P0/P1. CI passing alone is insufficient. Golden fixtures must be rights-cleared and not replaced to hide regressions. Track exceptions explicitly with owner approval and rerun changed gates after relevant changes. Release scorecards are supporting evidence, never substitutes for gates.
