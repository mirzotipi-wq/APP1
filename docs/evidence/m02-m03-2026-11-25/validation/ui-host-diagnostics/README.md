# UI host diagnostics candidate validation

Final workflow SHA256: 6792b1c16bd96ceba120e1906c9ee7ebdbaab01d8b8fbfaf0da39f8b2c29fbdb. Baseline: 214ca90bbd166482277d33d63b89c1472ba9abf6.

`validation.json` records the final candidate, including the library-only Intel fallback. `workflow.patch` is its exact diff against baseline. Files prefixed `prior-7f2be855-` are preserved historical validation/diff for the earlier independently reviewed ordering/diagnostic candidate, before the fallback. Any historical runners-unchanged field applies only to that earlier source hash. Exact comparisons prove the final delta changes only two library matrix values and the explanatory comment; all executable blocks retain the 29-shell/seven-Python validation scope.

No Apple execution of the newly added captures is claimed. Collection is bounded and best effort; no timing, resource-pressure, accessibility or runner-availability improvement is established. See ../../followups/followup-ui-host-diagnostics.md and the separate actual f6 studio failure packet.
