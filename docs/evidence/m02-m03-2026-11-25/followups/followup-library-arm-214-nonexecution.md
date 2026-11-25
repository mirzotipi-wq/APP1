# ARM library job: terminal nonexecution at 214ca90

Existing worker 100, read-only CI observation. [Run 45613203857 / job 139221045245](https://github.com/mirzotipi-wq/APP1/actions/runs/45613203857/job/139221045245), commit `214ca90bbd166482277d33d63b89c1472ba9abf6`.

The `ui (library-reference)` job requested label **macos-26** at **12:57:40 UTC**. Repeated allocation snapshots showed `status=queued`, `runner_id=0`, empty `runner_name`, and zero steps. At **13:13:38.170 UTC**, the API reported the terminal outcome **cancelled**, completed at **13:12:42 UTC**: **15 minutes 2 seconds without runner acquisition**. The API's initial `started_at` equals queue creation; it does not establish runner execution.

No build, XCTest method, or accessibility audit executed in this job. All 11 library/reference methods remain unrun at this revision. This outcome does not prove or resolve an application defect, AX failure, or a global service outage.

The commit check-runs collection confirms **four annotations** for this exact check run. Root read the official visible Annotations panel at **13:17:43 UTC**, retaining **one error and three notices**. The error says: **“The job was not acquired by Runner of type hosted even after multiple attempts.”** Each notice explicitly cites macOS arm64 capacity constraints and possible longer queues. The [exact annotation receipt](../validation/library-arm-214-terminal/annotations.json) was copied byte-for-byte, including root's browser-observation provenance. This resolves the earlier missing-text limitation: the supported diagnosis is hosted-runner nonacquisition with official ARM capacity notices, not a global-outage claim. No browser mutation, workflow cancellation or rerun was performed to obtain this evidence.

[Terminal job metadata, check-run metadata and acquisition snapshots](../validation/library-arm-214-terminal/receipt.json) are retained. The broader run remained in progress at the last observation, so this report makes no terminal claim about the other jobs. No rerun or cancellation was requested by this worker.

## Independent review of available-host fallback

Worker 100 compared the final workflow SHA256 `6792b1c16bd96ceba120e1906c9ee7ebdbaab01d8b8fbfaf0da39f8b2c29fbdb` with the preserved, root-approved ordering/diagnostics candidate SHA256 `7f2be855ca5b5dd39edff2a1751b5ddb1efe1870c75cbb0f0e49aa0a0d6ddedd`. The complete difference is only the library shard's runner (`macos-26-intel`), expected architecture (`x86_64`), and explanatory comment. Every runtime command, selector, audit handler, assertion, artifact path and deadline is unchanged by this fallback. No blocking integration finding.

This selects the runner pool that has actually acquired hosts in this run. It does not establish an Intel accessibility, library-readiness or resource-pressure fix. All full audits remain required; an actual successful run is still necessary. The separately frozen diagnostic test edits improve observability only. No unchanged ARM allocation retry is proposed.
