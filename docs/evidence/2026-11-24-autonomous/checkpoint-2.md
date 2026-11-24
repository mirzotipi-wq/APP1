# Editable project copies and verification repair — checkpoint 2

## Exact revision and results

Source revision `e45a1c8b0c1b01468f9f9f52812e118db18928fa`, tree `839e5c66a1b5733bc473759198cb7c3190ae434c`, was pushed to main and read back through GitHub. The index was exported to an isolated directory before testing, so later renderer work was excluded.

- Debian 13 x86_64, Swift 6.4.3: **187/187 Debug and 187/187 Release**, zero failures.
- **24/24 Python** evidence and native-shard validator tests. Recursive discovery now catches nested UI classes, including previously silent omissions; the real six classes remain assigned exactly once across three shards.
- Native Swift syntax parsing and repository state validation passed. No local Apple SDK or native execution is implied.
- [Workflow 45353070472](https://github.com/mirzotipi-wq/APP1/actions/runs/45353070472): core in progress at observation; native jobs not yet started. Current native gates remain unverified.

Commands: `swift test --jobs 2`, `swift test -c release --jobs 2`, `python3 -m unittest discover -s scripts/tests -p 'test_*.py'`, `python3 scripts/agent_cycle.py check`, `python3 scripts/native_test_shards.py check`, `swiftc -frontend -parse App/*.swift NativeTests/*.swift UITests/*.swift`. Swift PATH pointed to the verified 6.4.3 Debian toolchain recorded in checkpoint 1. Raw host test timestamps differ from connector UTC; preserved verbatim, not treated as duration evidence.

## Implemented behavior and independent corrections

The version-1 editable-project envelope is limited to 8 MiB and carries the name and validated scene. It rejects malformed, unsupported and unexpected envelope fields, migrates supported scene versions and preserves exact numeric values. Library IDs, active/archive state and reference photographs are absent. Import creates a fresh project through the existing optimistic transaction; full/dirty/unavailable libraries cannot import. Export captures the current scene and works without a free library slot, preserving unsaved work when all 64 projects are active.

System file export is immutable and reports saved only after success. Import holds security-scoped access across NSFileCoordinator provider materialization, reads the supplied coordinated URL with a regular-file descriptor and hard byte bound, and propagates cancellation. An independent reviewer identified missing file coordination in the first implementation; it was corrected before this commit. Native tests cover exact readback, cancellation, provider coordination errors, directories/symlinks/FIFOs and oversized/malformed input. These native tests remain unrun locally; actual Files/iCloud providers and picker behavior require native/device evidence.

Evidence validation now retains full gate provenance and supports explicit `scope: historical` records that cannot replace newer current observations. Fourteen regressions cover strict data types, dates, dependencies and provenance selection.

## Observed historical native evidence

At older `cab674175233249e8785797d283e414da23765fd`, [run 45346996294](https://github.com/mirzotipi-wq/APP1/actions/runs/45346996294) logs show both unsigned simulator builds succeeded, **10/10 native unit tests passed**, and **7/7 library/reference UI tests passed**. Those seven comprise five project-library and two reference-comparison tests. The room/precision shard passed both room tests then exceeded its 32-minute step budget during precision testing. Compilation had used roughly 20 minutes of that same step. This is a failed/incomplete shard, not a complete regression pass.

The workflow now builds UI bundles separately with a 25-minute build budget and runs `test-without-building` using the same scheme, configuration, simulator and DerivedData with a 32-minute test budget inside a 70-minute job. No selectors or scenarios were removed. Main-branch concurrency prevents superseded new runs from building a queue; older runs created before the grouping remain separately visible.

Genuine historical iPhone 17 Pro screenshots were downloaded from [compact artifact 14899882715](https://github.com/mirzotipi-wq/APP1/actions/runs/45346996294/artifacts/14899882715), ZIP SHA-256 `b14828fbd374dd3e3f367dcce4033cdb74caf9ac5d3e2999ee2f9dbfa94b4b43`. The root visually inspected Project-library and Reference-comparison-empty PNGs with the included test manifest. The library clearly distinguishes the current project; the reference view displays an empty photo state, actual Metal study and uncalibrated-preview description. This review is limited to two historical screenshots, not current layout, accessibility or device acceptance.

## Remaining work

M01 stays active. Next integrate the independent mannequin BVH oracle and measured rendering work, inspect current native CI, then verify actual editable-copy, provider and recovery user flows. No calibrated rendering, physical-device performance, AR, commerce, customer validation or release approval is claimed.

## Raw logs

- `cycle2-debug.log` SHA-256 `67a3978dbe6af8afd94c5849b11e18d2a6b0cc9e9845559566886f689c6440b6`; 187 tests, zero failures.
- `cycle2-release.log` SHA-256 `8e6ceada0d96283487db7529cc4c6c3a2dae11f6449b616a5dd9afa776e44a39`; 187 tests, zero failures.
