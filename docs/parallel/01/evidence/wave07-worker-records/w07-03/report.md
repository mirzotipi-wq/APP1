# W07-03 API review

Reviewed `08e80c756cb7c8aa4eaf11f27932c8f701000be1`; no source changes or new commit; tree clean.

Reference, Arrangement and Lux still consume rejected drafts. Their required `onApply` callbacks return Void. Reference clears photos/candidates before callback (`App/ReferenceComparisonView.swift:117`); Arrangement/Lux mark completion before callback and dismissal (`App/SceneArrangementView.swift:105`; `App/LightTargetLuxView.swift:114`). No acceptance or owner-close callback exists.

ManualRoom/AR provide optional Bool change/removal and Void close callbacks. False retains the draft and reports rejection; true acknowledges it. Nested manual close remains local to AR (`App/ManualRoomPlacementView.swift:158`; `App/ARPlacementView.swift:63`).

The host uses captured snapshots for one-shot producers, live scene for Room/AR, and matching-owner retirement/teardown (`App/StudioFeatureSheets.swift:10`). Session feature Bool means acceptance, including valid no-ops; ordinary command Bool means mutation. Scene/Lux retire after acceptance; Room/AR can repeat (`App/StudioSession.swift:146`).

Settings/Pro use separate local sheets. Protected storage still blocks scene tools/export while permitting Settings. Export captures an immutable scene without a mutation callback (`App/StudioView.swift:332`; `App/LightingPlanExportView.swift:16`). The added navigation test is one existing StudioSmokeTests method.

Checks: startup reads, source/hash review, clean Git diff, agent_cycle check/next exit 0. M03 remains selected. No build, syntax parse, tests or native verification ran. Root’s separate 12-test Swift6.0.3 receipt does not pass retained Swift6.4.2 failure 45842239860.

Recommendation: owner-provided synchronous Bool acceptance before cleanup; native rejection/no-op/close tests. Original, hashes and empty patch preserved beside receipt.json.
