# W03-02 DATA — static receipt review

Verified HEAD: `966c9c21adbb685d82127e7f88981b74daf47e3d`.

**Recommendation: ACCEPT the reviewed production path.** No verified P0–P2 production defect or malformed-scene partial adoption. Static acceptance only.

## Verified boundaries

- `App/StudioSession.swift:181–213` reserves before closing edits, stages operation/editor copies, and validates saved scenes before publication. Invalid scenes cannot partially advance generation/library/editor. Failure releases only the matching reservation (`225–241`). Reservation itself intentionally closes an open edit (`182–183`).
- `App/ProjectLibraryOperation.swift:110–129`: load resets history; save/same-project metadata preserve scene/history; switch/reload/recovery reset history and presentation. First save preserves selection/history while changing generation.
- Production loads validate complete libraries; saves validate before CAS/write; recovery validates latest snapshots and proposed scenes (`Sources/LightingCore/ProjectLibrary.swift:64–74,159–225`; `App/ProjectStore.swift:40–60`). Unsupported schemas, duplicate project/light IDs, invalid inactive scenes, and missing/archived active projects are rejected. Invalid UUID strings fail decoding.
- `Sources/LightingCore/StudioEditorState.swift:104–122` validates before adoption, rejects scene replacement without history reset, and repairs selection to a live UUID/nil. Private history receives validated snapshots; standalone `SceneEditHistory` delegates validation to its caller (`SceneEditHistory.swift:3–7`).

## Nonblocking limitation: injected executor trust

**Severity: informational; no production impact established.** `ProjectLibraryOperation.swift:110–129` checks active-project existence; `StudioSession.swift:208–213` validates only adopted/saved scenes and publishes the original library. An injected executor can publish an invalid library envelope completely, rather than partially commit a failed operation.

Minimal reproduction, static only: decode valid library JSON with top-level `schemaVersion: 99` and a valid active scene; return it from an injected `.load` executor. Adoption accepts it although full library validation rejects it. Duplicate project IDs/invalid inactive scenes have the same gap. App construction uses the default executor (`App/StudioView.swift:6`, `StudioSession.swift:51–55`); injections occur in tests. Hardening: stage `result?.validated()` before adoption, publish that value, and cover malformed envelopes if alternate executors become supported.

## Actual checks and limits

Ran `git rev-parse HEAD`, `rg --files`, `rg -n`, `cat` of all assigned instructions/documents, and `nl -ba`/`sed` source/test reads. No builds/tests/install/source edits/status/CI/descendants. Historical 392 Debug tests predate the control-identity fix; nine affected session tests followed it. No transferred evidence. Apple SDK/runtime unverified.
