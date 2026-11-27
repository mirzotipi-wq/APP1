# W03-03 — Native API and source membership

Frozen HEAD: `966c9c21adbb685d82127e7f88981b74daf47e3d` (detached, clean). Read required documents. Checks: source reads, `rg`, `git rev-parse/status/log`, filename reconciliation, separate `git show`. No builds, parsing, tests, installation, CI, source or status edits.

## Finding and recommendation

**P2; block frozen adapter acceptance:** `StudioView.swift:1141–1147` ends editing without checking captured generation. First save retains control owner but changes generation (`StudioSession.swift:99–110,160–164`); an old end can close a newer edit on that control, splitting undo.

Separate fix `4a9f964f0b1748c883a43a2940452014767683e5` routes both phases through the session's generation-checked `editChanged`; its added regression exercises this case. **Accept correction statically; execution not claimed.** The frozen tree lacks it.

## Other review results

- No further concrete adapter defect established. `StudioView.swift:4–6` owns one retained `@State` session inside `WindowGroup` (`KeyAndFillApp.swift:13–18`). Projections44–63 and library bindings245–250 read live state; no second editor copy found.
- Session/view/app are `@MainActor`; native session is `@Observable`, ignoring task bookkeeping. iOS17/Swift5 language mode and Swift5.9 package tools align (`project.yml:5,23`; `Package.swift:1–6`). Apple supports Observable State on iOS17: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app/
- `$session.showRecoveryCapacity` projects owned State to a writable property. Other bindings read live values and guard captured generations. No additional `@Bindable` requirement established.
- Xcode includes App/NativeTests and links only LightingCore (`project.yml:13–19,38–44`). Package includes three composition sources and session tests (`Package.swift:62–66,89–91`). All 46 App/20 NativeTests Swift files are accounted for, with no nonexistent entries. Conditional imports select the correct module. Frozen session inventory: **9 methods**.

## Residual verification

Apple SDK typecheck, Observation updates, bindings/sheets, window isolation and first-save focus/caret/undo remain unverified. Linux excludes Observation; syntax cannot validate SwiftUI APIs. Historical 392 Debug predates identity changes; only affected 9 reran afterward. No outcomes transferred. Feature-route revision admission remains explicitly pending.
