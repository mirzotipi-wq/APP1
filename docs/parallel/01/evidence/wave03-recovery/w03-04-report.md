# W03-04 — Plan session regression tests

Role: implementation; one fresh worker, no descendants.

Verified frozen base and commit parent: `966c9c21adbb685d82127e7f88981b74daf47e3d`.
Final local HEAD / commit: `bab813c5125b112c77ed367b184a3f5a88fae711`.
Worktree: `/tmp/keyfill-01-recovered/workers/w03-04/tree`.
Only committed path: new `NativeTests/StudioPlanSessionTests.swift` (277 lines).

## Authored — NOT executed

Six tests call the actual `StudioSession`, following the existing conditional
`KeyAndFill` / `StudioComposition` import pattern. Each awaits an asynchronous
`.load` executor returning nil. There are no sleeps or mirrored session algorithms.

1. Missing/unselected light IDs and stale generation leave both idle and active
   Plan state unchanged.
2. Zero/negative/nonfinite scale and nonfinite X/Z translations preserve idle
   redo and active drag state; a subsequent valid update retains cumulative
   translation against the frozen origin/scale.
3. A selection change commits one Plan transaction without changing scene or
   revision; repeated selection and delayed end add no history entries.
4. An old light's drag end and a mismatched generation cannot close the newer
   light's drag.
5. Discrete replacement during drag produces separate, coherent undo/redo steps.
6. Beginning another control commits the Plan drag; delayed Plan/control end
   callbacks preserve the new control's transaction and its grouped updates.

Assertions inspect complete scene, selection, revision, history and active drag,
including exhausted undo/redo checks that expose duplicate entries.

## Checks and limitations

Read all assigned directives/contracts and actual session, editor, history,
operation-adoption and existing test sources. Inspected the written file,
confirmed exactly six test methods, and verified the sole staged path.
`git diff --cached --check` passed. Commit parent matches the frozen base and the
post-commit worktree is clean.

No builds, test execution, compiler parsing, installations or pushes were
performed. Runtime/compilation acceptance is unverified. No production defect
was established through this static review; the root's separately identified
StudioView callback issue is outside this file's ownership. Earlier 392-test,
nine-test and syntax results are not transferred to this commit.

Recommendation: peer10 independently reviews this commit; root adds package
membership and performs serialized execution on the integrated source. No
production, package, CI or canonical status files were edited.
