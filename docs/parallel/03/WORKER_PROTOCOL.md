# Lane 03 worker protocol

This lane owns the CPU Study, mannequin geometry, reference-photo PNG sanitizer, Study fixtures,
and `App/ReferenceStudyPreview.swift`, with source-specific tests. The integration
branch is `finish/03-cpu-study-mannequin`. Do not write main, canonical agent state,
other lanes' source, CI, shared composition, GPU implementation or cache code.

Inspected campaign fallback: `f150f98e35dd735927075aac4d2f8b02295c6a67`.
Remote main observed at startup: `9e0e2ba7eded9bb5b91af53c44b4ff00efbdf318`.
No lane 20 campaign branch was published in the initial branch inventory. Later
main changes remain for lane 20 integration; this lane does not replace them.

Read `AGENTS.md`, `agents/OPERATING_PROTOCOL.md`, the applicable source, and
`docs/acceptance/m02-m03-code.md`. The user's lane ownership takes precedence over
the repository's older general main-integration directive. Preserve every existing
fixture and failure. Report host checks separately from native or physical checks.

Ten fresh wave leaders each perform the acceptance assignment and create exactly
nine fresh-context specialists: geometry/data, API, implementation, concurrency,
resource, consumer, accessibility/privacy, platform/performance, independent review.
Thus each wave contains ten actual workers, including its acceptance leader.
The root integrator is not counted. Never count followups as new workers.
The runtime permits four active agents total: root, wave leader, two specialists.
Queue specialists within that limit; do not spawn grandchildren beyond this plan.

Briefs at most 2,000 tokens; working target 12,000 tokens, checkpoint at about 60%
where measurable, final report at most 800 tokens. These targets do not alter
platform limits. Prefer bounded, specific source/probe tasks to repeated audits.

Use a private detached worktree for every worker, created sequentially with
`git worktree add --detach /tmp/keyfill03-7f4b/workers/Wxx-role HEAD` from the
integration checkout `/tmp/keyfill03-7f4b/repo`. It inherits sparse checkout.
Private outputs go under `/tmp/keyfill03-7f4b/builds/Wxx-role`. Only explicitly
assigned writers change source. Root integrates sequentially. Keep worktrees until
reports/patches have been pushed and their remote preservation verified.

Available read-only Linux Swift toolchain:
`/workspace/scratch/13a77d3f98df/toolchain/usr/bin/swift` (Swift 6.2.1).
Set PATH to that directory for Swift subprocesses. Do not alter this toolchain.
Root serializes heavy builds and renders; workers must request a build slot.
Initial workspace disk had only 95 MiB free; temporary memory-backed storage is
shared and must be monitored. Never remove another task's files.

## Worker metadata storage after wave 3

Creating linked-worktree indexes on the persistent volume exhausted its free
space during wave4. The source trees themselves fit in `/tmp`. New workers now
use a private sparse shared clone at `/tmp/keyfill03-7f4b/worker-control` as their
`git worktree add` origin. Thus both their trees and indexes are temporary; the
integration checkout and reports remain persistent. It shares immutable objects
from the integration checkout and has the original GitHub promisor remote for
missing objects. Root verified a clean W33 tree at the exact requested input.
Do not count an unused precreated tree as an actual worker. After a runtime reset,
recreate the control clone and requested trees, recording the interruption.

Only root removes completed workers after the report/source checkpoint is pushed
and verified. Existing active W31/W32 linked trees retain their original registry
until their wave is preserved. This storage change introduces no branch or source
ownership change and does not relax the private-worktree requirement.

Each leader writes `docs/parallel/03/workers/waveNN.json` and `waveNN.md` in the
integration checkout, exclusively owned for that wave. Record actual runtime ID,
canonical task path, role, assignment, input SHA, private worktree, output/report,
execution status, tests actually run and any commit for all ten workers. Store
individual <=800-token reports in the same folder. Send root concise findings.
Do not claim a pass from inspection, an unavailable test, or a source-text match.
