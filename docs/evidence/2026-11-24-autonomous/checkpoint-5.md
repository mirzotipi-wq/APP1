# Rendering precision, cancellation and owned edits — checkpoint 5

Source `0d63dd872bbd20aaa72f9263b51e2208b6ee926f`, exact tested tree `bacddcd4aa9ec280f33e75e07f2083d4d0b69dc6`, pushed to main and independently read back through the connector and git fetch. [Current CI run 45360664075](https://github.com/mirzotipi-wq/APP1/actions/runs/45360664075) was pending at the initial readback. This is the fifth complete exact-source implementation/verification cycle in this session; earlier work packages and corrections are recorded in checkpoints 1–4.

## Actual verification

The immutable index export passed **234/234 Debug and 234/234 Release XCTest tests**, zero failures; **28/28 Python validation tests**; recursive assignment of all six UI classes; agent-state validation; and native Swift syntax parsing. Swift 6.4.3 / Debian 13 x86_64; native parsing is not Apple SDK type checking.

The six established host-executed Float32 fixtures passed with maximum channel error at most one and exact unsupported-mask counts, including **84/84** for the deliberate near-field fixture. All eight strict far-camera/translation controls passed with **zero RGB differences** and matching masks. Swift generated the actual packed buffers and independent Double images from this exact source. Native Metal and physical-device execution remain pending.

## Corrections and evidence

| Packet | Implemented behavior and evidence |
| --- | --- |
| Cancellation responsiveness | Both CPU renderers check cancellation at most every eight pixel evaluations. Four focused tests cover initial, mid-frame and immediately-after-false-check boundaries. Real shared-Linux probes reduced measured maximum cancellation completion delay from 51.111 to 1.713 ms for the selected mannequin workload, and 45.068 to 3.466 ms for the selected reference sphere workload. All three image buffers remained byte-identical. These are finite measurements, not a wall-clock guarantee, FPS claim or device result. |
| Owned continuous edits | History begins/ends carry captured project/control/light ownership. A late end from a different control cannot close the current edit; lifecycle operations still explicitly force-close. Seven added tests preserve undo/redo boundaries. Native overlapping callbacks, especially reused generations of the same control/project identity, still require execution. |
| Float32 geometry | Stable closest-approach sphere roots fix the observed far-camera surface error while retaining the Double oracle. A conservative portable domain helper routes near-field ambiguity to CPU using actual sphere, rectangle, camera and visible-panel geometry. The 1 mm margin is an engineering guard, not a proved GPU error bound. |
| Raw parity remains explicit | All six native raw fixtures remain exercised through an internal validation-only path; production user frames still require eligibility and input validation. The raw 33-fixture diagnostic corpus remains **28/33**, with five cutoff-mask failures retained. All 14 cutoff probes route to CPU; 22/33 stress scenes route conservatively, not a measured production frequency. |
| Invisible names | New names need visible content. Legacy storage remains unchanged; bounded labels provide contextual project/light identities throughout studio, recovery, backup, room and report workflows. Independent iOS review found remaining blank labels, and a separate correction fixed them with two additional integration regressions. |
| CI prerequisites | Native jobs compile/link a real probe, install the optional Metal component once if needed, and require a successful reprobe. Failures propagate through pipefail and logs upload. An independent reviewer found insufficient total UI job overhead after this addition; the total is now 85 minutes around unchanged 12/25/32-minute preflight/build/test stages. No tests or selectors were removed. |
| Data/privacy review | Reports distinguish per-light scene UUIDs from omitted library identities, selected-file scope/coordinator protection, deliberate exports and generated structural/color PNG chunks. Native provider, deletion, network and archive tests remain required. |

[Performance review](performance-critical-review.md), [rendering review](rendering-critical-review.md), [iOS review](ios-critical-review.md), [CI review](ci-critical-review.md), [visible identity correction](visible-identity-correction.md), and the linked measurement reports contain exact scopes and remaining limits. The independent renderer geometry audit checked 345,824 finite valid near-field scenes with zero incorrect eligibility results; this is not a count of XCTest methods or GPU renders.

The storage measurement packet records five samples per operation on **Linux tmpfs**, including a valid approximately 8 MB legacy-name case with median load 319.649 ms and save 669.938 ms. KF-032 requires a complete asynchronous transaction/adoption design; no device stall or disk durability is inferred.

## Prior native evidence retained

For prior source `0fce248`, both unsigned simulator build and upload steps passed. Root downloaded Release artifact 14903072593: outer SHA-256 `92cf2f5b2328c3ba7aa22029aca3eeec5293a94a05fbf4949df5741adff0f5cb` matched GitHub, and both ZIP CRC checks passed. The actual app declares iOS 17 minimum, iPhoneSimulator SDK 26.5, Xcode build metadata 2660, icon assets, a privacy manifest and default.metallib. This is an unsigned simulator app, not a signed device build or App Store archive, and it does not verify the newer source above.

Both room/precision and studio/export jobs on `0fce248` failed before UI execution with the same missing Metal compiler error. The native unit job was later observed cancelled while finalizing; its complete log was unavailable at that observation, so no test count or exact cancellation cause is inferred. Historical successful suites remain attached to their earlier revisions.

## Next executable work

Correct the reproduced duplicate-envelope import ambiguity (KF-031) with an independently reviewed bounded scan. Correct the product review's reproduced tiny-value readout defect: accepted 0.0000001 m currently displays/announces 0 m. Preserve the strict parser and untouched imported values. Then run the next exact-source integration suite and inspect repaired native CI. M01 and physical/calibrated/commercial/release gates remain unresolved; no 95/100 or product-complete claim.

## Raw exact-source logs

- `cycle5-debug.log` SHA-256 `644032986cd8f55f4769d39d3a79305bc6f22958a293286462039c0f727765bf`.
- `cycle5-release.log` SHA-256 `d506ac689844e3eaecc14ba1227057bec3990ddfd775d62cb440560b186d64e7`.
- `cycle5-kernel.log` SHA-256 `5bc43229cad7693294c2342299848b3676d3c8eb54d09cf88038268892db3378`.
- `cycle5-precision.log` SHA-256 `70819cd1bc1bb704547ac9d1793db4c9bd85668f582353aad572443be547bf66`.

Raw logs preserve original whitespace and host timestamps. Source/document whitespace checks exclude raw `.log` files rather than rewriting evidence.
