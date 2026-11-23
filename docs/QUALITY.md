# Quality and release contract (protected)

These are initial engineering targets, not measured achievements. Record actual numerical results with device/toolchain, build configuration, workload, sample size, revision and raw artifacts. If target proves infeasible, owner must approve an explicit tradeoff; agents cannot weaken it. A missing tool or unrun test is unverified, never pass.

| Gate | Acceptance criteria |
|---|---|
| core_tests | swift test clean; analytic fixtures, invalid inputs and round-trip cases; no skipped required tests |
| native_build | generated Xcode project builds unsigned for iOS simulator; capture command, Xcode version, SDK |
| persistence_smoke | create/edit/save/relaunch; corrupt file surfaced, never silently overwritten; smoke evidence |
| photometry | inverse-square and cosine analytic cases <= 1% error in supported point model; area model compare against numerical reference <= 5% on declared test cases; document limits and units |
| rendering | 12 rights-cleared controlled scenes covering key/fill/rim, soft/hard modifiers, skin/material and shadow; calibrated comparison protocol plus independent photographer review; no clipping/flicker/obvious geometry errors in required cases |
| performance | physical iPhone 13 or agreed baseline: 3 lights, standard portrait scene, release build, 60 fps target, p95 frame time <= 20 ms after warmup over 5 minutes; 15-minute thermal test, peak resident memory <= 350 MB, no critical thermal state; report settings and raw samples |
| editing | precise units, undo/redo, stable selection, valid gesture transforms, no lost edits, 10 repeatable core workflow runs |
| accessibility | VoiceOver, Dynamic Type, contrast, meaningful non-color-only cues, accessible numeric editing, reduced motion; manual audit on real device |
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
