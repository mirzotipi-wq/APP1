# Independent engineering evidence review — 2026-11-24

## Conclusion and review boundary

**Key & Fill remains a pre-alpha product. The inspected evidence supports 20 of the 100 allocated evidence points at the reviewed source; it does not support a certified commercial-quality score, a completion percentage, or release readiness.** M01 remains active because coherent current native build/persistence evidence is incomplete. The protected release gates remain unchanged. [Quality contract](../../QUALITY.md), [roadmap](../../ROADMAP.md), [current checkpoint](checkpoint-5.md).

This is the wave-ten quality specialist's independent agent workstream. It is not an independent human photographer, customer, accessibility specialist or App Review decision. The reviewer inspected contracts, architecture, state/evidence records, backlog, raw verification logs and the specialist reports listed below. No device, simulator or customer session was run by this reviewer. No source code, gate state or commercial term was changed.

The scored source is `0d63dd872bbd20aaa72f9263b51e2208b6ee926f`, tested tree `bacddcd4aa9ec280f33e75e07f2083d4d0b69dc6`. Pending duplicate-envelope and numeric-readout changes are excluded until integrated and verified. Later evidence must be attached to its own revision. The [2026-11-23 scorecard](../quality-scorecard-2026-11-23.md) supplied the existing transparent sub-allocation; its old total was **not** automatically treated as current. Rechecking the portable evidence against those same buckets produces the same supported-point total. Expanding the number of tests inside an already-supported bucket does not automatically earn a new category of evidence.

## Evidence independently checked

The reviewer recomputed all four checkpoint-5 log hashes and read their actual results:

| Artifact | Observed result | SHA-256 |
| --- | --- | --- |
| [Debug log](cycle5-debug.log) | 234 XCTest tests, zero failures | `644032986cd8f55f4769d39d3a79305bc6f22958a293286462039c0f727765bf` |
| [Release log](cycle5-release.log) | 234 XCTest tests, zero failures | `d506ac689844e3eaecc14ba1227057bec3990ddfd775d62cb440560b186d64e7` |
| [Established kernel fixtures](cycle5-kernel.log) | 6/6 pass; maximum channel error at most one; near-field invalid mask 84/84 | `5bc43229cad7693294c2342299848b3676d3c8eb54d09cf88038268892db3378` |
| [Strict far-camera controls](cycle5-precision.log) | 8/8 pass; zero RGB differences and matching invalid counts | `70819cd1bc1bb704547ac9d1793db4c9bd85668f582353aad572443be547bf66` |

The logs identify Swift 6.4.3 / Linux x86_64. Their original host timestamps remain unmodified. These are retained executions by the integration lead, independently inspected here; this reviewer did not rerun the complete suites. `python3 scripts/agent_cycle.py check` and `next` were run directly and passed structural validation while retaining M01 and its `native_build` / `persistence_smoke` blockers. Script success is not verification of product behavior.

