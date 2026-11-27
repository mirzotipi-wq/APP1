# W03R10 — independent directional double-cosine check

**PASS, one fixture.** Swift snapshot `v1` and worktree HEAD both identify `1b286885cb803ba17e159713651515ab119e17f1`. Host: Swift 6.0.3, x86_64 Linux. Reviewed `AGENTS.md`, `docs/QUALITY.md`, `docs/ARCHITECTURE.md`, `StudioOptics.swift`, and the point-photometry contract in `SurfacePhotometry.swift`.

Coordinates in meters: source `(1.25, -0.75, 2.5)`, receiver `(-0.5, 1, -0.25)`, camera `(2.5, 2, 1.75)`, manual aim target `(0.25, 2.25, 1.5)`; intensity **1739 cd**. This uses three-dimensional offsets, not a 3–4–5 triangle.

Independent vectors: receiver-to-source `d=(7,-7,11)/4`, emitter aim `e=(-1,3,-1)`, receiver orientation `n=(3,1,2)`. Scalar products give `r²=219/16`, `e·(-d)=39/4`, `n·d=9`, `|e|²=11`, `|n|²=14`. Therefore emission cosine is `39/√2409 = 0.794595693616460`; incidence cosine is `36/√3066 = 0.650154279447693`; inverse-square factor is `16/219 m⁻²`.

A 60-digit Decimal reference evaluates `1739 × emission × incidence / r²` as **65.635391847674616291… lx**. Actual `StudioPhotometry.illuminance` returns **65.6353918476746 lx**. Relative error against the exact binary Swift result is **2.8716355540e-16** (**2.8716355540e-14%**), below the unchanged **1%** point-model gate. Expected calculations use no production normal helpers.

Reproduce using the two Python commands in `commands.txt`; successful commands exit 0. Evidence: `probe.swift`, `probe.log`, `reference.py`, `scalar-reference.json`, `compile.log`. Initial probe compilation exceeded Swift's literal-expression inference budget; explicit `Double` annotations resolved it, preserving diagnostics in `compile-initial.log`.

No production edits or package builds. One synthetic host check only; area accuracy remains untested here, its **5%** gate unchanged. No calibration or device-performance claim.
