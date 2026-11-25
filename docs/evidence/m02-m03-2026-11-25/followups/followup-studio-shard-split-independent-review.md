# Independent studio class/shard split review

**Scoped source approval**, against `9eddd97c5e638edf1768332d9d83d7dc2cccb72a`.

| File | SHA256 |
| --- | --- |
| `.github/workflows/ios-prototype.yml` | `83dbc72b9ce729514c304cb11e450cc76fcd8bd4929edb06e7e9fd858e22be60` |
| `UITests/StudioSmokeTests.swift` | `d6c19bb1084b8c33182f244a281cf84e007f4128eef2bb2d931560de39d6356e` |
| `UITests/StudioOpticsUITests.swift` | `371c45eb3fa6abbfdbfed941144203b72317a548cf3d4e3ee70409a569518c63` |
| `scripts/native_test_shards.py` | `d5ca836e698a4af22f2ecce5f23bea686e2cf64f55619fdaf7ee38e78ac5cd03` |

Independent exact reconstruction proves the remaining Smoke source equals the old file minus the contiguous ten-wrapper/full-optics-helper block. The new Optics source equals the original setup, makeApp and assertStatus definitions, copied unchanged, plus that unchanged block under its new class name. Shared helpers are still used as before. Each makeApp call has its own UUID fixture, so there is no shared stored state requiring the old class grouping. XcodeGen includes the entire UITests directory. All 36 method bodies remain represented once; the ten optics method identifiers change class, not behavior.

The shard parser changes only by adding the positive StudioOpticsUITests class mapping. No method-selector grammar, permissive fallback or retry is added. The resulting inventories are room5, library11, studio/export10 and optics10, with eight classes assigned exactly once. No stale qualified optics selectors were found in scripts/workflows.

Independent reversal of the new matrix entry and the two trace conditions restores the entire previous parsed workflow. Both studio shards receive the existing trace window/trap and collector, host captures, exact toolchain/runtime assertions, full and compact artifacts, and failure propagation. Existing bounds remain unchanged; the new optics shard has a 32-minute test and 85-minute job bound. UI max-parallel remains three and fail-fast remains false. More jobs can lengthen the total workflow; the source does not promise a faster or successful run.

The actual cbf failure completed 19 of 20 methods before its aggregate 40-minute deadline. Its ten optics methods totaled 1,099.740 seconds; the other nine completed methods totaled 1,023.135 seconds. That supports a balanced partition proposal, not a future duration guarantee or a finding about the interrupted method. The owner’s existing ten shard-check tests, method-bijection receipt and syntax checks were inspected. No Apple build, simulator execution, deadline relaxation, assertion weakening, test omission or production change was performed by this reviewer.
