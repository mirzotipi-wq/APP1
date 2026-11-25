# Focused launch/readiness diagnosis

Existing worker a099; read-only follow-up at `cbf94cecb113c1f03b0b8c7287e763655c14ec11`. `git diff f6f43dde… cbf94ce… -- App Sources` is empty. Production line references below therefore apply to f6. Repository: `/var/tmp/keyfill-c0abc39c4f18/APP1`. No patch, build, new test, rerun or repository-document edit was performed.

**No decisive reproducible product defect or actual duplicate accessibility node is established.** The useful distinctions are load-state readiness, element exposure/query delivery, and a concrete extra decode in the large-library fixture.

## 1. Shared control-state path

`App/StudioView.swift:313,388` enables Save and Projects exactly when `loaded && !saveBlocked && !libraryOperation.isBusy`. The initial Projects button does **not** require a saved project. Startup `.task` at line 263 reserves `.load` through lines 1300 and 1318. The store actor performs directory/fixture/file operations (`App/ProjectStore.swift:39–45,79–127`); the parent awaits it before adopting.

Normal success clears the pending request (`App/ProjectLibraryOperation.swift:103–140`) and sets `loaded=true`, `saveBlocked=false` (`App/StudioView.swift:1342–1351`). A normal load error clears pending and sets `saveBlocked=true`, `loaded=true` (1358–1363), displaying the protection/error state. Fresh UUID tests without an existing file should adopt a draft and enable both controls. No deterministic always-disabled condition was found for those launches.

For archived-delete and unsaved-setup, the first readiness wait occurs before any user action and with a fresh query/UUID (`UITests/ProjectLibraryUITests.swift:111–118,330–337`). Their failures cannot be attributed to their later archive/delete/save operations. Existing logs show slow idle/hierarchy queries but no returned missing-versus-disabled state.

**Discriminator:** the newly logged failure hierarchy should distinguish `Opening projects…`/operation progress, protected-data error, a disabled control, or an absent control. If these remain inconclusive, a small timestamped reserve→store-return→adopt/error trace with `loaded/saveBlocked/pending` would distinguish storage completion from main-actor adoption/query delivery. No full saved document is needed.

## 2. Concrete large-fixture cost

With `KEYFILL_UI_TEST_LARGE_LIBRARY=1` retained on relaunch, `ProjectStore.prepareStore()` first calls `store.load()` to avoid recreating an existing fixture (line 104); `perform(.load)` then calls it again (line 45). Each read decodes and validates the library (`Sources/LightingCore/ProjectLibrary.swift:151–161`), including its four-million-combining-mark name. This is two complete reads/decodes on the store actor; their contribution to the UI timeout is unmeasured. Display text is already bounded by `StudioDisplayName`, so an unbounded heading-layout diagnosis is unsupported.

Counterevidence: the actual f6 native `testLargeLaunchFixtureUsesRealBoundedBytesAndRetainsSavedEditsOnRelaunch` passed the complete creation/save/reopen scenario in **7.904s**. That establishes successful contents on its native runner, not a timing guarantee for a separate loaded UI runner. If the next failure still shows opening/busy, phase timings can identify which read or adoption stalled. Do not increase the 15-second predicate budget or remove the fixture to hide it.

## 3. Tenth optics: no incorrect label was recorded

Successful `.load` adoption assigns `scene` and `saved` from the **same decoded active scene** (`ProjectLibraryOperation.swift:109–115`; `StudioView.swift:1343–1344`). The status is computed from `saveBlocked` and `saved == scene` (355–356). Slider configure/synchronize reads the model; value events without a tracking token return without editing (`App/StudioSlider.swift:134–151,217–240`).

The relaunched process configured width **2.1** at **12:50:24.758**, before the status predicate began at **12:50:29.722**. Inspector construction is behind the loaded/unblocked branch (`StudioView.swift:91–111`). This supports successful adoption before the predicate. The test log contains existence retries and a timeout, not a sampled wrong label. Without an intervening edit, the code predicts “Saved locally.” Missing/delayed AX exposure remains plausible; disk loss and an actual “Unsaved changes” label remain unproved.

The new `assertStatus` failure snapshot can supply the actual label, frame or snapshot error. It is captured **after** the original timeout and must not be mistaken for a sample from every earlier instant.

## 4. Identity and adaptive-layout hypotheses

There is one source assignment per identifier, but `header` constructs `projectHeading` in two `ViewThatFits` alternatives (`StudioView.swift:324–344`), and `projectActions` similarly constructs Projects twice (366–377). Alternative construction does not prove simultaneous AX duplicates. No actual duplicate count/hierarchy was retained from f6. Verify repeated identifiers and frames in the new hierarchy before changing layout.

Save is a single pinned editing-bar instance outside those alternatives (278–320), so header duplication would not explain every failure. The large test reuses its Save query across relaunch; initial Projects queries are fresh, and `assertStatus` creates a fresh status query on each call (`StudioSmokeTests.swift:14–18`). A stale-query explanation therefore cannot cover all cases either. Preserve checks and inspect the newly added diagnostics first.
