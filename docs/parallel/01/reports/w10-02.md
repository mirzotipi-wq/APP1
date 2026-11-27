# W10-02 — native adaptive-layout regression

Added one native XCTestCase/method in `NativeTests/StudioAdaptiveLayoutTests.swift`, committed as `61183b6dfcabedd6c7df71cdf97f6f3dff39200f`. Only the owned file changed; detached worktree is clean.

The real UIHostingController fixture nests the production helper like StudioView's header/actions. Eight phases cover wide→narrow→wide, explicit outer-column forcing, accessibility5 at wide/narrow widths, and return to normal. Three actual child @State UUIDs must remain distinct and unchanged. Revision/environment-tagged attached UIKit probes supply live frames after bounded layout/main-queue passes. Assertions cover finite containment, spacing/nonoverlap, wide trailing actions, actual Text wrapping and accessibility growth. The original key window is restored. No sleep, production hook, source-string assertion or copied layout algorithm is used.

Inspected baseline `adffee463896ba3484a6dde883f7e6745a4c0c6e` and final production helper/wiring at `7cfab9d98895dbb36685f14191ddabaced4b323f`; receipt pins blobs. Fixture preserves outer-only accessibility forcing. W10-03 independently found no source-level iOS17/Swift5.9 API mismatch.

Validation: mandatory agent_cycle check/next exited0 (structure only); Swift6.0.3 frontend parse and staged diff check exited0. Apple compilation and native execution remain unverified; no builds or pushes ran. Root must add the explicit Package.swift exclusion and execute native acceptance. Exact patch and provenance are retained beside this report. Requested working-token usage is unmeasured.
