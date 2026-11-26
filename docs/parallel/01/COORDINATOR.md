# Coordinator checkpoint — persistent checkout

## Mission and ownership

Finish exactly 100 actual fresh contexts in ten waves of ten, on finish/01-architecture-composition only. Wave roles acceptance (also scheduler), data, API, implementation, concurrency, lifetime, integration, accessibility/privacy, platform/performance, independent review. Root+manager+two peers is real capacity4. All new spawns fork_turns:none; briefs<=2000 tokens, working target<=12000, reports<=800. Followups count zero. Root owns integration, expensive tests and publication; CI lane19, canonical status/main integration lane20. Do not edit other feature-owner files. Baseline f150f98e35dd735927075aac4d2f8b02295c6a67; main9e0e2ba has later native-test correction to preserve. No lane20 BASE_SHA yet observed.

## Active state

Waves1/2 complete20 workers, committed ledgers/reports. Fresh wave3 scheduler /root/w03_acceptance and peers02,04,03,10,05,06,07,08 have been created:29 actual at this checkpoint.09 not yet created. Manager sends actual IDs and maintains /workspace/scratch/e08d5190f17c/workers/w03-01/w03-ledger.json. Seven pre-reset contexts had reports preserved;07/08 are active;09 follows within capacity. Do not infer completed wave3 until manager reconciles all ten.

## Filesystem and publication

Temporary filesystem has reset twice, losing unpushed worktrees/builds. Durable root is /workspace/scratch/e08d5190f17c/keyfill-01 (sparse partial clone). It has only current branch shallow history; old unpushed commit IDs are historical, not reachable. /workspace is nearly full (~7 MB free); create only needed sparse worker trees. Four current persistent trees w03-01/07/08/09 in sibling workers/. Reports remain outside trees. Do not delete others' files. Clean only read-only published-source trees after preserving reports. Raw tests/logs live in repo, not /tmp.

Shared compiler restored at /tmp/keyfill02-r2-toolchain/usr/bin/swift (6.0.3). Swift frontend SHA f92b96b425e37c7080fe428e5f41c96ca0398f78d15b3624f5f59dcbc97ac997 and package SHA5bba7467db63edc678d0bd255f827ed70ae91728210166b6aabe56d5a82a69d2 exactly match prior provenance. Use build /tmp/keyfill01-build-v3, cache /tmp/keyfill01-cache-v3, --jobs1 -Xswiftc -disable-batch-mode. No Apple SDK.

Last verified remote966c9c21adbb685d82127e7f88981b74daf47e3d, tree02b0ab60505069930f13f3defad63e5c32a68776. Current restored local code6fe2cfab49f1b087553f65341f4471f786b309f9. GitHub connector account link_6b0496ede3088191ad7f6c85f178a8a8 repo mirzotipi-wq/APP1. Publish by create_tree(base remote tree, changed entries content UTF8), assert complete tree SHA matches local; create_commit(parent remote); update_ref expected SHA, force:false. Fetch, assert tree equality, preserve local ref and soft-reset to remote. Verify ls-remote. No main push. Pure JS functions stores retain previous publication manifests and source text.

## Current code and evidence

StudioEditorState owns validated scene/selection/revision/history. StudioSession owns editor/library/task reconciliation and cumulative PlanDrag; reservation fails before touching gesture; successful reserve closes gesture/history. editOwner uses workspaceResetID, stable across first save and metadata, rotates document switch. StudioView renders read-through state. Core feature context/session exists but native route guards remain equality-only/unwired.

Wave3 fixed an actual View adapter bug: end-edit called unguarded session.endEditing whereas begin checked generation. New View helper delegates BOTH to session.editChanged(editing,owner:from:). Native StudioSliderTracking retains begin-time closures, so a stale false after first save must not close newer same-control group. New actual session test covers admission/grouping; it also passes pre-fix session, so View-path correction has STATIC verification only, not Apple runtime proof.03/10 independently accepted exact original4a9f964 delta.

