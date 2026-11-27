# Execution interruption and recovery

The execution environment became unavailable during wave 2. A subsequent command
returned: "No usable execution environment is available. Wait for an environment
to become available before using this tool."

The last verified remote checkpoint before the interruption was
`9c172d3e2d0c3f18636d84e8f31150236c63cbaa`. It preserves the original twelve
renders, baseline 366 Debug/366 Release results, optimized benchmark, and ten
completed wave-1 worker reports.

## Evidence recovered from completed tool outputs

- The unintegrated geometry candidate uses a triangle-area-scaled parallelism
  threshold and cached geometric normals. The actual Swift witness changed from
  no hit/no occlusion to hit and occlusion, distance 0.00004999790879948998 m.
  The independent plane oracle returned 0.00004999790731633365 m.
- The candidate rendered all twelve original configurations successfully. A
  completed byte comparison returned `allTwelveUnchanged: true` and
  `supported: true`. The complete local comparison file became inaccessible;
  this note preserves the observed terminal result without inventing that file.
- The no-light overhead-camera probe returned 322 unsupported pixels at 0.171 m
  and 328 at 0.18 m out of 384. Above at 0.20/0.25/0.30 m, and front/side at all
  five tested distances, returned zero. The exact probe and rows are recovered
  here from their completed command output.
- W14's analytic visibility test draft was prepared but its write failed when
  the executor disappeared. It is retained as an uncompiled draft, not a pass.

## Continued execution limits

GitHub source reads and writes remain available. After the interruption, workers
use immutable commit snapshots and return patches/reports in messages. No private
temporary worktree or local build is claimed for those assignments. Root alone
integrates to the authorized branch using a checked expected head. Existing CI
provides portable test/render execution; its actual terminal outcomes are recorded
separately. This is a recorded runtime limitation, not a statement that the
original private-worktree requirement was fulfilled after the interruption.

The environment subsequently returned, but its temporary files were gone. Root restored the verified remote checkout on the persistent workspace and recovered W12/W13 exact blobs (matching their original Git blob IDs). Private builds/worktrees are being recreated; source snapshots and interruptions remain explicit.

## Recovered probes executed

Root compiled the recovered tests on the unchanged production source: 24 selected test methods, 25 assertion failures in three methods. The original-source log and source hashes are retained. After the mesh and early cancellation corrections, all 380 Debug and 380 Release tests pass. W14’s recovered analytic draft is now compiled and its four tests pass; its earlier uncompiled status above records the interruption point.
