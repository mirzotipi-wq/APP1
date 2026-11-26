# W10-06 — independent lifecycle challenge

Reviewed integrated `1f14d48a2e640ee9fe7986f15c20622461ede03f`; test/helper blobs exactly match `61183b6`/`7cfab9d`. No demonstrated blocker; native execution remains required.

**Scheduling:** Twelve main-queue turns are bounded work, not a proven SwiftUI transaction barrier. Concrete possible false failure: current revision metadata arrives before column placement, header width remains 900, and pass 2 returns horizontal frames during the forced-column phase. Geometry then fails correctly for that snapshot. The source does not prove this ordering occurs. `layoutIfNeeded` documents pending UIView subtree layout, not a guarantee that all future SwiftUI updates have completed. Require the real hosted run; if reproduced, await a phase-specific layout observation with a finite deadline.

**Falsifiability:** Revision, environment and State UUID update together; geometry is read from exactly six currently attached probes. Three distinct installed UUIDs must survive eight phases. Width, forced-column, accessibility growth and narrow multiline checks reject stale transitions. No stale callback cache or post-loop action can manufacture success.

**Window:** Requested 1800-point window size is not asserted against scene bounds. However, the separately fixed header width is measured, so a smaller scene cannot silently shrink tested layout width. This does not establish onscreen visibility or real StudioView control behavior.

**Lifetime/layout:** Each continuation resumes once; deferred teardown detaches the host and restores the previous key window. No fixture retention cycle found. Measurement/placement independently select from the same normalized proposal; zero/unbounded behavior was inspected only.

Read mandatory context; `agent_cycle.py check` and `next` exit 0 (structure only; M03 active). Frozen `adffee463896ba3484a6dde883f7e6745a4c0c6e` worktree remains clean; empty patch. No builds, native execution, edits, extra tests or pushes.
