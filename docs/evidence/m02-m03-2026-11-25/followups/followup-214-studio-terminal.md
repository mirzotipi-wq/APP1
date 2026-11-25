# 214 studio terminal result — actual Intel simulator pass

Run [45613203857](https://github.com/mirzotipi-wq/APP1/actions/runs/45613203857), job [139221045264](https://github.com/mirzotipi-wq/APP1/actions/runs/45613203857/job/139221045264), tested commit `214ca90bbd166482277d33d63b89c1472ba9abf6`. The terminal connector verdict is **success**. The complete decoded log independently contains all **20 unique required methods started and passed, zero failures, zero skips, no interrupted or missing methods**. XCTest reports 1,898.727 seconds of tests (1,898.760 seconds wall time); `TEST EXECUTE SUCCEEDED` appears at `2026-11-25T13:44:40.7228120Z`.

The source method list was read directly with `git show` for the tested commit before the transient environment reset. The 18 StudioSmokeTests and two LightingPlanExportUITests exactly match the 20 completed methods. The final four methods that did not start in the earlier f6 failure all passed here, as did recipe save/reopen and the tenth optics repetition. This run predates cbf's build-before-boot change and new failure/host diagnostics; its success cannot establish that those later changes caused an improvement.

## All ten optics workflows

| Workflow | Actual result | Seconds |
| --- | --- | ---: |
| EditingUndoRedoAndRelaunch | passed | 112.846 |
| Repeatability02 | passed | 105.557 |
| Repeatability03 | passed | 104.951 |
| Repeatability04 | passed | 113.418 |
| Repeatability05 | passed | 105.661 |
| Repeatability06 | passed | 90.198 |
| Repeatability07 | passed | 118.626 |
| Repeatability08 | passed | 108.466 |
| Repeatability09 | passed | 109.550 |
| Repeatability10 | passed | 90.938 |

The same job log records macOS x86_64, Xcode 26.6 build 17F113, and the exact214 checkout. Required test, unified-log collection, finalized native-result export, and both artifact uploads succeeded. This remains Intel simulator evidence; it does not certify the ARM RealityKit branch, physical-device behavior, or accessibility audits from a different shard.

## Preserved original evidence

Scratch directory: `/var/tmp/keyfill-c0abc39c4f18/214-ui-terminal-triage/studio-export/`.

- `complete-terminal-decoded.log`: the entire UTF-8 decoded connector response, 618,969 bytes, SHA256 `85cfc54f71a4b64570d90f23130a0058455fc3442675963154c04cec4dd3e125`. It is decoded text, not a downloaded compressed log archive.
- `terminal-excerpts.log`: 49 exact selected lines, 6,335 bytes, SHA256 `2a8bd5a673657465a9899ae2b9ca4d98d67f2e2d1247d01e500f0ee1e35711d6`. Every line was checked against the full log; this file is explicitly incomplete.
- `terminal-summary.json`: all start/pass events, durations, exact counts and limits; `terminal-job.json`: final step statuses; `monitor-history.json`: bounded polling observations; `artifact-metadata.json`: GitHub artifact/source/digest metadata; `receipt-sha256.json`: file hashes and scope.

Artifact metadata binds both uploads to214: full evidence ID15028619691,14,605,941 bytes, digest `b717146141baae6b2cb85ecde7f35a39c0464b4cc1bc8b81a09667ec0ba76987`; compact ID15029795076,4,526,852 bytes, digest `a7a6062f7c1eccfbbd83e4a5f29147548ccaf993678bbf97b391836f77a88eb7`. ZIP bytes were not downloaded in this receipt; no claim of independent archive verification is made.

No source edit, rerun, cancellation, gate relaxation or repository evidence change was made for this observation. The earlier failed f6 run remains retained as historical evidence; this successful run does not erase that failure or establish its cause.
