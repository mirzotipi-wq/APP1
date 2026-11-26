# W07-04 implementation report — original

## Conclusion
Recommend integrating commit cb0b3b7511c6f3b33f5354fe3873526a98d2088d. The only repository change is App/StudioView.swift, inside projectUtilityActions: 10 insertions and 3 deletions. The detached worktree is clean after committing. Root retains exclusive integration/build/push authority.

## Baseline, scope and acceptance
The inspected base is 4a2199d78ba52b9174381fdd1736f73e47959252. Startup documents and agent_cycle.py check/next were read/run. The scheduler selects M03 with editing, accessibility and persistence outstanding; its state/reference check does not establish runtime acceptance. Wave-five language in lane documents is stale relative to the manager's supplied wave-six completion checkpoint. No status or other-owner files were modified.

The previous outer Menu disabled state combined unloaded, protected storage, busy storage and active edits. This prevented opening Settings/purchase options when saved data was protected. Each Subject/Arrange/AR button now owns the original loaded/saveBlocked/busy disabling expression. The outer Menu retains active-edit disabling only. Settings therefore remains reachable during unavailable/busy storage when no edit is active. Export, Save, scene mutation policies, all labels/accessibility identifiers, and the 44-point menu label remain unchanged.

## Concrete stale Subject admission
The former Subject Menu closure assigned showSubject directly. A queued callback could survive a document switch or storage state change and open a live SubjectInspector with current bindings. Existing sceneAction checks generation/busy only; StudioSession.allowsMutation additionally checks loaded and saveBlocked. The new local generation capture and callback guard use that session method and a live active-edit check before presentation. Arrangement/AR keep their existing featureAction route and live openFeature admission. No new route abstraction was added. The separate Plan-marker Subject action is unchanged; the protected-storage view hides that workspace, and this work packet is restricted to the Menu.

## Actual checks
- Initial and final git status: clean detached worktree.
- git diff --check: exit 0, no whitespace errors.
- /tmp/keyfill01-swift-6.0.3/usr/bin/swiftc -frontend -parse App/StudioView.swift: exit 0, syntax only.
- git diff review: exactly the allowed file and Menu block.
- agent_cycle.py check and next: exit 0; metadata/queue checks only.
- An initial rg lookup used a nonexistent Sources/LightingCore/ProjectLibraryOperationState.swift path and exited 2. rg --files located App/ProjectLibraryOperation.swift; the corrected source read confirmed busy/generation admission.

## Limits and recommendation
No build, unit/UI test, Apple typecheck, native runtime, camera/photo, purchase/restore, upload or external communication was performed. Native default/largest-text protected-storage Settings/purchase navigation remains for the root's integration validation. Reference/Arrangement/Lux legacy Void producer callbacks still can consume rejected drafts; this patch does not address them. Integrate the narrow commit with the manager's independent native acceptance test work. Preserve source.patch, this original, report.md and receipt.json before worktree cleanup.
