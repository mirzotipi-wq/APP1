# Lane 02 — ideal photometry and color

Requested branch: `finish/02-photometry-color`. Inspected main at startup:
`9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. No lane 20 campaign baseline
was published at inspection, so the owner's fallback `f150f98` is the branch
base. Later main changes are preserved on origin/main for lane 20 integration.

Scope: SurfacePhotometry.swift, Colorimetry.swift, LightOutputAdjustment.swift,
StudioOptics.swift, source-specific regressions and lane evidence. Renderer,
UI, export and scene-schema changes are requests to the owning lanes.
Thresholds remain point <=1%, declared area <=5%. Physical calibration is
unperformed and separate from ideal-model correctness. Canonical milestone
state is owned by lane 20 and is not modified here.

## Execution

Requested: 100 actual fresh contexts across ten waves, ten roles per wave.
At the execution-host interruption, 18 actual contexts had completed; 82 were
not created. See worker-ledger.json and HANDOFF.md for the final session state. The acceptance worker
also coordinates nine fresh specialists. Root integrates serially. Available
capacity is four contexts including root: one wave lead and at most two child
workers. Each receives its own detached sparse worktree and private-output
folder. Briefs <=2000 tokens, reports <=800, working target <=12000 per worker;
these are targets, not changes to platform limits. Checkpoint at six of ten
assignments and before integration. Root records progress at 60% of its working
budget and uses persisted artifacts across context boundaries.

Roles per wave: acceptance, invariants, interfaces, implementation, concurrency,
resources, consumers, accessibility/privacy, platform/performance, independent
verification. Numbering is W01R01 through W10R10; actual agent IDs must be
captured from spawn results. Every role must perform concrete inspection or
execution; plans alone are not completion. Builds serialize under a single
resource lock and use private outputs. Do not install another toolchain in a
worker. Push only the requested branch. Retain worktrees until source/reports
are committed, pushed, and the remote SHA verified.

## Wave topics

1. Formula/unit/normalization/geometry map.
2. Independent analytic and numerical references.
3. Point/directional evaluation and receiver orientation.
4. Rectangle grazing, roll, separation.
5. Target-lux solving and unattainable output.
6. Color adaptation, exposure, finite boundaries.
7. CPU/GPU/inference/UI/export contracts.
8. Reproducible sweeps and supported regressions.
9. Alternative-reference challenge.
10. Corrected mathematics and evidence delivery.

## Initial resources

Linux Debian 13 x86_64; 9967 MiB total memory, ~6425 MiB available at inspection;
workspace disk ~98 MiB available; /tmp tmpfs ~3.0 GiB available. Checkout 143 MiB.
No Swift on PATH at startup; portable Swift execution must be established or
honestly marked unavailable. No Apple-native runtime claim on this host.
