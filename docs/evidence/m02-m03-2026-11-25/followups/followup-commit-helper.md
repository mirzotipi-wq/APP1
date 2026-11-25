# Follow-up — atomic commit helper

Source frozen at `1a02498fdcfefc4b3805b2e4e4b45cfd726e8ed10a17e4d9e91f2ed7bc8dda40` (`scripts/probe-atomic-library-write.swift`), based on main `d99c9bdfc1b3c1a185d87079efcc62cd34049279`.

The original `setup`, `control`, `inject`, and `verify` behavior and JSON contracts remain. New modes:

- `save ROOT`: calls the same production `ProjectLibraryFileStore.save(candidate, replacing: prior)`. Normal return reports `save_complete`; a throw retains `save_threw`, immediately captured errno and the error chain.
- `verify-candidate ROOT`: fresh-process complete library and exact-byte equality with the candidate, active identity, all candidate records, both unrelated records, and independently reopened unrestricted control. Status is `candidate_verification_complete`.
- `verify-either ROOT`: accepts only a complete prior or candidate snapshot with matching bytes, reports which one, and retains identity/unrelated/control checks. It is optional diagnostic support.

Contract agreed with a097: pre-rename interruption and rename EIO use strict existing `verify`; post-successful-rename interruption uses strict `verify-candidate`. Each scenario has fresh fixtures and independent setup/control. A witnessed hook plus observed stop/kill belongs to the driver; helper output alone cannot establish interruption.

Static diff/whitespace review passed. No Swift build or runtime execution performed. Root should compile the frozen helper and run both existing EFBIG and new scenarios. From the repository, using the available Swift compiler and a fresh private build directory:

```sh
"$KEYFILL_SWIFTC" -O -module-cache-path "$KEYFILL_PROBE_BUILD/module-cache" Sources/LightingCore/*.swift scripts/probe-atomic-library-write.swift -o "$KEYFILL_PROBE_BUILD/atomic-library-write-probe"
```

No production, workflow, wrapper or protected gate changes. This supports host persistence evidence; it supplies no physical-device or full-milestone acceptance.
