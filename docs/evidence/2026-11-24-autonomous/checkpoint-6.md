# Exact readouts and import integrity — checkpoint 6

Source `ff8b683098a720b4c7abdddf212f85a79f3cfd39`, exact tree `9707e0a45954ea4ee42e81379a0f4ef825230618`, integrated on main and independently read back through the connector and git fetch. Parent `9724cc26b8de80aaad28474674cbdb80e442b926` is the preceding evidence-only checkpoint. [Current workflow 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829) is the native acceptance run for this candidate.

## Verification at the exact source

**245/245 Debug and 245/245 Release XCTest tests passed**, zero failures, in the isolated index export. **28/28 Python tests**, state validation, recursive six-class/three-shard coverage, native Swift syntax parsing and icon/privacy source validation passed. Swift 6.4.3, Debian 13 x86_64. The previously verified kernel and numerical renderer implementation is unchanged in this packet; CI retains all six original and eight strict host checks.

Eleven new portable methods account for the increase from 234 to 245: five envelope-integrity tests and six exact numeric-readout tests. The native preflight packet adds no portable package methods. Its separate Linux adaptation passed **13/13 Debug and 13/13 Release real-file tests**; those are neither Apple tests nor additions to the portable 245 count.

The six complete integration cycles, their exact source/tree pairs, sixty real specialists, sixteen substantive packages and thirty-two actionable deliverables are recorded in [the session ledger](session-ledger.md). The lead is additional to the sixty; no human customer, photographer, device operator or release reviewer was simulated.

## Accepted corrections

### Duplicate project-envelope keys

The versioned editable document now rejects repeated root keys after Foundation has accepted the original envelope. Escaped-equivalent keys cannot hide duplicates. An iterative bounded scan skips quoted delimiters and nested containers; Foundation remains responsible for complete JSON validity, supported encodings and scene decoding. The existing 8 MiB wire bound, closed root, stored name compatibility, canonical export bytes and store compare/write protections remain intact. Nested scene-object duplicate behavior is explicitly outside this envelope-only packet.

The author reproduced sixteen failed assertions before the change and then passed all eighteen focused document/adversarial tests in both configurations. The independent exact-source differential review preserved 1,152 accepted unique documents and canonical bytes, rejected all 3,840 duplicate variants, matched deep-container behavior and five exact 8 MiB encoding boundaries, and rejected nineteen malformed payloads plus all 136 truncated prefixes. Zero mismatches were observed. These are finite probe inputs, not thousands of XCTest methods. [Correction](document-key-integrity.md), [independent review](document-parser-review.md).

### Truthful exact-value controls

The previous six-fractional-digit readout converted accepted 0.0000001 m to visible/spoken text `0 m`. The shared formatter now starts from Double's round-trip digits, expands decimal notation only within its bounded length, and localizes symbols without re-rounding. Tiny, high-precision and signed values remain distinguishable; extreme finite imports use bounded scientific notation. The strict decimal input grammar and range checks are unchanged.

The editor uses an exact bounded decimal draft. When an imported value cannot fit, it shows the actual scientific value and an explicit empty replacement field: unchanged Apply preserves the original; an entered valid decimal replaces it. Tests cover locale digits, signed zero, subnormals, finite extremes, input bounds and unchanged scene bytes. The independent review checked 13,507 finite readouts across 1,039 locale identifiers with zero sign/round-trip/bounds mismatches. Actual VoiceOver pronunciation and native interaction are still required. [Correction](numeric-readout-correction.md), [independent review](numeric-readout-review.md).

The more accurate helper costs a measured 15.5–23.6 microseconds per call versus 1.75–3.07 for the earlier rounding formatter in four shared-Linux locale workloads. This is a finite per-call cost, not a device UI failure or frame-rate measurement; no speculative caching was added.

### Known nonregular imports are rejected before coordination

The completed older native log showed nine descriptor tests, three PDF tests and six project-I/O tests pass, then the combined symlink/directory/FIFO case start without completing before cancellation. It does not identify which input stalled or prove the exact Foundation mechanism. [Selected exact native log lines](0fce248-native-test-excerpt.log) and [the repair report](native-import-stall.md) preserve the observation.

Project import now performs metadata-only lstat while security scope is held, before NSFileCoordinator. A known nonregular final component is rejected; unavailable metadata still takes the normal provider path. The later no-follow/nonblocking open, descriptor fstat, actual-byte bound and cancellation remain authoritative if the path changes. This does not authorize reading based only on a pathname check or claim immunity from every provider/race stall.

