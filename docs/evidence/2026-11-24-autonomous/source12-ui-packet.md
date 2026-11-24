# Source 12 UI guidance and audit packet

Parent source: `95e9c2446b7bb05e6df38d103063b4254bb07c92`. The packet combines the independently reviewed Studio Guide, the evidence-supported studio/export CI budget correction, and two native accessibility audits. All three narrow patches preserve the source11 slider and plan corrections and every pre-existing UI assertion.

## Source changes and accounting

- P22 / T43: native read-only Studio Guide with six practical topics, measured header fallbacks, explicit44pt Guide action, Back/Done navigation and a real scene/history preservation regression. The fixed-grid wording was corrected and unique Done assertions were added after review.
- T44 within P08: keep studio/export verification bounded at40 minutes for its UI step and93 minutes overall, while the other two shards remain32/85. All three retain16 minutes beyond Metal12 + build25 + UI. This addresses a recorded CI budget shortfall, not a product-speed claim.
- T45 within P17: add default all-category native accessibility audits for the loaded Plan studio and exact intensity sheet, with no issue filters or suppression. Actual before-audit screenshots and bounded hierarchy will be collected when they execute. These are current-screen diagnostics, not manual device acceptance.

On successful publication this packet adds one integrated package and three tasks to the source11 counts, for22 packages and45 tasks. It is the twelfth source integration. Eleven complete local portable cycles have run; this UI-only packet does not invent a twelfth full local SwiftPM run. Native acceptance and release gates remain separate.

## Local verification

`source12-preflight/results.json` records44 native Swift source files syntax-parsed in Swift5 mode, all28 Python tests passed, all7 UI classes assigned exactly once, and clean production whitespace. All Package.swift, Sources Swift and Tests Swift inputs are byte-identical to source11, whose local/Ubuntu/macOS portable suites passed257/257. No redundant local full core run was performed. Exact-source CI remains required.

The resulting83 native unit methods and26 UI methods are authored counts. Source11's native83 pass does not execute the new Guide or audits. Native Guide navigation, header reflow, actual accessibility results and screenshots remain unverified for this packet. Every new audit issue will remain a test failure until corrected and rerun.

## Evidence

`studio-guide/` preserves all guide iterations, hashes, source, author report and independent review. `studio-budget/` retains the unchanged deadline logs comparison, patch and exact semantic budget validation. `accessibility-audits/` retains the two-file audit packet, inventories and independent review. Root's separate review is in `guide-budget-integration-review.md`. The checkpoint11/native reports preserve source-scoped core/native success and source10's two failed and one interrupted UI outcomes.
