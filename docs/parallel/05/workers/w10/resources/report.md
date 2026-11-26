# W10 resources audit

**Inputs:** documentation `1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a`; production `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`; baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`.

**Executed:** read-only Git inspection, Python JSON/SHA256 checks and integer arithmetic. Inspected `AGENTS.md`, architecture/design/current acceptance, and `docs/parallel/05/{HANDOFF.md,RECOVERY.md,WORKER_LEDGER.json,workers/w01–w09}`. No builds, installs, native execution, source changes or ref updates.

**Ledger:** 90 unique completed canonical contexts, ten per wave; every source-ledger ID matches. Role-label aliases normalize consistently. Root and repeated followups receive no credit. All **80 ledger-bound hashes** match: 70 whole reports and ten embedded W02 recovered texts. All **176 entries across seven manifests**, plus five report sidecars, match. W01's ten summaries retain explicit original-report loss and null hashes.

**Archival defect:** `workers/w08/resources/report.md` under that documentation directory declares an incorrect embedded Findings-body hash. Extract the UTF-8 bytes immediately after `## Findings\n`, preserving the final LF. Declared:
`1ee0c18e97d4e38b34c9acbbf87e1824c316e06a85a087b42895b2b86a2da861`
Actual:
`950f0f790e637e5df84cbab78326f45a1759fd7d1f33716fee63b283db5b5cd7`
Its ledger/manifest/sidecar **whole-file hash is correct**. Root should append a superseding clarification while preserving historical bytes.

**Topology:** independently rederived from `Sources/LightingCore/Scene.swift` and `App/{SpatialPreview,StudioEntityGraph,RealityStudioPreview}.swift`. For N≤12 lights and S≤N elevated stands, SceneKit owns 8+4N nodes (maximum56), attaches 8+3N+S, and has 5+2N+S direct content children. RealityKit owns 53+24N graph entities plus two camera entities (maximum343). These count explicit source-created objects, including disabled/detached retained objects, excluding framework internals and external witnesses.

**Provenance/limits:** four executor interruptions and W01 summary-only recovery remain explicit. W06 reconstructed resource JSON lacks an original digest; W07 measurements are parent-provided. W10 `dispatch-resources.jsonl` records UTC host free-space/MemAvailable snapshots, not application usage or peaks. Wave creation remains in progress. No leak, deallocation, FPS/device, renderer-thread atomicity, manual-accessibility or measured token-compliance claim.

**Owner dependency:** root owns the append-only clarification, final W10/hash completion, aggregate100 verification and separately dated current-source receipts. Historical pending cutoffs remain preserved. No new production resource defect found.
