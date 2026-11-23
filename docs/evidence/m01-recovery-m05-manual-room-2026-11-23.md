# Recovery and manual room placement cycle (2026-11-23)

Recovery source 4a3d0e6e, core job 138052958137, 99/99 Debug and Release, zero failures including all four recovery tests. Simulator 138052957650 queued.

Room source 5855ca5c, core job 138053931520, 104/104 Debug and Release, zero failures including all five room-coordinate tests. State/syntax and host parity checks passed. Simulator 138053931764 queued.

Manual room placement with user-measured rectangular room, subject floor offset and yaw, exact 1:1 rigid transform, signed wall coordinates, equipment heights and horizontal distances, center bounds warnings, native diagram and no scene mutation; precise locale-aware distance fields with explicit Set and invalid-input feedback. Six portable geometry/input tests and one native UI scenario added in total; latest input source CI pending. Session-only settings; not AR tracking, automatic measurement, collision/footprint or ceiling clearance.

- Recovery evidence: https://github.com/mirzotipi-wq/APP1/actions/runs/45277494136/artifacts/14868592104
- Manual room evidence: https://github.com/mirzotipi-wq/APP1/actions/runs/45277775880/artifacts/14867622512
- No new native screenshot or physical-device evidence yet. No release gate advanced. No independent review or parallel workers.
