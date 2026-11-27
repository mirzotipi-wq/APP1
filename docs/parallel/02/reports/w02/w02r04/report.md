# W02R04 — independent rolled rectangle regression

**Result: PASS for one standalone fixture; one XCTest candidate ready for root review.**

Input and frozen LightingCore v1 revision: `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b`.

`IndependentRolledRectangleReferenceTests.swift` uses the held-over 37° rolled, oblique partial-face fixture: 1.2 × 0.6 m rectangle, 0.6 m depth, 1000 cd. Fixed world-space receiver coordinates and normal keep the expected value independent of production frame changes.

The independent reference is **133.78670191052524 lx**, from direct world-space cosines integrated with composite Simpson over analytic slices. The method does not reuse production clipping or triangle quadrature. Refining the same fixture from 160 to 320 intervals yields 133.78670187718623 lx, a **2.49195e-10** relative change. The candidate retains the **5% area contract** and adds a **1e-6 fixture-specific relative bound**; no global gate changes.

The required helper compiled and ran one equivalent standalone Swift probe against the frozen production module. Actual: **133.78670187496377 lx**; relative error: **2.65807e-10**. Both assertions passed; exit 0, no compiler diagnostics.

**Standalone execution validates expressions; the candidate XCTest was not package-executed.** No production/test-tree edits, package builds, commits, pushes or cleanup. This is numerical model evidence, with no physical calibration claim.

Evidence: candidate, `probe.swift`, `probe-output.log`, `compile-output.log`, `reference_convergence.py`, `reference_convergence.json`, and `commands-and-provenance.md` in this directory. Root owns integration and package execution.
