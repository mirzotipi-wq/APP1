# Independent control runtime-only experiment review

**Scoped source approval**, against `9eddd97c5e638edf1768332d9d83d7dc2cccb72a`:

- Workflow SHA256: `ef07fb2d5013b5d3815c8a4e93e0d06b186871e6211711a664268e70489afe0a`.
- README SHA256: `f135e5d69194bb28d8bbcad7b6e78c23fe43eefddd4051b66c8669e6b2fd42d1`.

Independent reverse reconstruction exactly reproduces the base workflow after undoing only four lines: runtime identifier, required runtime version, missing-runtime error text and preboot lookup. The isolated control now requires identifier `com.apple.CoreSimulator.SimRuntime.iOS-26-4` and version `26.4.1`; the selected iPhone remains iPhone 17 Pro. Xcode 26.6/build17F113, build SDK26.5, primary APP1 runtime26.5, control Swift/project source, audit semantics, assertions, 10-minute boot, 6-minute test, 32-minute job and all other workflow bytes remain unchanged.

The reviewer independently read the actual retained inventory at `/dev/shm/keyfill-a100-control-9ed/evidence/{runtimes.json,simulators.json}`. It contains available iOS26.4.1/build23E254a and a matching available iPhone17Pro, UDID `A6574FEC-AE06-46C2-92CC-F2BBAB2A5601`. This is inventory evidence, not a simulator run. The owner's YAML/shell/Python and pure-selection receipts were inspected; no new test campaign was performed.

The preceding control run45632330705 stopped before any audit because its boot step exceeded its bound. The README correctly distinguishes that nonexecution from an audit-service timeout, labels this as a control-only experiment, preserves the primary requirements, and acknowledges uncontrolled hosted-machine variation. No runtime download, relaxed gate, deadline increase, expected pass, or runtime-specific causal conclusion is introduced. Actual admission/build/boot/audit results of this candidate remain pending.
