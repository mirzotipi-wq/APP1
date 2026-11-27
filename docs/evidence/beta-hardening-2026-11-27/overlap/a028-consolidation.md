# A028 — consolidated text-input diagnostics

Working baseline: `9e2313cbffb01d66249458c64087cb66c7652cca` on `main`.
Foundation for both Swift files: exact upstream revision
`2fc7647314d3ae6fa22d95284e778c6c5badbe4a`.

## Preserved history and review scope

Before replacing either file, `git diff -- App/StudioTextField.swift
NativeTests/StudioTextFieldTests.swift` was saved as
`a005-before-consolidation.patch` (16,823 bytes;
SHA-256 `b7c475e2b91d0ffc5fe9b393f1db6205085df4ba1814cfc76e8999ba02f26750`).
No checkout, reset, commit, pull, rebase, or push was performed.

The A005 implementation and A010 review are superseded for the current
implementation by this consolidation. Their earlier conclusions describe the
archived patch, not the resulting upstream-based recorder. The local duplicate
`testInputTraceRequiresUITestArgumentRedactsIdentifiersAndExplicitlyCapsOutput`
is superseded by upstream's explicit environment opt-in and 512-process /
256-control budget contract. Its unknown-identifier newline canary is retained
in the upstream privacy test.

## Result

All upstream text-field behavior and diagnostic instrumentation are preserved.
The only changes to upstream `App/StudioTextField.swift` are a DEBUG-only OSLog
import and the shared recorder's sink. That sink preserves `print(line)` and
also passes the same already-sanitized `KEYFILL_INPUT_TRACE_V1 ` payload to
`Logger.notice`, using subsystem `com.example.keyandfill` and category
`StudioTextInputTrace`. The explicit `KEYFILL_UI_TEXT_INPUT_TRACE=1` gate,
process/control limits, cap markers, lazy state collection, default sink, and
injected test sinks are unchanged. Release behavior is unchanged.

All 21 upstream test methods remain, including all four upstream diagnostics
methods. Nineteen method bodies are byte-for-byte identical. The existing
privacy method adds the retained newline canary. The identity-change method
retains its behavioral assertions and adds JSON assertions for
`identityChange`, `publishLifecycleChanged`, `submitLifecycleChanged`, and no
`bindingReadback`.

The unique local
`testInputTraceDistinguishesDeliveryRejectionResetAndBlockedEventsWithoutText`
is adapted to upstream JSON records. It checks that initial configuration does
not report input delivery; accepted/rejected readback records expose the
appropriate equality boolean; external reset emits no binding write/readback;
and disabled/invalidated events emit `publishIgnored` with the corresponding
configured/enabled flags. Private draft canaries remain absent from output.

The workflow edit changes only the text collector's category/prefix predicate
to `StudioTextInputTrace` / `KEYFILL_INPUT_TRACE_V1 `. Its exact before/after
hashes and substitution are in `a028-workflow-predicate.json`.

## Verification and limits

- `python3 scripts/agent_cycle.py check` passed structural/evidence-reference
  validation; it explicitly does not verify runtime truth or release readiness.
- `python3 scripts/agent_cycle.py next` reported M01's outstanding
  `persistence_smoke`; milestone files were not changed.
- Targeted `git diff --check` passed.
- A Python source comparison proved the app equals the exact upstream file
  after removing only the authorized DEBUG import/shared-sink addition.
- Method extraction proved no upstream method was removed; repository
  `native_test_shards.discover_methods("NativeTests")` reports 328 declared
  native methods, including 22 in `StudioTextFieldTests`.
- `a028-preservation.json` contains source hashes, retained method names,
  inventory counts, and explicit unrun flags.
- `a028-upstream-integration.patch` is the exact two-file diff against the
  upstream foundation. The original local patch remains separate.

No Swift compiler, native test, simulator, or Apple runtime was invoked by
A028. The compiler reservation and subsequent integrated validation belong to
A027/the integration lead. Source inspection and declared method counts are
not runtime passing evidence. No physical keyboard-delivery repair or release
acceptance is asserted.
