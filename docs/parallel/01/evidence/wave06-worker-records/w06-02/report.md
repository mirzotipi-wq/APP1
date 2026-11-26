# W06-02 DATA: independent window feature regression

Commit: `5805620`. Added only `NativeTests/StudioFeatureWindowTests.swift` (166 lines, one async regression).

Two independent `StudioSession`/`ProjectStore` instances load the same real stored project and light UUIDs. Assertions cover distinct workspace/control/feature owners and rejection of foreign apply, retire, and finish callbacks. Window B has pending room work when A applies and saves. B's actual stale-snapshot save failure preserves its local scene, feature receipt, and logical identity; that same feature accepts another measurement. Successful recovery appends B's complete scene beside A's saved record, resets B's history/workspace, rejects its retired context, and leaves A's editor, library, and active feature unchanged. A fresh B presentation also survives late teardown.

Checks completed: clean frozen baseline inspection; required project/protocol/handoff/interface reads; `agent_cycle.py check` and `next` (structurally valid, M03 still outstanding); `git diff --cached --check`; scoped commit and clean final status. Acceptance manager reviewed the actual diff with no requested changes.

Not run: compilation, Swift tests, Apple/native/UI tests. No sleeps or mock executor. Root owns package membership, integrated execution, and publication. Runtime behavior remains unverified for this commit. Patch and full identity/hash receipt are retained alongside this report.
