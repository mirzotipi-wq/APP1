# Required studio optics shard with unchanged test bodies

## Observed budget failure and bounded response

Exact cbf run **45623581873**, studio job **139252380183**, completed **19 method passes, zero terminal method failures/skips, and one started/interrupted method**. All ten optics workflows passed. The final `testStudySwitchesBetweenSphereAndMannequinWithoutEditingScene` started at 14:40:49.867207 UTC; the required UI step hit its unchanged **40-minute** limit at 14:41:07.226148, 17.359 seconds later. No finalized result bundle was available. This is an interrupted final test, not a completed 20/20 result or a demonstrated defect in that final workflow.

The [source-bound budget receipt](../validation/studio-shard-split/budget-source-summary.json), selected from the actual terminal summary with its original hash, records **1,099.740 seconds for the ten completed optics methods** and **1,023.135 seconds for the other nine completed methods**. These measurements motivate separating the workloads; they do not predict the next run. A separate optional pre-test host-capture timeout is retained in that receipt and does not change the required UI-step timeout evidence.

The candidate is based on published **9eddd97c5e638edf1768332d9d83d7dc2cccb72a**. Only the four authorized source/configuration files below were changed for this split. It adds one standard Intel host setup and its build/boot/artifact work. With maximum concurrency still three, a fourth job may queue. No paid tier, larger host, deadline relaxation or measured speedup is claimed.

## Exact partition

| Required shard | Assigned classes | Methods | Test/job bounds |
| --- | --- | ---: | --- |
| room-precision | ManualRoomPlacementUITests, PrecisionEditingUITests | 5 | Existing 32/85 minutes |
| library-reference | ProjectLibraryUITests, ReferenceComparisonUITests, AccessibilityAuditUITests | 11 | Existing 32/85 minutes |
| studio-export | StudioSmokeTests, LightingPlanExportUITests | 10 | Existing 40/93 minutes |
| studio-optics | StudioOpticsUITests | 10 | New 32/85 minutes |

`UITests/StudioOpticsUITests.swift` receives the ten existing optics wrappers and the complete private `runOpticsEditingUndoRedoAndRelaunch` implementation **byte-for-byte**. Its `setUpWithError`, `makeApp` and `assertStatus` helpers are exact copies; the original helpers remain in StudioSmokeTests. The other eight smoke methods plus two export methods remain in studio-export. The optics workflow does not depend on the old private `reveal` helper.

The moved block SHA256 is `57c9d2b00bb26f008c144f3f1ca3a81f80171fdc299b44e963ac1b929a77de3f`; copied helper block SHA256 is `91c8fd22df0f24224f292024a8c2991f5e974f73be933b99217c55ee9c527305`.

`scripts/native_test_shards.py` assigns the new class once. `.github/workflows/ios-prototype.yml` adds its required matrix entry on the same `macos-26-intel`/x86_64, Xcode 26.6, iOS 26.5 environment. All original matrix entries/deadlines remain unchanged; `max-parallel: 3`, `fail-fast: false` and `-parallel-testing-enabled NO` remain. Both the studio trace-start condition and always-run trace collector now include studio-optics; the commands and artifacts otherwise remain identical.

No test action, assertion, per-test wait, fixture, audit or product source changed. The optics XCTest class identity intentionally changes; the exact method map preserves historical-to-current names instead of claiming unchanged full identifiers. This is an execution partition, not a missing test exemption.

## Validation actually performed

- All **36 test declarations/bodies** have a one-to-one mapping with byte-identical contents. The remaining smoke source is exactly the prior file minus the contiguous moved optics block. New optics source is exactly the new class wrapper plus the copied helpers and moved block. Other UI files match the captured split baseline.
- The selector check reports **eight classes assigned once across four shards**, inventories **5/11/10/10**; the new selector is `-only-testing:KeyAndFillUITests/StudioOpticsUITests`.
- All **ten existing shard tests passed**, covering missing/duplicate/stale classes, nested discovery, invalid matrix membership, empty/unrecognized suites, unit/UI separation and fail-closed unknown selectors. Command: `python3 -m unittest discover -s scripts/tests -p test_native_test_shards.py -v`; observed 0.010 seconds, zero failures/errors.
- YAML parse, **29 bash blocks** (`bash -n`) and **seven inline Python blocks** (`ast.parse`) passed. Parsed workflow comparison permits only the fourth matrix entry and two trace guards; all other workflow structure is identical.
- Linux `swiftc -frontend -parse` passed for both studio files. Whitespace checks passed. This is syntax/source validation, not Apple typechecking, native execution or a performance measurement.

The [packet index](../validation/studio-shard-split/README.md) links the exact baseline slices, complete 36-method hashes/mapping, validation and diff. [Copy provenance](../validation/studio-shard-split/copy-manifest.json) binds the frozen outside report and this repository edition; only relative provenance links changed. The separate keyboard helper candidate remains unchanged at `cde53fae85e741f18d10fea9ac2c23080cf3b7dd225c7ae8affa6eb459bac05f`.

## Frozen candidate hashes and next verification

- StudioSmokeTests.swift: `d6c19bb1084b8c33182f244a281cf84e007f4128eef2bb2d931560de39d6356e`
- StudioOpticsUITests.swift: `371c45eb3fa6abbfdbfed941144203b72317a548cf3d4e3ee70409a569518c63`
- native_test_shards.py: `d5ca836e698a4af22f2ecce5f23bea686e2cf64f55619fdaf7ee38e78ac5cd03`
- ios-prototype.yml: `83dbc72b9ce729514c304cb11e450cc76fcd8bd4929edb06e7e9fd858e22be60`

Root and a097 review precede publication. Actual Apple compilation and all four required shard outcomes must be observed at the eventual published revision. Each of the ten optics workflows and the previously interrupted non-optics method still needs a complete terminal outcome there; no future revision, complete CI pass or gate promotion is asserted.
