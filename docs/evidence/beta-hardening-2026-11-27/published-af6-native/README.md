# A095 — af6 Apple compile and native execution receipt

Source: `af6b7e56bb5d2b550ebefcc5fd7bb2afc4c20867`.
Run: [46033956426](https://github.com/mirzotipi-wq/APP1/actions/runs/46033956426), simulator job **140628197430**.

## Observed outcome

The macOS package compiled at the declared macOS 14 target. **All 597 expected method identities started and passed exactly once**, with no failures, skips, duplicates, omissions or unexpected events. This establishes that the previous unavailable UTF-8 initializer failure was cleared on this Apple host.

The following unsigned Debug simulator build-for-testing failed with exit **65** at `NativeTests/LightingPlanPDFTests.swift:188:57`: `type AnyHashable has no member titleAttribute`. The dictionary subscript used an unqualified `.titleAttribute`, whose inferred context was `AnyHashable`. Root was notified immediately and owns the subsequent repair. This receipt remains bound to the failing source.

**All 335 native methods were unstarted.** The required Metal methods and new PDF regression did not execute. The native command was skipped, no finalized xcresult or PDF attachments were produced, and both Release simulator and unsigned arm64 device builds were skipped. A successful no-files-found upload step is not artifact evidence; no compact native or device artifact was created.

## Evidence boundaries

The original decoded job log is retained verbatim with checked UTF-8 byte/scalar/newline counts. Exact timestamped runtime events were matched against source inventories extracted with `git show` at the specified commit, independently of job summary counts. `method-accounting.json` retains all actual event identities and sequences.

The bounded atomic-write stage, Metal compiler check, project generation and simulator selection succeeded according to the original terminal job and log. No independent download/inspection of the macOS atomic artifact was performed. Two listed artifact digests are API metadata, not independently rehashed ZIPs. No native app launch, device test, PDF visual/share check, signing or distribution is claimed. UI matrix outcomes are outside this receipt.

No repository edits, workflow reruns or test execution were initiated by this reviewer. The Python analyzer and all evidence are private review material for root to integrate.
