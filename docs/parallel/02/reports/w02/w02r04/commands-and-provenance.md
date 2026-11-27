# W02R04 commands and provenance

- Frozen input and LightingCore v1 snapshot revision supplied by root: `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b`.
- Worktree: `/tmp/keyfill02-workers/w02r04`; `git rev-parse HEAD` returned the same revision.
- Existing independent fixture: `docs/parallel/02/reports/w01/w01r04/roll_area_probe.json`.
- Relevant reference method read: lines 48–74 of the sibling `roll_area_probe.py`.
- Scope: one 37-degree rolled, oblique, partially contributing rectangle fixture; no source or test-tree modifications.

## Executed numerical commands

Working directory: `/tmp/keyfill02-workers/w02r04`.

```sh
python3 /tmp/keyfill02/docs/parallel/02/reports/w02/w02r04/reference_convergence.py > /tmp/keyfill02/docs/parallel/02/reports/w02/w02r04/reference_convergence.json
cp /tmp/keyfill02/docs/parallel/02/reports/w02/w02r04/probe.swift /tmp/keyfill02-workers/w02r04/private-output/probe.swift
python3 /tmp/keyfill02-probe.py /tmp/keyfill02-workers/w02r04 /tmp/keyfill02-workers/w02r04/private-output/probe.swift > /tmp/keyfill02/docs/parallel/02/reports/w02/w02r04/probe-output.log 2>&1
cp /tmp/keyfill02-workers/w02r04/private-output/compile.log /tmp/keyfill02/docs/parallel/02/reports/w02/w02r04/compile-output.log
```

Both numerical commands exited 0. Compilation emitted no diagnostics. The helper uses `flock /tmp/keyfill02-build.lock` and `/tmp/keyfill02-toolchain/usr/bin/swiftc`, links `/tmp/keyfill02-swift-snapshot/v1/libLightingCore.a`, and imports `/tmp/keyfill02-swift-snapshot/v1/Modules`. It compiles only the standalone probe, then executes it. No package build or package test was run.

The saved probe and its executed private-output copy have identical SHA-256. The candidate uses the same fixture construction, call and relative-error expressions, replacing standalone unwrap/precondition operations with XCTest equivalents. This validates expressions against production Swift; it does not claim candidate XCTest discovery, compilation or execution by the package runner.

## SHA-256 provenance

| Artifact | SHA-256 |
| --- | --- |
| W01R04 `roll_area_probe.json` | `afd26819dfdc4ddbc73a2122424fe94ae0061e6ef02bf11a4948da0b5515009b` |
| W01R04 `roll_area_probe.py` | `e6507f1b03b60279a27f34965ba103b7ad108095f69e18b3d816b77590b3dd2b` |
| `IndependentRolledRectangleReferenceTests.swift` | `a96d6f08708c687542fb8fb7deaf938c9b7cf26248b0d0e23542a705d17db8cf` |
| `probe.swift`, both copies | `3d35775d2e800dc810c5d8931c5033cc7aa0c79829a8331d16d7d98ab8cd09a2` |
| `/tmp/keyfill02-probe.py` helper | `d64297cfed4fe6cb5d76626eaa79c92b016784a9229b5d73d3459ac2af07c592` |

Final worktree status contained only untracked `private-output/`; tracked source/test diff was empty. The evidence directory contains source, text and JSON only. The helper-created executable remains in the private worktree; no binary was copied into evidence, and no cleanup was performed.
