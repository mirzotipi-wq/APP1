# W07-02 — protected-storage navigation

**Ready for integration; native execution unverified.** Commit `237165afc4a060db8eebd5b8946a2b9a69717c2f` changes only `UITests/StudioSmokeTests.swift` (+75 lines). Root authorized the existing-class placement because a new class would fail closed shard discovery.

The new `testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable` waits for the exact protected-load status, then checks disabled Save, Projects, Export and Recipes, absent editing controls, enabled Tools, and disabled Subject/Arrange/AR actions. It exercises Settings → purchase options → Pro close → Settings Done → Studio, then rechecks protection and relaunches the same UUID store without recreating corruption. Existing identifiers, English arguments and condition-based waits are used.

Actual checks passed: startup `agent_cycle.py check/next`; `git diff --check`; Swift6.0.3 `-frontend -parse` (syntax only); UI shard consistency; discovery of the new method in `studio-export`. The committed tree is clean.

Source inspection predicts baseline failure at the enabled Tools wait; no runtime red/green result is claimed. No build, Apple typecheck, UI run, purchase/restore, camera/photo action or push occurred.

Recommend integrating with W07-04 and running this method on the simulator. `receipt.json` records commands/results and source hashes; `source.patch` and `report.original.md` preserve the change and original report.
