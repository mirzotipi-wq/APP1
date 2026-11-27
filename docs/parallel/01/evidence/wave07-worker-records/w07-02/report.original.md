# W07-02 protected-storage navigation regression

The new regression is committed and ready for integration with the narrow Tools-menu implementation. It does not constitute native runtime acceptance. The source-derived expected baseline failure is at the wait for an enabled Tools button: the base StudioView disables that entire menu when saved data is protected.

Root explicitly changed the allowed source scope through the acceptance manager. The original requested new XCTestCase file would fail the repository's closed shard discovery. The authorized final change therefore adds exactly one method, testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable, inside the existing StudioSmokeTests class. No candidate new file was written, no CI configuration changed, and no implementation file changed.

The method uses the existing makeApp(corrupt: true) helper, which supplies -ui-testing, a fresh UUID for KEYFILL_UI_TEST_ID, and KEYFILL_UI_TEST_CORRUPT=1. English language and US locale arguments keep the existing menu labels deterministic. It waits for the exact completed-load Saved data protected status using the existing immutable accessibility snapshot helper; initial disabled Save cannot pass readiness. It requires the Project unavailable heading, disabled Save/Projects/Export/Recipes, and absent add-light/reference editing controls.

The regression then requires Tools to become enabled and reachable. Subject position, Arrange setup and Place in AR must remain present and disabled. Settings opens through its real menu action, purchase options must open the actual Pro navigation screen, closeProFeatures must disappear after closing, and Settings Done must become enabled and hittable before dismissal. Protected state is rechecked after returning to Studio and after terminating and relaunching the same UUID store with the corruption flag removed. That relaunch checks persistence without injecting replacement corruption.

Commit: 237165afc4a060db8eebd5b8946a2b9a69717c2f. Exact changed source: UITests/StudioSmokeTests.swift, 75 added lines. Base: 4a2199d78ba52b9174381fdd1736f73e47959252. The committed worktree is clean.

Actual checks: agent_cycle.py check and next succeeded; they select active M03 and do not certify gate truth. git diff --check passed. Swift6.0.3 Linux -frontend -parse succeeded as syntax only. native_test_shards.py check assigned all nine classes across five required and one diagnostic shard. Direct discovery found the new method in the existing studio-export shard, nine StudioSmokeTests methods and 38 UI methods including diagnostics.

No build, Apple typecheck or native test was run. No red/green runtime result is claimed. No purchase, restore, refresh, camera/photo interaction or publication occurred. Preserve this original, the concise report, receipt.json and source.patch before manager cleanup. Integrate with W07-04 and run the named UI method on the actual simulator target.
