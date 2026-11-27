# A087 — welcome title query repair

The original opted-in DEBUG hierarchy contains two StaticText nodes named `studioWelcomeTitle`: an empty-label wrapper and the actual text labeled `Start your first portrait`. Both have recorded geometry values and visible frames. The original log fails before a drag or geometry attachment. The suppressed snapshot exception was not recorded, so its precise identity remains inferred.

The test now queries both exact identifier and exact expected label, asserts exactly one match, and then passes that real element into all unchanged intrinsic-layout, largest-font and viewport checks. Dismissal uses an identifier-only query’s first match, so a residual wrapper keeps the existing ten-second disappearance expectation from passing. No new wait is added.

Only `UITests/BetaAccessibilityUITests.swift` changed. No app code, helper, deployment target, method, image requirement, font, threshold or deadline changed.

DEBUG and Release syntax parsing and targeted diff checking exited zero. `query_probe.py` replays eight label/identifier scenarios against the captured hierarchy and verifies the exact two-hunk scope. It accepts optional repository and hierarchy paths; its Git baseline is pinned to `135d3b4755d97bbb8fcff993d8dfd532a8d48b93`. This Python replay is not live XCTest execution, and syntax parsing is not Apple compilation. Fresh native UI execution remains required.
