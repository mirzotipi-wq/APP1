# Bounded remaining worker packets

Each wave has exactly 10 fresh contexts. On resumption root directly schedules
at most three workers concurrently, without nested coordinators. Each worker performs ONE concrete
check below, records commands, input SHA, result and artifact, then returns.
Do not expand into broad audits. Prefer <=300-word reports (hard cap800 tokens).
Each has an isolated worktree/private-output via tools/prepare_worker.py. No worker
pushes or removes worktrees. Root owns source integration. No template report
counts as execution. Checkpoint after6 complete. Store reports and ledger under
docs/parallel/02/reports/wNN. Briefs below2000 tokens; working target12000 maximum
or platform limit. No model overrides. Do not reread historical handoff volumes;
read relevant contract and source. A real conclusion of no defect is acceptable.

Use a frozen published commit as input. For Swift probes use
`python3 /tmp/keyfill02-r2-probe.py WORKTREE WORKTREE/private-output/probe.swift v1`.
This compiles against a frozen, separately built LightingCore module; output is
private, compilation serializes through flock. It executes real production Swift.
Record snapshot revision reported by root, not the worker HEAD when different.
No package builds, installs or external writes from children. One small probe
per role is sufficient. Bounded independent Python/reference calculations allowed.
Source changes need a patch, root review and serial integration.

## W02 — independent references

R01 compare independent methods to1%/5% contracts; R02 derive12 point/cosine
expected values independently and compare with Swift; R03 check nil/zero/error
case table against actual API; R04 add one independent centered-rectangle Swift
test file candidate (no production edits); R05 repeat a mixed-rig calculation
32 times and compare exact deterministic results; R06 measure own resources and
compute sweep cost bound; R07 compare unoccluded meter vs Study on two ordinary
fixtures, explicitly retain grazing model distinction; R08 verify error strings
contain units/action and no scene names/private information; R09 time100 calls
to each photometric path in Swift, diagnostic only; R10 independently integrate
official CIE1nm data /tmp/keyfill02-cie.csv and generate8-temperature table with
md5 provenance and CC BY-SA4.0 attribution (no production observer replacement).

## W03 — points, directional emitters, receiver orientation

R01 point/orientation acceptance matrix; R02 rigid-transform point invariance
probe; R03 test coincident camera/subject unsupported vs back-facing zero; R04
add focused directional double-cosine analytic test candidate; R05 run independent
concurrent point evaluations using immutable fixtures and compare serial values;
R06 inspect bounds ensuring no point unbounded loop/allocation; R07 audit target
solver receiver normal versus export/consumer normal; R08 inspect unsupported
orientation text propagation without editing UI; R09 probe5cm boundary and1–3
light scaling; R10 independently challenge off-axis source/emitter/receiver using
scalar dot products, no production normal helper in expected values.

## W04 — rectangles, grazing, roll, separation

R01 review tiny-output fix and preserved ordinary sample order; R02 compare
90°roll+dimension swap and180°roll invariance; R03 exact boundary nil/zero cases
on front/back receiver sides; R04 add tiny clipped-face regression candidate;
R05 repeat partial-face fixtures concurrently and compare serial values;
R06 bound unit-scaling recursion and quadrature work from actual source; R07
confirm CPU/GPU subnormal mismatch patch request and unchanged ordinary path;
R08 inspect nil vs black card presentation contract; R09 time partial vs full
paths and scaled tiny path once; R10 independently challenge rolled grazing
case with Simpson or projected-solid-angle reference and record numeric error.

## W05 — target lux

R01 unchanged1e-9 forward solver acceptance and100000cd cap; R02 check source
identity/non-output fields preserved; R03 classify invalid target/light/scene,
unsupported geometry and numeric unattainability with actual Swift; R04 add
point/directional/rectangle attainable-target round-trip regression candidate;
R05 run pure solver independent inputs concurrently, no shared mutations;
R06 inspect solve evaluation bound and memory; R07 inspect single-light versus
total-rig consumer assumption; R08 review actionable error wording; R09 exercise
max.nextDown, max, max.nextUp for3 emitter kinds; R10 challenge representable
subnormal targets versus true unrepresentable target using independent equation.

## W06 — color

R01 review hugeXYZ transform algebra and preserved scene-domain arithmetic;
R02 exposure settings preserve incidentXYZ/totalLux in a3-light rig; R03 reject
nonfinite/negative XYZ and invalid settings while black stays valid; R04 add
matched-white/exposure boundary regression candidate; R05 concurrent immutable
color-transform reuse agrees serially; R06 inspect finite high-scale adaptation
bounds and no unbounded work; R07 verify computeParameters unchanged and document
Float32 domain separation; R08 review color-independent lux/unsupported labels;
R09 test continuity near internal high-scale branch threshold; R10 independently
compute Bradford matrix inverse and compare matched gray output with analytic
sRGB/Reinhard reference (do not call production math for expected values).

## W07 — contracts

R01 consolidate shared-interface compatibility; R02 inspect units/candela/lux
inference invariants; R03 audit public signature diff from baseline; R04 produce
minimal renderer-owner patch suggestion only, no renderer mutation; R05 inspect
actor/Sendable consumer handoff of value types; R06 bound light-count and output
allocation across consumers; R07 inspect CPU/GPU/UI/export callsites for semantic
mismatches and exact paths; R08 check privacy/accessibility implications in exported
plans/error messages; R09 inspect Swift5.9/iOS17 compatibility of additions;
R10 independently falsify any claimed unchanged normal-range arithmetic using
baseline and current witnesses provided by root.

## W08 — reproducible sweeps

R01 audit sweep domain and maxima denominators; R02 run deterministic point
sweep across angles/distances; R03 sweep separation boundary outcomes; R04 add
reproducible rectangle sweep script candidate, fixed seed; R05 repeat subset
in reordered/concurrent execution and compare results; R06 record runtime/memory
and fixed work bounds; R07 compare ordinary meter/Study samples on sweep subset;
R08 ensure numerical reports are human-readable without hue or user data;
R09 run color temperature/exposure finite-output grid; R10 independently recompute
max errors from raw rows and verify1%/5% unchanged.

## W09 — independent challenge

R01 challenge completion claims against current source hashes; R02 geometric
similarity/translation held-out fixture; R03 adversarial invalid optical geometry;
R04 inspect implementation diff for cancellation/overflow mistakes; R05 repeated
pure calculations with different ordering; R06 challenge maximum quadrature and
recursion resource claims; R07 review remaining consumer risks and ownership;
R08 challenge wording for physical-calibration or exact-reconstruction claims;
R09 challenge nearest output/threshold neighbors; R10 alternate spherical-edge
projected-solid-angle or independently refined Simpson reference on held-out
rectangle fixture, compare with production.

## W10 — delivery

R01 numerical acceptance signoff with explicit limitations; R02 verify regression
fixtures cover identified failures; R03 final public interface/signature audit;
R04 inspect owned source/test diff for unrelated changes; R05 final determinism
spot check; R06 resource/evidence retention and cleanup eligibility audit;
R07 verify concrete consumer requests and lane01/20 handoff information;
R08 audit handoff claims for accessibility/privacy and physical-calibration scope;
R09 verify actual toolchain/test command/source provenance; R10 independently
recompute reported numerical maxima and verify actual100-context ledger.