Worker04 original bab813c5125b112c77ed367b184a3f5a88fae711 added six Plan tests, 277 lines. Recovered source SHA817b934859c173ee96fa40ac374c0047636f0460bf0ca9085cb568d6f2aa6e3d matches exact original and is integrated as NativeTests/StudioPlanSessionTests.swift plus Package membership. Reports and superseded drafts recovered under sibling w03-recovery/. All seven earlier report hashes/variants verified.

Root added meaningful two-window real-store conflict/recovery test (same light IDs, distinct editor generations/scopes, foreign callback rejection, both scenes preserved on disk, other window unaffected). Its first attempted execution never started when tmp vanished. Current full Debug run at6fe2cfa completed:400 actual tests passed,0 failures (11 session+6 Plan+383 core), including two-window storage recovery. Native syntax passed;169-input source manifest and full raw log are durable in docs/parallel/01/evidence/wave03-restored. Scheduler independently checked all169 hashes and17 actual session method passes.

Earlier verified fresh source: full392 atlocala98be93; affected9 at66aec8b; source/rawlogs published in evidence/revalidated at966. Then10 session at4a9f964 and16 session+Plan at906049f passed, but their raw logs were lost in second reset (terminal excerpts in conversation only). Do not fabricate recovered logs. Recovered current source needs fresh full evidence and syntax.

## Remaining waves

Finish wave3 ten workers, inspect reports, integrate substantive defects, publish exact evidence/ledger.05 notes sequential .load currently can reset a dirty session if directly called; UI fences current path. Decide model guard in wave5.06 observes session weak-release test does not directly measure store release; no leak claim. Reference Void Apply clears local photos/candidates before parent callback; native API requires owner-provided acceptance/draft contract for complete rejected-draft preservation.

Wave4: closed typed commands on already validated editor; avoid full unchanged imported-name scan per scalar update. StudioLightField cases positionX/Y/Z,candela,kelvin plus read/domain. StudioFieldCommand light scalar/position/optics, camera/subject position, lens/preview, optional room. Validate payload/live UUID; no public unchecked mutation closure or raw keypath. Full validation remains init/arbitrary update/replace/adopt/import. Share private normalized update commit helper; preserve nil-default/roll history normalization, stable UUIDs/SI/schema, no-op/invalid atomicity. Root View/session bindings migrate; implementation peer can own core commands+editor change, data/test peer separate new test file.

Wave5: live owned feature admissions; consider separating stable document workspace identity from storage-operation generation so first save can preserve same feature draft while stale storage callbacks reject. This is a DESIGN PROPOSAL, not current contract or implementation. Need peer challenge. Receipt checks owner, document generation, accepted revision, busy/loaded. Repeated own room changes advance receipt; unrelated edit/undo ABA rejects. Retire synchronously and clear only matching owner.

Waves6/7: wire available feature adapters/navigation with accepted-no-op Bool, nested AR room single undo, pending-work preservation. Available remote branches last inspected01–05 only, no reference/AR owner adapter branches; inspect again. Strict feature ownership remains.8 package/generated targets;9 duplicate state/lifecycle/undo independent challenge;10 final source-specific evidence and precise lane20 handoff. Native UI/AR/StoreKit unavailable is unverified.

## Wave 3 complete

All ten wave 3 contexts completed, including09. Exact campaign count30, remaining70. Reports/normalized wave ledger/aggregate ledger are saved in root; original manager ledger and recovered report variants retained. Full400 Debug and native syntax at6fe passed;169-input manifest independently verified. Publish this checkpoint next, then fresh wave4 manager plus9 peers. Existing read-only w03-01/09 trees are clean and may be removed after this checkpoint;07/08 already removed, reports preserved. Use compact/non-cone sparse workers to exclude agents/history and old evidence when needed; only active worker trees are necessary. Native behavior remainsunverified.
