# W16 — Early cancellation preparation probe

Runtime/canonical task: `/root/wave02/resource`. Assigned input: `d0583603fa05d42d5b8e36d9b1e8353965989ea6`.
Assigned worktree/output: `/tmp/keyfill03-7f4b/workers/W16-resource` and `/tmp/keyfill03-7f4b/builds/W16-resource`.
No successful file reads/writes, commit, checks, Swift builds/tests or renders: three initial read-only commands and one apply_patch call were rejected because the execution environment was unavailable.

A narrowly scoped draft patch was prepared from the inherited exact StudyCancellationTests.swift. It preserves existing tests and adds three methods. The immutable recovery blob is `65314d8b869385e5e5eb20e158642649ba0175cf`; the acceptance leader created that blob, with no branch update.

| Probe | Required result | Predicted original result, not runtime executed |
|---|---|---|
| Width24, camera==subject, callback true, sphere interactive/reference | cancelled, exactly1 poll | invalidCamera, zero polls; expected failure |
| Same, mannequin | cancelled, exactly1 poll | Expected pass |
| Width23 or25, invalid camera, callback true/false, all3 renderers | invalidResolution, zero polls | Expected pass |
| Width24, invalid camera, false callback | invalidCamera; poll count unrestricted | Expected pass |

The last control intentionally avoids freezing the sphere's missing preparation poll. The draft is unapplied and uncompiled, not a passing regression. No production change, fixture replacement, cleanup or new context was created during recovery.
