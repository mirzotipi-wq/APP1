# cbf library keyboard readiness and host observations

Scope: bounded read-only triage of run **45623581873**, library job **139252380291**, exact source **cbf94cecb113c1f03b0b8c7287e763655c14ec11**. The shared full artifact **15031956986** is 141,943,904 bytes, SHA256 `6493755e13076d65d88d754c858e744430ae683f763830e96c27a54be115aed5`. a100 owns complete method accounting and audit interpretation. No source, workflow or repository-document changes were made.

## Actual keyboard state

The archived-delete test passed its initial Projects/Save readiness checks, saved, opened Projects and reached the new-project name field. Its sole functional failure occurs at `UITests/ProjectLibraryUITests.swift:130`, before typing `Keep`. The unchanged helper at `UITests/StudioContentReachability.swift:27–49` recognizes the introduction, taps Continue, then requires `(!proceed.exists || !proceed.isHittable) && typingKey.exists && typingKey.isHittable`, where `typingKey` is q/Q under `app.keyboards.firstMatch.keys`, within ten seconds.

The genuine recording `84877E74-464C-4A09-869F-CCAFF5F678F4.mp4` resolves the visible state:

| Recording offset | Direct visual observation |
| --- | --- |
| 88.0 s | Introduction copy and Continue visible; focused empty Name field |
| 92.0 s | Introduction/Continue gone; full lowercase QWERTY keyboard, including q, visible |
| 101.3 s | Same visible keyboard through the timeout; Name still empty because typing has not begun |

Thus Continue visibly dismissed the introduction. The assertion does **not** establish that the keyboard failed to appear. It also does not establish accessible identity/hittability: attachment `33663E36-F41C-4F20-85E2-D38C27E5E5E9.txt` contains only the q/Q query chain, not resolved keyboard/key nodes. The text-field attachment likewise contains only a query chain. No full failure AX hierarchy is retained for this helper. The newer `Project-control-readiness-failure` diagnostic was not triggered because its separate fifteen-second enabled predicates passed.

Raw log lines 241–254 record event synthesis at t=90.41, the predicate/Continue query at 91.89, q/Q existence queries at 100.71/101.11/101.12, and teardown at 101.76. The **8.82-second gap between logged Continue and key queries** consumes most of the predicate budget; it is not a measured single-call duration. Whether the remaining query failed due to snapshot latency, first-keyboard identity, key labeling or hittability is unresolved. No one of these possibilities justifies a product patch. A focused failure hierarchy or explicit per-clause query values/timing would distinguish them without changing the assertion/deadline.

Prior f6 readiness failures were not reproduced here: the large-library relaunch workflow passed in 61.791 s and the unsaved-library workflow in 45.899 s. Archived-delete reached substantially beyond its earlier initial Projects wait. This does not pass its incomplete archive/delete behavior or erase the earlier evidence.

## Host snapshots: observations, not causation

Before/after timestamps are **13:58:36.617375** and **14:21:55.984522 UTC**. They do not sample the 14:08 keyboard failure itself. Host RAM is 15,032,385,536 bytes (14 GiB); both snapshots report zero swap. Free pages correspond to 13.863/569.520 MiB; occupied compressor pages to 23.000/1,317.473 MiB. These are host-wide counters, not app allocation or proof of memory pressure. Disk space remained available.

The before-test process query reports **timed_out, elapsed 59.243 s**, despite requesting five seconds, and retained no process output. This is concrete collection/host latency, with no established cause. The after-test query completed in 1.483 s but its output was truncated at 65,536 characters. Its process CPU values cannot establish CPU peaks or state at the keyboard failure. No causal benefit from build-before-boot, definitive resource-pressure diagnosis, or physical-device performance acceptance follows from these two snapshots.

## Retained repository provenance

[Packet index](../validation/keyboard-readiness/README.md), [exact keyboard excerpt](../validation/keyboard-readiness/cbf-keyboard-excerpts.log), [host summary](../validation/keyboard-readiness/host-capture-summary.json), [query attachment](../validation/keyboard-readiness/key-query.txt) and [attachment manifest](../validation/keyboard-readiness/attachment-manifest.json) retain bounded text evidence. The [original source/derived-file index](../validation/keyboard-readiness/investigation-source-index.json) records the artifact, original log, video and decoded frame hashes. Its absolute scratch paths are original provenance, not repository links. Videos, PNG frames, ZIP archives and the complete raw native/job logs are excluded from this packet. The three original-resolution frames were visually inspected; their derived hashes and recording offsets remain in that index.

The helper and library test source were unchanged between cbf and checked-out 9eddd97c5e638edf1768332d9d83d7dc2cccb72a at this investigation. A later [helper candidate](followup-keyboard-helper-semantics.md) is documented separately and has no executed pass claim. This repository edition changes only links/provenance text; [copy-manifest.json](../validation/keyboard-readiness/copy-manifest.json) binds both the original report and this edition.
