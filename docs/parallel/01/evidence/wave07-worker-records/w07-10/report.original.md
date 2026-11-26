# W07-10 independent readonly challenge — preserved original

## Conclusion

Accept the narrow navigation/source integration, with native acceptance remaining open. No new source defect or hidden scene mutation, save, or export route was found in the reviewed change. This is an independent source/evidence audit, not native execution.

Reviewed clean detached HEAD: `46a161cb01d0aee2e91940dbd06d82cfe2df5821`. No source files changed, no commit created, no build or native test run, and no external action performed. An empty `source.patch` records the absence of worker changes. The manager may remove only this worker's worktree after verifying the preserved report, receipt and audit script.

## Exact integrated scope

The difference from portable CI source `5ccfbaae821a32d88c12ed8b3abf1600aef25753` is exactly:

- `App/StudioView.swift`, menu commit `5decbb0`: 10 inserted and three removed lines. Settings becomes reachable while loading, busy, or protecting saved data. The menu still disables during an active continuous edit. Subject/Arrange/AR retain their individual loaded/writable/idle disables. Subject now also checks captured generation and live edit state. Arrangement/AR use `openFeature`, whose live admission checks reject protected, busy or obsolete actions.
- `UITests/StudioSmokeTests.swift`, test commit `08e80c756cb7c8aa4eaf11f27932c8f701000be1`: one 75-line method inside the existing class. It waits for completed protected status, checks Save/Projects/export/Recipes and scene tools remain unavailable, opens Settings and actual Pro, returns through Settings to Studio, then relaunches the same UUID store after removing its corruption-seeding environment variable. It never taps purchase/restore/refresh.
- `docs/parallel/01/NAVIGATION.md`, documentation commit `46a161cb01d0aee2e91940dbd06d82cfe2df5821`: source map, existing coverage and explicit native gaps. No feature-owner, workflow or canonical state files changed in this interval.

Settings only owns display preferences and purchase presentation. Pro transactions remain explicit button actions. Save still routes through `beginLibraryOperation`, which rejects blocked/unloaded sessions before reservation. Export remains disabled at its unchanged outer menu. The protected screen omits the editable workspace. The pre-existing Plan subject marker sets a presentation flag directly; its actual typed binding uses guarded session mutation, and that marker is absent from the protected workspace. This is not a newly enabled save/edit/export path.

## Feature rejection and draft-loss boundary

The host forwards results to live session acceptance. Presentation identity, logical generation, accepted scene revision and busy/protection admission remain required. Retire/finish match the current owner; an old dismissal cannot close a replacement owner. Scene/lux results retire once after validation; room/AR retain repeated acceptance. Reference switches mode only after acceptance.

The three existing Void producers remain a material limitation: Reference clears photos/candidates before calling the parent; Arrangement sets `didFinish`; Lux sets `didApply`; all dismiss after their callbacks. A rejected mutation therefore does not imply a retained draft. Both `NAVIGATION.md` and `FEATURE_ADAPTERS.md` state this explicitly. The host's owner-scoped error asks the user to reopen. No producer fix is claimed.

## Independently reproduced checks

`audit.py` is a reproducible read-only verifier, run as `PYTHONDONTWRITEBYTECODE=1 python3 /workspace/scratch/e08d5190f17c/workers/w07-10/audit.py` from the worker tree. Exit 0. `receipt.json` records exact subprocess argv, exit codes, hashes, corrected nonexistent-path read attempts and evidence/source hashes.

Both 175-input manifests exactly cover their declared App/NativeTests/Sources/Tests/UITests/Package.swift/project.yml scope and match the corresponding Git blobs. Every current input additionally matches disk and HEAD. Only StudioView and StudioSmokeTests differ between the two source manifests. Current manifest SHA256: `d119b45806845017bcee97fb44ca019f59375bb058b7d680b1c2e0acc243a417`.

The retained current-source syntax receipt lists exactly all 82 native Swift inputs, reports parser exit 0, and has an empty log. This receipt was verified, not rerun. Static shard check exits 0 and exactly matches the retained output: nine UI classes, five required shards and one opt-in diagnostic shard. The exact new method `StudioSmokeTests.testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable` is discovered under required `studio-export`; no new test class exists.

The 471,293-byte CI log was parsed programmatically without dumping its text. Checkout source is exactly `5ccfbaae821a32d88c12ed8b3abf1600aef25753`, compiler Swift 6.4.2 Linux. Debug and Release each contain 431 unique cases with exactly one ordered start/pass pair, no failures, skips, duplicate events or omissions within the raw observed inventory. Total 862 passes and 1,724 case events. Both independently computed sorted inventory hashes match the receipt. Raw log SHA256: `00323fc554ab439fd44077bbd8535368b39fce4181080383d67a243c41af93aa`.

Historical workflow `45842239860` remains failed. Its retained log hash matches the failure receipt and contains the numeric-literal error. The explicit `Double(0.05).nextDown` correction and separate later portable success do not rewrite that history.

Startup `agent_cycle.py check` and `next` succeed; they validate references and select M03, not actual runtime truth. Existing canonical historical status was not changed by this audit.

## Recommendation and limits

Accept source integration and preserve all evidence. Keep Apple compilation, actual UI navigation, Observation/sheet lifetimes, device/AR and StoreKit validation open. In particular, the new method has not executed in this worker or in the older portable CI log. Do not transfer the 5ccfbaa portable passes to the later 08e80c7 menu/test behavior. The unchanged legacy producer draft-loss API gap remains explicit owner work.
