# Execution environment interruption and recovery

The lane began at f150f98e35dd735927075aac4d2f8b02295c6a67. First-wave checkpoint 3d0e20616d0e771ad72161592c59105f591951c9 preserves ten actual worker reports, the unchanged-source C++ reproduction, and the ownership routes.

## Observed interruption

The original workspace had approximately99MB free. Its incomplete fresh checkout was moved to a temporary filesystem and made sparse without changing tracked content. When concurrent work filled /tmp, this lane's own77MB tree was moved to /dev/shm and its original path retained as a symlink. No other contributor's files were removed.

A shared Swift6.0.3 toolchain later became available at /tmp/keyfill02-toolchain. It was used read-only. The following compile attempt exited1:
```
flock /tmp/keyfill04-2987b1ee980d/build.lock /tmp/keyfill02-toolchain/usr/bin/swiftc -O -use-ld=lld -module-cache-path /tmp/keyfill04-builds-2987b1ee980d/module-cache Sources/LightingCore/*.swift docs/parallel/04/evidence/prepare-silhouette-fixtures.swift -o /tmp/keyfill04-builds-2987b1ee980d/oracle/prepare-silhouette
```
Observed compiler output: `error: compile command failed due to signal 9 (use -v to see invocation)`.
A subsequent diagnostic command could not start: exec-server transport disconnected and recovery timed out after45s. The execution environment then reported unavailable. Memory pressure is a plausible cause, not a proven diagnosis. The shipped Swift oracle was not executed by this local attempt.

## Preservation and continuation

Twenty detached sparse worktrees had been prepared; prepared workspaces are not worker counts. Wave1's ten completed reports are remote. Wave2's actual IDs, reports, patches and unavailable artifacts are recovered from worker conversation context and preserved as Git objects before integration. Missing original bytes are never reconstructed and presented as byte-identical originals.

Connected GitHub tools remain available. Subsequent workers use pinned Git tree/blob snapshots in separate fresh agent contexts and preserve their report/code blobs remotely. These are isolated source snapshots, not functioning physical worktrees. Local build directories and result bundles are unavailable; remote CI execution is reported separately. The original100-worker goal and ten specialist roles per wave remain unchanged; only actual returned run IDs count.

## Upstream dependency

Observed main remained9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318. Its four commits after f150 contain historical evidence/status updates and one source correction: b0d25ee disambiguates a local bounds value in UITests/StudioAppAccessibilityUITests.swift. This existing upstream correction is carried unchanged into the feature branch so native validation can compile. No shared build/CI configuration is edited by lane04. Main is not updated. The branch retains f150 as its inspected campaign baseline and the upstream merge as a distinct dependency.
