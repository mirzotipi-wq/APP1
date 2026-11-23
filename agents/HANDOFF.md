# Current handoff

**Stage:** M01 active, M02 pending. The independent ideal photometry gate has passing portable evidence; no complete milestone yet.

## Integrated this cycle

- Baseline: 426d43f761f31ad1180bdb3db6b76d48552d51b3.
- 6254c9d9e49eb3d10cdf062023624231141eb9f5: bounded scene reads; differentiate missing from inaccessible/invalid; reject non-regular files; preserve oversized, malformed and symlink targets; five regression tests; UUID-isolated native save/reopen and corrupt-data smoke cases.
- 9b5fd3a093615daa4b2e1b1a466bdf4117262d99: normalized directions, cosine-weighted oriented point sources, finite Lambertian rectangular emitters; six additional XCTest cases with analytic and independent numerical fixtures.
- Existing editable overhead and illustrative 3D studio, recipes, light management, undo/redo, local save and share text preserved.

## Verification

All 22 portable XCTest tests passed, zero failures or skips, on Linux Swift 6.2.1. All ten source/package/test Git blob hashes were checked against the integrated tree. See [cycle evidence](../docs/evidence/m01-m02-2026-11-23.md). The ideal point/rectangle math passed the declared numerical gate (maximum area error 0.0678272% on ten fixtures), not calibrated rendering. The app still uses illustrative SceneKit lighting and the old normal-incidence inspector; the new domain photometry is not wired into that preview. No independent reviewer or physical device available.

GitHub Actions main runs 45254550467, 45256006750, 45256267785 were queued at observation, with both core and simulator jobs queued, no executed steps. The latest source revision is [run 45256267785](https://github.com/mirzotipi-wq/APP1/actions/runs/45256267785). Native build, UI smoke, artifacts and screenshots remain unverified. M01 cannot complete until those gates have passing evidence. Do not claim signed/device or App Store build.

## Next executable packet

1. Inspect latest native build and UI smoke job; if failure, inspect logs and fix root cause. Capture exact Xcode/SDK/simulator, screenshots and result bundle; verify create/edit/save/relaunch and corrupt-file protection. Run agent_cycle.py check and next on a real checkout. 
2. Only mark M01 complete if its required gates pass. Advance M02 when eligible.
3. Integrate point/area math with explicit receiver geometry and source orientation into editor and production RealityKit/Metal adapter. Preserve scene schema compatibility and add rotated emitter, grazing angle and coordinate-transform tests. UI must label estimates as ideal; do not conflate cd, watts, lux or SceneKit intensity.
4. Prepare rights-cleared reference fixtures and measure performance on a physical iPhone. Real-device, independent photographer, customer, privacy, commerce and release gates remain outstanding.

No owner action required for these code changes. Physical device access and independent validation are required later. No parallel workers were available; specialist reviews were sequential/self-review.
