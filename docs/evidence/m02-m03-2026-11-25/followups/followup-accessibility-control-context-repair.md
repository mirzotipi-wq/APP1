# Accessibility-control workflow context repair

Base: b26d3caa498d9f5e75758718a4a932cb0c0ac172. The first control run45630592265 was rejected before jobs, as reported by root; it did not build or execute the audit. Root retains the actual GitHub annotation evidence.

The official [GitHub context-availability table](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability) excludes runner from jobs.<job_id>.env, while allowing it in step run/with contexts. The authored workflow incorrectly used runner.temp for three job-level environment values. Earlier YAML/shell/Python checks did not validate this GitHub expression-context rule.

The exact repair removes those three job-env expressions and initializes the same absolute paths from RUNNER_TEMP at the beginning of the existing record step. They are exported for that step and appended to GITHUB_ENV for subsequent steps. The final artifact action retains its legal step-with runner.temp reference. No step, deadline, path value, audit source, test selector, assertion, exit-status handling, or existing primary workflow changes.

Frozen workflow SHA256: 10b38c89d404a625d8b44390b4b4ed0d63d4bf01c6b88095a1ef00a04e1e922d.
Prior SHA256: e9241d0ef66cc09e33ef0043975b82114a1ea841f7953de89e5da49241f0cf8f.
Exact diff SHA256: 8451740787eeb3117f20d6c12d8e81fc07c188f8a1fa4581e4d679b2970f86f7.

Validation: the new file exactly equals the prior bytes plus the approved eight-line delta; YAML, seven bash blocks, and six inline Python blocks parse. A real shell-only check with spaces in RUNNER_TEMP confirms both current-process exports and the exact GITHUB_ENV values. Source/primary workflow remain unchanged. Receipts are in ../accessibility-control-context-repair/validation.json and workflow.patch.

This is a local workflow correction, not proof of GitHub admission or an Apple audit result. Publication and actual next-run observation remain necessary.

