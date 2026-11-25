# Independent macOS host SDK repair review

Existing worker a100 independently reviewed the shared frozen source and actual
Linux receipts. Root transcribed the worker's returned review; no new worker was
counted. The reviewer performed no builds, runtime tests, or source edits.

**Scoped approval to publish; no blocking finding.** Wrapper SHA256:
`d8c036aa7348fba636c4f9c41d3d6468e112c34445756eff4cf98befe87ae7d3`.
SDK test SHA256:
`a82c613240110043c95f0606f32600316fde383f33e6f79e6e512dacc35eae64`.

The Darwin branch discovers the selected Xcode's macOS host SDK with a bounded
ten-second xcrun call and passes a single explicit `-sdk` argument pair. It
records the command, result, selection environment, path and resolved path.
Missing, failed, timed-out or malformed discovery stops before compilation and
preserves the available receipts. Paths containing spaces remain one argument.

Linux compile arguments remain unchanged. Compilation/probe deadlines, the
six-minute CI step, failure checks and source-hash coverage remain intact. The
compile-manifest checksum covers the added SDK provenance.

The reviewer independently inspected the frozen-source Linux receipts: all 31
compiled source hashes remained stable; all eleven EFBIG checks and all three
rename/interruption scenarios passed; Linux had neither a `-sdk` argument nor
`hostSDK` metadata; the Python log records 35 passing tests.

The seven new SDK tests use mocked child execution. They establish command
construction and failure handling, not macOS compilation. The observed Apple
failure happened before the helper ran. Fresh Apple CI is still required to
establish that this repair resolves it.
