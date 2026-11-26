# W06-resource

Runtime/task: `/root/wave01/resource` (`list_agents` observed).
Input: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Worktree: `/tmp/keyfill03-7f4b/workers/W06-resource`, clean detached HEAD.
Assignment: pre-cancelled sphere setup bounds, portrait comparison, W2 regression.
Status: inspection complete; no tests/builds/renders/source edits/commit. Private output directory unused.

## Findings

`ReferenceStudy.swift:447–498` performs camera/geometry validation, lighting preparation, color-transform construction and image-array initialization before its first poll. Lighting (`232–265`; grid at `11`) validates the scene, creates 1 sample per active point/directional emitter or 64 interactive / 1,024 reference samples per rectangle. The 12-light limit (`Scene.swift:64`) bounds preparation at **768 / 12,288 samples plus 12 area guards**. Validation also creates an ID map/set (`77`).

Image payload maxima: interactive 192×128 gives 98,304 RGBA + 24,576 mask bytes (**120 KiB**); reference 96×64 gives 24,576 + 6,144 (**30 KiB**). These exclude array capacity, metadata and sample storage; no RSS measured. First-poll cancellation precedes pixel evaluation (`470–475,498–502`), so this gap does not violate the eight-pixel bound. Invalid setup may throw without polling.

Portrait checks width, then cancellation (`PortraitStudy.swift:164–167`) before setup/buffers (`168–184`). The previously recorded head initialization during camera exclusion (`77,89–91,173`) is after this poll.

## W2 regression

At width 24 with `camera = subject`, table-test both sphere qualities and portrait: callback increments once and returns true; require `.cancelled`, one poll. Current sphere throws `.invalidCamera`, zero polls. Preserve false-callback `.invalidCamera` and invalid-width `.invalidResolution`/zero-poll controls. Initial sphere cancellation belongs after cheap resolution validation, before remaining setup. Valid-scene `{ true }` alone already passes and cannot detect avoided preparation. Existing `StudyCancellationTests.swift:55–95` covers pixel/final checkpoints, not setup ordering.

## Commands actually executed

All subprocesses used `TMPDIR=/home/agent/keyfill03-7f4b/tmp`: protocol/AGENTS/acceptance `cat`; `git status --short --branch`; `git log -3 --format='%H %s'`; bounded `rg --files` and `rg -n` source/test searches; inline Python numbered source reads and report writes. One combined `rg` exited 2: missing `SceneValidationTests.swift`; existing `SceneTests.swift:44–56` matched the 12/13-light boundary. No runtime pass claimed.