The combined native case is replaced by separately identifiable symlink, directory and FIFO cases with five-second failing expectations, source-byte assertions and cancellation on exit. No timeout is converted into success and no second indefinite await follows a failed expectation. Four additional native helper cases verify metadata behavior, replacement after preflight and actual cancellation. Native execution of the repaired source remains the acceptance boundary.

## Actual CI observations

At **09:20:59 UTC on 2026-11-24**, current core job **138341537614** was running its Debug tests; native jobs had not yet appeared. The preceding source `0d63dd8` completed core job **138331236599** successfully. Its three started native preflight steps passed, both unsigned simulator build/upload steps passed, and the two previously blocked UI shards reached test execution. The newer candidate superseded that grouped run; all four old native jobs subsequently reported cancellation. Cancelled or partial jobs are not complete suite passes.

Prior `0fce248` Release artifact 14903072593 was downloaded and checked as documented in [the native artifact audit](native-artifact-audit.md): valid ZIPs, matching digest, iOS Simulator architectures/platform, iOS 17 minimum, SDK 26.5, icon assets, privacy plist and shader library. It is an unsigned simulator build in the owner/distribution sense; the arm64 slice has a linker-generated ad hoc signature, not owner-signed device or Store distribution evidence.

## Quality and remaining acceptance

The independent [quality review](quality-review.md) supports twenty evidence points using the declared sub-allocation: eight core, eight lighting and four integrity. It explicitly does not certify an overall commercial grade or twenty percent completion. The new source strengthens those same portable categories without inventing native/device/customer evidence. **M01 remains active** until the exact candidate's native build and persistence smoke are established. Physical rendering/calibration, performance/thermal/accessibility, held-out reference inference, AR, StoreKit, customer validation, distribution and owner approval remain outstanding.

Next: inspect the current workflow, first the three separate nonregular import cases and the remaining photo/Metal tests, then all UI shards and genuine attachments. Fix demonstrated failures while preserving the existing assertions. If native results are queued, continue only justified independent work; do not promote gates or claim background assistant supervision after the session ends.

## Raw exact-source logs

- `cycle6-debug.log` SHA-256 `68343404bd0d1ba93598fc8f91cf58f6cfb46ff5c15514981c73c57ff3de96bd`.
- `cycle6-release.log` SHA-256 `0fe573582d4c618eed2e636be5221360161d353a2c59e5c7d3085f5d44a7f3eb`.

## Later current-source build observation

Current core job 138341537614 subsequently completed successfully, with actual 245/245 Debug and Release, Python validation, six established and eight strict host-kernel checks in the retained `ff8b683-github-core.log`. By 09:28:41 UTC, both current unsigned simulator build/upload steps had passed and the native unit step was running; library/reference and room/precision UI were running, studio/export queued.

Root then downloaded and inspected current Release artifact 14906397278. Its digest, CRCs, Xcode/SDK metadata, actual simulator architecture/platform commands, icon/privacy contents and shader library support the **native_build gate pass** recorded in [the current build report](native-build-ff8b683.md). This is a legitimate build-gate update, not a native-test or release promotion. M01 remains active with **persistence_smoke** outstanding. Earlier dated observations above remain historical observations.

## Finalized native observations and ensuing corrections

The source-six simulator job finalized with **40/42 native methods passed**, two SceneKit test methods failed and 33 failed assertions. Its descriptor 13/13, document I/O 9/9, photo 7/7, PDF 3/3 and renderer 7/7 suites all passed. Real simulator Metal ran all six established parity fixtures with maximum channel difference one and matching invalid masks. The previously stalled nonregular import cases each completed promptly.

Library/reference UI finished **7/8**, failing on nested duplicate recovery-confirmation accessibility nodes. Room/precision finished **4/5**: all three precision-editing scenarios passed, while the room-notes content observation failed. Studio/export remains in progress at this observation. The actual failures, logs and acceptance boundaries are preserved in [native-results-ff8b683.md](native-results-ff8b683.md).

Independent reviewers diagnosed the SceneKit presentation-transaction boundary and exact Float FOV representation without loosening clipping bounds. They also identified a real invalid SF Symbol and low-contrast project metadata in current screenshots. Corrective source and tests are being integrated; their native results are not inferred from these diagnoses. The failed source-six runs remain failed evidence.
