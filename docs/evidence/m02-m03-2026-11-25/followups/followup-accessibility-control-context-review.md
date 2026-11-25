# Independent review of control workflow context repair

**Scoped approval of the narrow source fix**, based on published base `b26d3caa498d9f5e75758718a4a932cb0c0ac172`. The final workflow SHA256 is `10b38c89d404a625d8b44390b4b4ed0d63d4bf01c6b88095a1ef00a04e1e922d`; patch SHA256 is `8451740787eeb3117f20d6c12d8e81fc07c188f8a1fa4581e4d679b2970f86f7`.

The first review missed a GitHub expression-context restriction. Its original approval is retained as historical evidence rather than rewritten. The old workflow hash was `e9241d0ef66cc09e33ef0043975b82114a1ea841f7953de89e5da49241f0cf8f`. An independent connector read of control run [45630592265](https://github.com/mirzotipi-wq/APP1/actions/runs/45630592265) returned an empty jobs array; no control audit or Apple compilation ran. This reviewer has not independently observed a rejection annotation.

GitHub's [official context availability table](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability) excludes the runner context from job-level env while allowing it in step.with. The three old runner.temp expressions were therefore invalid in their original position.

Independent exact-byte reconstruction against b26 confirms only the authorized delta: remove those three job-env expressions, then export the same three paths from quoted RUNNER_TEMP values and append them through a fixed printf format to GITHUB_ENV at the start of the existing record step. Exports make the values available immediately to that shell/Python; GITHUB_ENV provides them to subsequent steps. Quoting preserves spaces. The artifact step's remaining runner.temp expression is in the documented supported step.with position.

All remaining workflow bytes are unchanged, including the 32-minute job, 30-minute summed step limits, 10-minute boot, 6-minute audit, exact selector, full audit semantics, failure propagation, provenance, upload, permissions, triggers and concurrency. The control Swift/project files, primary workflow and app/native/UI sources have no diff. The owner's recorded YAML, seven shell and six Python syntax checks and focused shell path-export check were inspected; this independent review did not run Apple tools or trigger CI.

The unsupported expressions are removed. Actual GitHub admission, build, simulator launch and audit outcome remain pending the replacement run. The old zero-job failure is not accessibility evidence and does not alter any required full-app gate.
