# W08-08 — privacy and accessibility source review

Reviewed clean `46a161c` (native source `08e80c7`) and current root configuration. No source changes or commit.

- `PrivacyInfo.xcprivacy` is tracked, declared as an app resource, and matches the verifier policy and wave08 manifest. Sparse absence is expected. It declares no tracking/collection, UserDefaults reason CA92.1, and file-timestamp reasons C617.1/3B52.1.
- Camera purpose is declared in generated Info settings; camera authorization starts from the explicit AR button. The commerce product ID defaults to blank and disables sales; displayed prices come from StoreKit.
- Shard validation exits 0: 189 native methods; 36 required UI methods plus two diagnostic methods. These are source counts.
- The protected-storage method occurs once in existing `StudioSmokeTests`/`studio-export`. It asserts Settings → Pro → Settings → protected Studio, disabled mutation controls, and same-store relaunch. It invokes no purchase, restore, refresh or camera action.

The navigation method does not assert privacy prose, Settings/Pro largest-text layout or VoiceOver behavior. Native generation, bundle resources, Apple compilation, camera permissions, UI execution and commerce acceptance remain **UNVERIFIED**. Existing rejected-draft limitations remain unchanged.

`agent_cycle.py check` and `next` exit 0; M03 gates remain outstanding. Git status stayed clean. Full hashes, commands and limits are in `receipt.json`; `source.patch` is empty.