A single direct fetch of [workflow 45360664075](https://github.com/mirzotipi-wq/APP1/actions/runs/45360664075) showed core job `138331236599` successful. The simulator was running macOS package tests, library/reference was building the native test bundle, room/precision was selecting a simulator, and studio/export was queued. This is a dated observation, not a later outcome or an aggregate native pass.

Historical evidence remains useful without being promoted to the newer source. The [artifact audit](native-artifact-audit.md) inspected the actual `0fce248` Release simulator executable, icon assets, manifest and shader library. The [product review](product-accessibility-review.md) inspected two genuine `cab67417` simulator screenshots. Neither artifact establishes the current UI, device performance, physical accessibility or signed distribution.

### New native stall evidence supplied during this review

The integration lead retrieved the completed log for prior-source simulator job `138314533584`. This reviewer independently read the retained [47-line selected excerpt](0fce248-native-test-excerpt.log), which records **9 bounded-reader, 3 PDF and 6 document-I/O tests passed**, followed by `testSymbolicLinkDirectoryAndFIFOAreRejectedWithoutFollowingOrBlocking` starting at `08:49:41Z` and not completing before cancellation at `08:57:50Z`. This is a specific incomplete native case, not a full suite pass. The reviewer inspected that test's source: it calls the import operation serially for a symlink, a directory and a FIFO, without per-item progress records. The available observation does **not** identify which of those three inputs stalled or establish the internal blocking mechanism. [Job source](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140/job/138314533584), [test source](../../../NativeTests/ProjectDocumentIOTests.swift).

The excerpt SHA-256 was independently recomputed as `fd306e3b636acf7f6f139d767ca8f16bb95e3d3f3587ef5dbc55c7e1583d245a`. The complete downloaded log hash was recomputed as `e85e5759d3393b5ef8684b7daf76868ffb1dc29923b6c43ad8f26efb92114991`; only the selected excerpt and relevant test source were independently read in this review, not every line of that full job log.

The lead's hypothesis is that coordination begins before nonregular-file rejection. That hypothesis needs a separate reproduction/correction and native execution. The earlier artifact report accurately records that its own log fetch was unavailable; this later log observation must not be retroactively presented as having been known during that audit.

## Requested scorecard, with evidence allocation preserved

Zero supported points means the allocated acceptance evidence is missing; it does not mean that no implementation or useful engineering work exists. Points below are bounded review judgments under the existing internal rubric, not a statistically calibrated measurement.

| Category | Maximum | Supported now | Demonstrated basis and withheld allocation |
| --- | ---: | ---: | --- |
| Core functionality | 15 | **8** | Re-supported: validated scene/recipes 3, camera/optics domain 2, project operations 2, PDF layout model 1. Current portable tests cover those behaviors. Native end-to-end 3, reference workflow 2 and AR/manual-placement workflow 2 remain withheld until their actual acceptance evidence is complete. |
| UI/UX and visual design | 15 | **0** | The historical images and current source reviews expose useful layout/identity work and real defects. They do not complete the allocated native workflow 5, genuine current screenshot/professional review 5, device layouts 3 and onboarding/error-state review 2. No current comprehensive visual/user-flow pass is established. |
| Lighting accuracy and rendering | 20 | **8** | Re-supported: analytic/independent numerical photometry 5 and bounded CPU direct-light/host parity 3. Current oracle/geometry/Float32 work strengthens these buckets. Actual current GPU parity 4, calibrated reference comparisons 5 and realistic subject/material review 3 remain withheld. |
| Performance | 10 | **0** | Linux cancellation and storage measurements are real and useful, but the allocated physical frame-time 4, memory 2, launch/input latency 2 and thermal 2 require the declared device workload. No host timing is substituted for an iPhone result. |
| Stability and data integrity | 10 | **4** | Re-supported: portable round-trip, migration, malformed/oversized and stale-write protections 4. Native persistence 2, interruption/recovery 2 and full regression 2 remain withheld. The newly observed incomplete native nonregular-file case reinforces this boundary. |
| Reference analysis and AR | 10 | **0** | Guided observations/assumptions, descriptive tonal statistics and manual room coordinates are implemented. They do not satisfy held-out inference/uncertainty acceptance 5 or physical AR tracking/error acceptance 5. No synthetic reviewer or arbitrary confidence score fills those gaps. |
| Accessibility | 5 | **0** | Bounded labels, control identities and numeric formatting tests are implementation evidence. Real-device VoiceOver, Dynamic Type, contrast, non-color cues and controls remain unverified; the reviewed source still has a reproduced tiny-value readout defect. |
| Privacy and security | 5 | **0** | The source threat review, bounded file reads and packaged manifest are useful. Runtime permissions/network/deletion, archive/disclosure consistency and the complete required audit remain open. A source search for network APIs is not a runtime privacy pass. |
| Commercial readiness | 5 | **0** | StoreKit transaction lifecycle, owner-approved entitlements and actual customer/payment-intent evidence are absent. The proposed price and demand targets are hypotheses. |
| App Store compliance | 5 | **0** | Simulator packaging is inspected. Current full submission materials, owner signing/distribution decisions, signed-device/archive evidence and independent release review are not complete. No external-policy compliance certification is made here. |
| **Total supported evidence points** | **100** | **20** | **Fresh source-bound evidence floor; not 20% complete and not an overall commercial-quality grade.** |

Core and integrity credit rests on [checkpoint 5](checkpoint-5.md) and its raw suites; the lighting limits are explicit in the [architecture](../../ARCHITECTURE.md), [Float32 audit](float32-boundary.md) and [independent rendering review](rendering-critical-review.md). The [storage benchmark](storage-benchmark.md), [performance review](performance-critical-review.md), [privacy review](privacy-source-review.md) and [product review](product-accessibility-review.md) support the narrower findings in the remaining rows. None replaces the [protected gate criteria](../../QUALITY.md).

## Material quality findings

**The native baseline is the immediate integration bottleneck.** Portable tests and builds on successive revisions have accumulated while complete current native persistence/UI evidence remains incomplete. A successful build with a test still stalled or cancelled cannot close that gap. The new nonregular-file case warrants priority as a **P1 verification/workflow blocker**, without asserting an unproved production-wide hang or data loss. Finish a coherent corrected candidate and preserve its finalized native results before crediting native functionality or integrity points.

**Exactness is uneven across product surfaces.** The [product review](product-accessibility-review.md) reproduced accepted `0.0000001` and `-0.0000001` being displayed/spoken as `0 m` and `-0 m`; `1.23456789` was rounded to six fractional digits. This is a P2 presentation defect, not stored-data loss. It invalidates an unrestricted “exact spoken values” claim. The ongoing correction must preserve sign, nonzero magnitude, bounded layout, locale and unchanged imported values, with native pronunciation still checked separately. The same review's AR wording inconsistency has a concrete README correction prepared; that does not implement AR or change M05.

**Numerical robustness has improved without becoming photographic calibration.** Stable intersections, a 300-ray independent mesh oracle, conservative routing and strict far-camera controls address real computational defects. The raw Float32 corpus still has five cutoff-mask disagreements out of 33 when forced through the kernel; routing all measured ambiguous cases to Double CPU is an explicit operating-domain decision. The 1 mm margin is not a universal GPU error proof, and 22/33 CPU-routed stress scenes are not a production fallback frequency. The illustrative 3D adapter, neutral synthetic mannequin, fixed-grid grazing renderer and absent controlled photographic evaluation still limit the professional photographic promise. [Rendering review](rendering-critical-review.md), [architecture](../../ARCHITECTURE.md).

**Large valid data remains a responsiveness risk.** The complete storage transaction had a 669.938 ms median for the approximately 8 MB legacy-name fixture on Linux tmpfs. Current UI handlers call the synchronous store. This supports KF-032, but does not prove an iPhone freeze or justify skipping validation. A future asynchronous correction must move the complete read/validate/compare/write transaction and reconcile a committed write with subsequent edits/cancellation; moving only the final write is insufficient. [Measured workload and scope](storage-benchmark.md), [iOS review](ios-critical-review.md).

The remaining first-release gaps are substantive: held-out useful reference reconstruction, calibrated portrait rendering, physical AR, device performance/accessibility, full purchase lifecycle and real customer validation. More commits, agents or passing portable tests cannot stand in for those required observations. The [product contract](../../PRODUCT.md) and [quality contract](../../QUALITY.md) remain the acceptance boundary.

## Highest-value next executable packet

**Close the demonstrated native import stall and establish one coherent native baseline (KF-001 / KF-004 / KF-006).** The integration lead has already assigned a correction specialist; this review endorses that priority over a speculative visual or rendering expansion.

Acceptance must be observable at the corrected source:

1. Isolate symlink, directory and FIFO rejection so the log identifies each attempted/completed case. Each must finish under a declared bounded native test wait, return `notRegularFile`, and preserve the regular source bytes. A cancellation or job timeout is a failure to establish this acceptance.
2. If an early metadata rejection is added, retain authoritative opened-descriptor type/size checks, no-follow/nonblocking behavior, security scope and coordination for legitimate regular provider files. Re-run the actual provider-coordination error/cancellation and successful regular-file cases; a pathname check must not replace the descriptor protection.
3. At one exact integrated revision containing the accepted import and numeric corrections, finish portable Debug/Release, generated unsigned simulator Debug/Release builds, the native unit suite, and create/edit/save/relaunch plus corrupt-file preservation smoke. Keep all three UI shards and their actual assertions. Record finalized result bundles, genuine attachments, commands, Xcode/SDK and the source SHA; investigate failures instead of promoting partial counts.
4. Recompute M01 gate state only from the completed evidence belonging to that revision. Keep physical/device, calibrated rendering, commerce and owner approval gates unresolved until their separate criteria pass. A complete M01 baseline permits the next milestone; it does not declare a release candidate.

While that candidate runs, independent evidence review and documentation can continue without representing a new source change as covered by the in-flight native run. No approval, publication, spending, protected-contract change or additional broad architecture rewrite is required for this packet.

## Review provenance

Read: AGENTS, operating protocol, product, architecture, design, roadmap and quality contracts; current handoff/state/evidence/backlog; the prior scorecard; checkpoint 5 and its four raw logs; product/accessibility, native-artifact and storage reports. The current CI status was fetched directly once; the later completed prior native log was supplied by the integration lead, and its selected excerpt was independently read and hash-checked as described above. This reviewer ran record validation and inspected the combined native rejection-test source, but did not execute native tests, remeasure performance or inspect the current app visually.

Only this report is written by the reviewer. The existing scorecard, protected files, gates, production code and tests are unchanged. No score increase, milestone promotion or release certification is requested.
