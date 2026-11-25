# Keyboard introduction: equivalent predicate and bounded failure evidence

Base: **9eddd97c5e638edf1768332d9d83d7dc2cccb72a**. Authorized source scope: **UITests/StudioContentReachability.swift only**. Candidate SHA256: `cde53fae85e741f18d10fea9ac2c23080cf3b7dd225c7ae8affa6eb459bac05f`. No production source, caller, selector, deadline or acceptance gate was edited. At original preparation, the candidate awaited independent review and real Apple compilation/execution. The subsequent independent review is recorded separately; this packet claims no Apple execution of the candidate.

## Evidence and exact change

The preceding cbf library failure at `ProjectLibraryUITests.swift:130` happened after Continue was tapped. Genuine recording frames at 92.0 and 101.3 seconds show the introduction gone and a visible q key. The retained q/Q attachment is only a query chain, so it does not prove accessible key identity/hittability. Detailed source-bound observations and hashes remain in the [investigation](followup-cbf-library-readiness-host.md) and [original source/derived-file index](../validation/keyboard-readiness/investigation-source-index.json).

Apple documents that `isHittable` requires existence and an actionable current location, and is false when an element is absent, offscreen or covered.[1] Existence alone does not establish hittability.[2] Let E mean exists and H mean hittable. Under H implies E, `(!E_continue || !H_continue) && E_key && H_key` equals `!H_continue && H_key` for every valid fixed UI state. The helper now uses exactly:

```swift
!proceed.isHittable && typingKey.isHittable
```

The same Continue-first short-circuit order, app-keyboard/q-or-Q identity, introduction recognition, five-second Continue lookup, tap, and single **ten-second** readiness waiter remain. The final assertion still requires `.completed` with the original failure message and caller location. There is no retry, sleep, alternative selector, skip, deadline increase or screenshot-based pass condition.

The four callers at `ProjectLibraryUITests.swift:61,80,130,351` remain byte-identical. In particular, archived-delete still requires exact `Keep` entry, confirmation/cancellation behavior, only the intended removal, and relaunch persistence (`:131–178`).

## Failure-only diagnostic

After the original waiter returns a non-completed result, the helper obtains **one immutable app snapshot** and a screen attachment. Apple exposes snapshot attributes and descendant snapshots through this API.[3] Traversal examines at most **256 nodes**, retaining root, keyboard, key, text-field, Continue and introduction nodes. It records type, identifier, label, frame and enabled state; identity strings are UTF-8-safe prefixes of at most **256 bytes**. The complete diagnostic excerpt is at most **16,384 UTF-8 bytes**, plus a truncation marker and console label. It is both printed and attached. Snapshot errors are caught and recorded, followed by the unchanged original assertion.

This replaces query-only evidence with selected structured snapshot attributes when available. Apple explicitly permits `debugDescription` to contain only a query and does not support relying on its format for test behavior.[4] No diagnostic observation participates in pass/fail evaluation. Truncated traversal is labelled, and a later snapshot is not represented as the state throughout the failed wait.

## Validation actually performed

- Linux syntax parse exited zero: `/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc -frontend -parse UITests/StudioContentReachability.swift`. This is not Apple typechecking.
- `git diff --check -- UITests/StudioContentReachability.swift` exited zero.
- Source comparison verified unchanged text outside this helper, unchanged actions/query before the waiter, one ten-second wait, exact predicate order, one snapshot and one screen capture exclusively after failed readiness, original assertion text and all caller source unchanged.
- Boolean enumeration checked all **nine** valid combinations of absent/present-nonhittable/present-hittable states for Continue and the key; original and replacement agree. This is a logical check, not live AX or UI execution.

The [exact diff](../validation/keyboard-readiness/candidate.diff) and [machine-readable checks](../validation/keyboard-readiness/source-validation.json) are preserved byte-for-byte. The receipt retains the original outside-report path/hash; [copy-manifest.json](../validation/keyboard-readiness/copy-manifest.json) also identifies the new repository report hash. Changes to this edition are relative links and preparation/review chronology only.

## Known limits and recommendation

The change removes two explicit existence reads; Apple does not promise one remote request per property read, shared snapshots, or a particular relative cost. No request-count reduction, runtime speedup or repaired keyboard run is claimed. UI state can change between reads, so fixed-state equivalence is not identical race timing. The unchanged ten-second waiter is the acceptance budget; it does not establish a new hard preemption guarantee for an in-flight AX request.

The snapshot request itself has no newly introduced duration bound: only its count, local traversal and retained text are bounded, and existing job limits remain unchanged. Snapshot attributes do not establish hittability, and an app snapshot cannot diagnose SpringBoard-only nodes. The next real library run must exercise the intro transition, finish archived-delete and retain any new failure evidence. Keep production and all exact typing/deletion assertions unchanged while evaluating this narrow candidate.

## Primary sources consulted

1. Apple, [isHittable](https://developer.apple.com/documentation/xcuiautomation/xcuielement/ishittable.md), retrieved 2026-11-25.
2. Apple, [exists](https://developer.apple.com/documentation/xcuiautomation/xcuielement/exists.md), retrieved 2026-11-25.
3. Apple, [snapshot()](https://developer.apple.com/documentation/xcuiautomation/xcuielementsnapshotproviding/snapshot%28%29.md) and [XCUIElementSnapshot](https://developer.apple.com/documentation/xcuiautomation/xcuielementsnapshot.md), retrieved 2026-11-25.
4. Apple, [debugDescription](https://developer.apple.com/documentation/xcuiautomation/xcuielement/debugdescription.md), retrieved 2026-11-25.
