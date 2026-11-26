# Wave 05 implementation checkpoint

Base: `deffb5e3c93b507ceb4189a414a4ff0e3cf19395`. Scope: new `NativeTests/SpatialSelectionLifetimeTests.swift` only. **Commit: none.**

Prepared three native methods. The first keeps scene, selection and Fit request identical while changing callback A to B and then nil, checks UUID delivery through direct callback invocation, and verifies persistent content identities, selection indicator, camera identity, orbit position and controller target. The other methods retain fixture, indicator, stand and source references across deletion/reinsertion and invalid-scene/recovery, respectively. They assert lost live-content ancestry, rejection of stale hit objects, fresh node identities after the same UUID returns, and successful lookup of replacement selectable nodes.

Coverage gap: `SpatialInteractionTests` changes metadata/output during callback replacement and retains only the fixture during removal/recovery; `SpatialEntityUpdateTests` covers live mutations and stand thresholds, not removal of all retained equipment. The new indicator assertion allows it to remain under its detached fixture. No production defect or change is claimed.

Completed checks: pinned `git ls-tree` path discovery; `git show` inspection of `AGENTS.md`, startup documents, the three existing spatial test files and three relevant production files; `git status --short --branch`; `git log -4 --oneline` at the pinned base. `git worktree add --detach /tmp/keyfill05-be879deb/worktrees/w05-implementation deffb5e3c93b507ceb4189a414a4ff0e3cf19395` completed successfully.

The environment became unavailable during `apply_patch`. The pending call was terminated without a completion result; **the file write is unconfirmed**. No git diff check, file discovery check, build, native execution or commit completed. No tap, RealityKit, device, VoiceOver or performance execution is claimed.

Exact source, generated new-file patch, report and intended filenames are preserved in functions store. Disk artifacts and commit remain pending restoration. Lead should review the source-only patch, materialize it in the private worktree, run `git diff --check`, commit only the new file, then perform native validation on the integrated revision.

