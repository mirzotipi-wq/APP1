# Main branch consolidation — 27 November 2026

## Result and publication boundary

All eight audited non-main branch tips are ancestors of integration source [`660b50a251f662b0207d0e5aab70fda748a77664`](https://github.com/mirzotipi-wq/APP1/commit/660b50a251f662b0207d0e5aab70fda748a77664). Three branches were already included in original main; five finish branches contained **100 distinct commits** that were not. The merge preserves all 100 commits and their original source, tests, handoffs, proposals and evidence.

**Published and independently checked against the live remote. All eight audited branch tips have zero commits absent from main and are safe to delete at the recorded SHAs.** No branch has been deleted. The [remote receipt](remote-branch-verification.json) records the exact heads and observation time. Subsequent documentation commits retain this merge as an ancestor. Branch preservation and application acceptance are separate decisions.

Original main: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`. The merge has six parents: original main followed by the five pinned finish tips. No squash, force push, conflict discard or remote history rewrite was used. The local Git client could read but lacked push credentials, so the connected GitHub account published the same exact Git tree and ordered parents. The [publication-equivalence receipt](publication-equivalence.json) binds the local tested merge to the published SHA; its original commit object is also retained as text.

| Branch | Pinned tip | Commits absent from original main | Disposition |
|---|---|---:|---|
| `development/completion-20261124` | `394e28e163be` | 0 | Already in original main |
| `development/completion-final-20261124` | `7dca1b00331e` | 0 | Already in original main |
| `finish/01-architecture-composition` | `74fe821cfdd1` | 17 | Merged with complete history |
| `finish/02-photometry-color` | `b5c1f008446f` | 14 | Merged with complete history |
| `finish/03-cpu-study-mannequin` | `82c0e59a9adc` | 26 | Merged with complete history |
| `finish/04-metal-cache` | `9a21fdd088e0` | 16 | Merged with complete history |
| `finish/05-spatial-viewports` | `2b6aed97327e` | 27 | Merged with complete history |
| `m03-evidence-inspection` | `6e8179b1795e` | 0 | Already in original main |

## What is now together

| Workstream | Integrated development |
|---|---|
| [Architecture](../../parallel/01/HANDOFF.md) | StudioSession ownership, field commands, stale-result admission, feature presentation, committed-save handling, stable workspace identity and composition tests |
| [Photometry and color](../../parallel/02/HANDOFF.md) | Rolled-emitter normals, tiny-output handling, finite color boundaries, target-lux guidance and numerical regressions |
| [CPU Study](../../parallel/03/HANDOFF.md) | Mesh intersections, near-plane handling, bounded tiny-emitter integration, cancellable preparation, retry and latest-result preview adoption |
| [Metal and cache](../../parallel/04/HANDOFF.md) | Width-aware precision eligibility, guarded packed inputs, actor-owned rendering, CPU fallback, cancellation and failed-Metal cache eviction |
| [Spatial viewports](../../parallel/05/HANDOFF.md) | Fit envelopes, conservative camera projection, node lifetime/selection, navigation recovery and authored rectangle geometry |

Historical lane instructions and results remain available under `docs/parallel/01` through `05`. Their pinned commits remain reachable after deleting the branch labels. Current integration work resumes from main and the canonical handoff.

## Preservation proof

The [independent review](independent-review.md) checked all **3,184 changed paths** from the five branch tips against the merged tree. **3,183 retain exactly the same Git object, type and mode.** The only intentional integration change is ten exclusion entries in `Package.swift`, preserving the portable composition source allowlist while keeping Apple-specific sibling files in the native project. No branch source/test file was dropped.

At the merge source, all **230 original-main paths changed after campaign baseline `f150f98`** also retain exact original-main objects and modes, including both explicit `CGFloat.greatestFiniteMagnitude` compilation repairs. Every original-main path remains present. Subsequent canonical documentation updates add the current handoff and verification without changing production/test sources or historical lane packets. The complete branch inventory and commit lists are in [branch-baseline.json](branch-baseline.json).

## Combined-source verification

Published source: `660b50a251f662b0207d0e5aab70fda748a77664`; Linux Swift 6.0.3 and Clang 17. Both package configurations passed again at this exact SHA. The other checks executed on local merge `eb62da9dc7aee8fe899c8cc27b05adc3c700fb7d`, whose complete Git tree and ordered parents exactly match the published source. Logs, source hashes and exact commands are in [local-validation.json](local-validation.json) and [the equivalence receipt](publication-equivalence.json).

| Check | Result |
|---|---|
| Swift package Debug | 482 passed; zero failures |
| Swift package Release | 482 passed; zero failures |
| Python tooling | 100 passed |
| Native Swift syntax | Passed; parsing only, no Apple API type-check |
| Native/UI source partition, app icon, privacy manifest | Passed |
| CPU reference images | 12/12 passed, zero unsupported pixels; all image hashes identical to retained source-f150 originals |
| Shared Float32 kernel versus CPU | 6/6 canonical and 8/8 strict precision cases passed; exact masks in all fourteen |
| Optimized bounded benchmark | 8 frames, 12 observed cancellations and 4 visibility workloads passed; seven timing samples each |
| Apple build, native/Metal and UI on combined source | [Fresh workflow 45979992218](https://github.com/mirzotipi-wq/APP1/actions/runs/45979992218) running; not executable on this Linux host |

The [rendering receipt](rendering/summary.json) preserves all 13 executed command results, unchanged source hashes, per-fixture metrics and benchmark provenance. The root reviewed the actual twelve generated CPU images; they match the previously retained images exactly. These are CPU/shared-C++ results, not actual GPU execution.

Source discovery declares **261 native methods and 36 required UI methods**, plus two separately dispatched platform diagnostics. These declarations are not executed passes. The portable package also includes the native-independent composition tests; Darwin-only observation tests still require Apple execution.

The signed official Swift archive was verified against pinned SHA256 `6f78203e4b0037c8ecfae89096433eb0ef198d20ae4b2ebfadf3c04209d2cde2`. Toolchain provenance is retained under `toolchain/`. The existing subnormal `1e-320` regression literal emits a precision warning on Swift 6.0.3; the corresponding tests pass.

## Acceptance and remaining development

The previously advertised pending [main CI run 45807031966](https://github.com/mirzotipi-wq/APP1/actions/runs/45807031966) is terminal. Core, simulator, studio-optics and Default visual jobs succeeded; room-precision, app-accessibility, library-reference, studio-export and AXXXL visual jobs failed. [Original terminal job metadata](prior-main-ci-jobs.json) is retained. These results belong to `b0d25ee`, before consolidation.

The current combined tree needs fresh acceptance. `agents/state.json` therefore reopens foundation validation and leaves dependent M02/M03 acceptance pending; original statuses and source-specific passes remain preserved in [the prior state](../../../agents/history/2026-11-27-before-branch-consolidation-state.json) and the evidence ledger. This records validation freshness; it removes no implementation and changes no acceptance threshold.

Retained development follow-ups include:

- Execute combined native/Metal, hosted preview-observer and UI checks; repair actual failures without treating earlier isolated passes as combined proof.
- Complete the rejected-feature-draft acceptance adapters described in [lane 01's proposal](../../parallel/01/FEATURE_ADAPTERS.md).
- Resolve the documented positive-tiny-output Float32 routing policy; retained reviews do not establish a visible RGB/mask failure.
- Reconcile export chooser, library save-status, optics and accessibility workflows from actual new-source results.

No physical-device, photographic-calibration, release-readiness or historical 100-worker-campaign completion claim is made by this consolidation.

## Recheck before branch deletion

With fresh remote refs, an empty last command means every non-main remote branch tip is reachable from main:

```sh
git fetch origin --prune
git branch -r --no-merged origin/main
```

For an individual pinned branch, verify `git merge-base --is-ancestor <branch-tip> origin/main`. A new commit added to another branch after this audit needs a new comparison. Branch deletion was not part of this execution.
