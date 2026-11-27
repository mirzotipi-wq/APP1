# W07-05 — concurrency review

Base: `08e80c756cb7c8aa4eaf11f27932c8f701000be1`. No repository edits or new commit.

**Conclusion:** No additional concrete late-callback scene overwrite or transition defect found in the inspected source.

- `App/StudioSession.swift:288` reserves before edit teardown; `:309` adopts committed receipts without a post-write cancellation gate. `App/ProjectStore.swift:40` checks cancellation before synchronous work. Child-observer cancellation cannot abandon adoption.
- `App/StudioSession.swift:140` consults live feature ownership and revision. Busy work rejects results; first save preserves logical context; successful switch/reload/recovery clears it at `:331`. Matching teardown cannot retire another owner.
- `App/LightingPlanExportView.swift:23` captures immutable export inputs. PDF option/cancellation guards at `:175` and backup worker cancellation at `App/ProjectBackupView.swift:95` protect export-local state; neither writes the scene.
- `App/KeyAndFillApp.swift:6` owns shared entitlements. `App/EntitlementStore.swift:231` intentionally finishes verified transactions independently of scene/sheet lifetime.
- **Retained limit:** Reference clears before its Void callback (`App/ReferenceComparisonView.swift:116`); arrangement/lux mark completion before theirs (`App/SceneArrangementView.swift:97`, `App/LightTargetLuxView.swift:108`). Rejected drafts can still be consumed. No repair claimed.

**Checks:** `agent_cycle.py check` and `next` succeeded; next selected M03. Git status/diff checks are clean. Reviewed input hashes match HEAD; commands, outputs and anchors are in `receipt.json`. Original preserved in `report-original.md`; empty `source.patch` preserves unchanged state.

**Recommendation:** Keep ownership boundaries; obtain producer acceptance callbacks and exact-source Apple lifecycle evidence. No builds/tests/syntax parse ran. Native Observation, export and StoreKit behavior remains unverified. No external actions. Root alone pushes.
