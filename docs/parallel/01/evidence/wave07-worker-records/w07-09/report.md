# W07-09 — platform/performance review

**Accept for source integration; native execution remains unverified.** Base: `46a161cb01d0aee2e91940dbd06d82cfe2df5821`. No source edits or new commit; worktree clean.

- `project.yml` includes `UITests`. The existing `StudioSmokeTests.testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable` is discovered and selected through `-only-testing:KeyAndFillUITests/StudioSmokeTests`. The workflow passes those selectors and checks all discovered methods. No lane19 inclusion change is needed.
- Inventory: **189 native methods; 36 required UI methods**, partitioned 5 room/precision, 9 library/reference, 11 studio/export, 10 optics, 1 accessibility; **2 separate opt-in diagnostics**. All nine UI classes are assigned once.
- Utility diff `5decbb0` adds constant-cost Boolean/UUID guards; no new traversal, task, renderer, or I/O. No measured performance claim.
- Independently parsed CI at `5ccfbaae821a32d88c12ed8b3abf1600aef25753`: **431 unique ordered start/pass pairs per Debug/Release, 862 passes**, zero failures/skips/duplicates. Log and inventory hashes match.
- Both **175-input manifests** match Git; later `08e80c7` also matches disk. Only StudioView/StudioSmokeTests changed after CI. Its **82-input syntax receipt is syntax only**.
- Boundary log/hash confirms **12 targeted passes**; historical run `45842239860` remains failed.

Checks: agent-cycle check/next, shard check/selector emission, programmatic event/hash reconciliation, clean status/diff. No builds, reruns, Apple execution, or external actions. Full commands and retained parser-helper corrections: `receipt.json`; expanded original: `report.original.md`.

Recommendation: retain current selectors; require source-specific Apple validation before native acceptance.
