# W12 — Independent near-tangent finite mesh probes

Runtime/canonical task: `/root/wave02/geometry`. Input: `d0583603fa05d42d5b8e36d9b1e8353965989ea6`.
Original worktree/output: `/tmp/keyfill03-7f4b/workers/W12-geometry` and `/tmp/keyfill03-7f4b/builds/W12-geometry`; subsequently lost with the execution environment.
Original isolated commit: `d281faae891e38184bc96adb0d794656bb702592`.
Recovered exact file blob: `60b48b8637ee0a8fdf68aa33bba3c5563e2baabf`; original SHA-256 `6024e0cbfb315c68bb3f761fc725a90656d5ddffe1df16db9762081527d85aef`.

Only PortraitHeadMeshTests.swift changed (+98 lines). The exact original witness and 24 centroid rays cover three polar/three regular faces, incidences 1e-6 and 1e-8, and both tangent directions. Each requires barycentric weights 0.30–0.37, exactly one oracle hit, nearest-distance agreement, and before/through/after finite-window hit/occlusion classifications. Existing endpoint tests and 1e-8 m distance tolerance remain unchanged.

Actual Python oracle arithmetic checked 25 rays against 5,248 triangles: minimum weight 0.3333316597; maximum constructed-centroid distance deviation 2.091e-9 m. An initial upper-pole short-edge direction crossed another face; its failing script/log were retained locally before the outage, then the final matrix used the radial edge. Those local arithmetic artifacts became inaccessible; this report preserves the observed outcome without claiming their remote recovery. git diff --check passed and the committed tree was clean.

Swift tests were not executed. Root's original grazing failure remains separately attributed. No candidate or production intersection implementation was inspected by W12.

Recovery used the same context: fetched immutable baseline test blob 15559d988863af4d9eaed48027013270e7d15bba, inserted verbatim retained diff additions at four unique anchors, and created the exact full-file blob. In-memory SHA-256 exactly matched the retained pre-loss receipt, proving byte-identical recovery. No commit/ref mutation, rerender or new worker.
