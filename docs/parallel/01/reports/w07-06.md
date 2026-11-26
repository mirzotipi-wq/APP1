# W07-06 — resource lifetime review

**Conclusion:** No new confirmed ownership defect. Inspected routes match NAVIGATION.md. Read-only at `46a161cb01d0aee2e91940dbd06d82cfe2df5821`; no changes or commit.

- **Known loss remains:** Reference clears photo/candidates before Void Apply (`ReferenceComparisonView.swift:115–123,520–535`). Parent rejection cannot restore them; arrangement/lux share the documented limitation.
- **Photo lifetime gap:** Parent and comparison have separate state; child Done clears only its slots. Request IDs reject obsolete import/analysis results. Reference’s unstructured tasks depend on explicit close or the UIKit dismissal observer (`ReferenceComparisonView:432–535`; `PhotoComparisonView:348–398`). Parent reset/removal while already covered, cancelled swipes and actual photo-picker coverage need native verification. This is an uncovered path, not a proven leak.
- **AR boundary:** Nested manual Done changes only its matching local owner; outer Done retires Studio ownership and stops the controller (`ARPlacementView:54–106,243–247`). Existing smoke closes one child without room mutations; repeated commit/close/reopen remains uncovered.
- **Export ownership:** PDF shares immutable Data; backup uses immutable FileDocument with cancellation forwarded to its detached worker (`LightingPlanExportView:7–12,175–190`; `ProjectBackupView:75–121`). No app temporary-file leak found. PDF rendering is synchronous on MainActor; cancellation guards publication, not mid-render work. Provider/share success, cancellation and failure remain unverified.

**Actual checks:** Required startup documents; status/HEAD/log; agent-cycle check/next both exit 0; 35 source SHA-256s match HEAD. Clean tree; empty patch preserved. One search’s nonexistent-file errors are retained and corrected.

**Recommendation:** Accept source mapping; retain Void API owner work and execute the lifecycle/provider cases above. No build, parse, native runtime, camera/photo/export/commerce action or push ran. Original detail and command evidence accompany receipt.json.

