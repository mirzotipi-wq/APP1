# Follow-up — witnessed library commit interruption and rename failure

**Implemented and actually passed on Linux x86_64.** This follow-up used existing worker a097; no new worker was spawned. Owned source changes are only `scripts/probe-library-commit-interposer.c` and `scripts/probe_library_commit_interruption.py`. a100 owns the helper extension; root owns its compilation and CI integration. No production persistence, app, workflow, wrapper, or full-suite changes were made by this worker.

## Actual result

The revised driver returned 0 with all three scenarios passing. The Foundation operation actually observed was `renameat`, with exactly one destination-matched pipe witness per scenario.

| Scenario | Witness and required result |
|---|---|
| Before rename | Complete 242,569-byte candidate already staged; old 3,900-byte library still present. Child stopped at the hook, parent killed its owned group, and a fresh helper reopened the complete prior three-project library. |
| After rename | Real `renameat` returned 0 before the hook stopped the child. Parent killed the group; a fresh helper reopened the exact complete 64-project candidate. |
| Rename-only EIO | Interposer returned `-1`/errno 5 at the exact destination, without calling real rename. Actual `ProjectLibraryFileStore.save` threw; helper immediately captured errno 5. The complete prior library survived. Cocoa's error chain remained generic code 512; it was not reinterpreted as POSIX evidence. |

All active-identity, unrelated-record, unrestricted-control, exact-byte, source-stability, binary-stability, and parent-state checks passed. This run used `/dev/shm` tmpfs; it establishes controlled Linux process/rename behavior, not disk durability, power loss, macOS, iOS, simulator, or physical-device behavior.

## Isolation and bounds

Only the save child receives `LD_PRELOAD` and the exact canonical owned `projects.json` target. The library is passed by file descriptor, avoiding preload path parsing problems. Setup, controls, and strict fresh-process verification run without interposition. Missing or mismatched hook evidence fails the scenario. Final-component symlink destinations are rejected from matching because rename replaces that entry rather than following it.

Every child has a private process group. TERM/INT handlers abort through cleanup; cancellation is blocked during spawn until the child handle is registered, and the original mask is restored before child exec. Cleanup kills the owned group and bounds direct-child reaping to five seconds. Ordinary phases/C compilation are bounded to 30 seconds, metadata to 10; overall deadline defaults to 120 seconds and accepts `--timeout-seconds` from 1–240. An outer caller must reserve cleanup margin and use graceful TERM before its KILL fallback. Arbitrary SIGKILL of the driver is explicitly excluded from cleanup guarantees.

## Evidence and meaningful negative checks

- Three-scenario receipt after the isolation/cancellation fixes: `/dev/shm/keyfill-c0abc39c4f18-commit-interruption-2/`.
- Actual TERM while the real helper was stopped at its witnessed hook: `/dev/shm/keyfill-c0abc39c4f18-commit-cancellation-1/`. A recorded test-only pause made the cancellation point deterministic. Driver exited 1 in 0.015 seconds, helper group disappeared, and fresh prior verification passed.
- Final-symlink negative: `/dev/shm/keyfill-c0abc39c4f18-commit-symlink-negative-1/`. Another symlink entry was replaced normally, emitted no hook, and left the configured target unchanged.
- Historical first pass: `/dev/shm/keyfill-c0abc39c4f18-commit-interruption-1/`; historical missing-hook and other-destination negative checks: `/dev/shm/keyfill-c0abc39c4f18-commit-negative-1/`. Their original source hashes and all raw output remain intact.

Python syntax passed; C compiled with `-std=c11 -O2 -fPIC -shared -Wall -Wextra -Werror` using GCC 14.2.0 without diagnostics. Root's helper manifest records Swift 6.4.3, successful optimized compilation, all 31 unchanged Swift inputs, and binary SHA256 `6ace669e9536f681d70a77f1451da16064d0491e31500a5a12785adab565fa4d` against base `d99c9bdfc1b3c1a185d87079efcc62cd34049279` plus the explicitly hashed helper extension.

The three-scenario, cancellation, and symlink receipts above retain Python hash `f6102479a242254e1572881aac611357193f2492f3ad550b787c7b12c5718be4`. Independent review then identified one final bookkeeping edge: cancellation immediately after success assignment must reset status to failed. That one-line correction is included in the final hash below. Root owns the integrated-wrapper rerun against those final bytes; earlier runtime receipts are not relabeled.

## Frozen sources and invocation

- C SHA256: `e412914f9bb4c9d83d760e5327c618d5f70772d2111907ecbc8cc917c82fdc2a`.
- Python SHA256: `a1d5344fded8681209d39c6723a8a20d25b3b31966eedef03ad1ca160feabd1b`.

```text
python3 scripts/probe_library_commit_interruption.py --helper HELPER --compile-manifest MANIFEST --output NEW_DIRECTORY --source-revision LABEL [--cc COMPILER] [--timeout-seconds SECONDS]
```

The final receipt is `NEW_DIRECTORY/result.json`; success requires `status: passed`. a100 independently approved the final source scope in `/var/tmp/keyfill-c0abc39c4f18/reports/followup-commit-probe-review.md`, preserving the exact source scope of earlier runtime receipts. The task closes only these bounded Linux diagnostic scenarios; broader persistence/device gates remain open.

## Final integrated pass on the final bytes

Root's final integrated wrapper returned **passed** at `/dev/shm/keyfill-c0abc39c4f18-integrated-persistence-final/evidence/`. I read the final receipts: all 31 compiled Swift input hashes and four diagnostic hashes remained unchanged; all 11 EFBIG checks passed; all three strict commit/interruption scenarios passed; and the commit driver recorded the final C `e412914f9bb4c9d83d760e5327c618d5f70772d2111907ecbc8cc917c82fdc2a` and Python `a1d5344fded8681209d39c6723a8a20d25b3b31966eedef03ad1ca160feabd1b` hashes unchanged.

Exact receipts: `wrapper-result.json`, `compile-manifest.json`, `probe/result.json`, and `commit-interruption/result.json` under that evidence directory. Complete wrapper output: `/dev/shm/keyfill-c0abc39c4f18-integrated-persistence-final/wrapper.log`. Root owns copying those receipts and publishing the integration. Earlier failed/negative and intermediate passing evidence remains preserved with its original source scope.
