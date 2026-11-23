# Current handoff

**Stage:** M01 — foundation verification, with independent illustrative UI work.

## Present
- Redesigned native studio, overhead plan, illustrative 3D, four recipes, add/remove, undo/redo, local save and share text.
- Portable atomic file store and corrupt-data protection; domain persistence and recipe tests.
- GitHub Actions macOS pipeline with generated Xcode project, unsigned simulator build, UI smoke test and evidence artifacts.

## Verification
The complete portable package passed 11/11 tests on Linux Swift 6.2.1 at a04f2e955e095f8c6af98f37b501308e528fc508; the seven package/source/test blob hashes matched the integrated tree. Evidence: docs/evidence/core-2026-11-23.md. The macOS workflow run 45254550467 is queued as last observed; native build and UI smoke remain unverified. No real-device, calibrated rendering, commerce, customer or release evidence exists.

## Next work packet
1. Inspect Actions core and simulator logs and correct failures.
2. Record exact test revision, environment, logs and results in the evidence ledger; only then mark eligible gates.
3. Inspect UI screenshots, audit accessibility and use a real device. Keep illustrative SceneKit separate from M02 production renderer.
4. Continue physical photometry and reference fixtures after M01 is evidenced.
