# Finalized native results at ff8b683

Source: `ff8b683098a720b4c7abdddf212f85a79f3cfd39`. [Workflow 45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829). Native unit job `138342789331` and library/reference UI job `138342789365` were both completed failures when read back at **09:43:47 UTC, 2026-11-24**. Both unsigned simulator builds had succeeded. These failed runs are retained as failed evidence even after the corrective candidate is implemented.

## Native unit execution

The finalized native artifact is `14905719667`, ZIP SHA-256 `7fad93fa9c760d28ea88235a53b8c1122ea81b55c666e189a6fc3536f2f942b4`; archive CRC verification passed. It includes the finalized XCTest bundle, actual build/test logs and PDF attachments. Root extracted the test log and mechanically counted method outcomes:

| Native suite | Passed methods | Failed methods | Actual scope |
| --- | ---: | ---: | --- |
| BoundedFileReaderTests | 13 | 0 | Descriptor bounds, regular-file restrictions, cancellation and metadata preflight |
| LightingPlanPDFTests | 3 | 0 | Native PDF generation and checked report contents |
| ProjectDocumentIOTests | 9 | 0 | Coordinated project reads, cancellation, provider errors and separate directory/FIFO/symlink rejection |
| ReferencePhotoTests | 7 | 0 | Eight EXIF orientations, bounded decoding, cancellation, source preservation, alpha and tone exclusion |
| SpatialPreviewTests | 1 | 2 | Ordinary-edit orbit preservation passed; synchronous projection and FOV precision assertions failed |
| StudyRendererTests | 7 | 0 | Real simulator Metal parity, startup retry/cancellation, CPU routing and re-entry |
| **Total** | **40** | **2** | **42 methods, 33 failed assertions, no skipped test methods** |

The three isolated nonregular project inputs all completed: directory 0.015 seconds, FIFO 0.006 seconds, symbolic link 0.005 seconds. The previous combined-case stall did not recur in this run. These are simulator measurements of those inputs; arbitrary cloud-provider interruption remains outside this evidence.

The native renderer selected **Metal compute**. Six raw Metal/CPU parity fixtures ran, retaining the established assertions:

| Fixture | Mean channel error | Maximum channel error | Outlier fraction | Invalid-mask match |
| --- | ---: | ---: | ---: | --- |
| hard | 0 | 0 | 0 | true |
| soft | 0.00005425347222222222 | 1 | 0 | true |
| warm-rotated | 0 | 0 | 0 | true |
| dark | 0 | 0 | 0 | true |
| near-field | 0 | 0 | 0 | true |
| translated | 0.00005425347222222222 | 1 | 0 | true |

This is actual simulator GPU execution, not physical-iPhone performance or calibrated photographic rendering. Host stress cases outside the admitted Float32 domain remain documented separately; these six successful fixtures do not erase those limitations.

### Two SpatialPreview failures and corrective scope

The FOV assertion expected `26.991466561591626` degrees with a `1e-8` bound, while SceneKit returned `26.991466522216797`, exactly `Double(Float(expected))`. A reviewed representation-bound assertion is justified; the physical camera target remains unchanged.

The other method produced 32 failed clipping assertions. Independent geometry calculations reproduced its negative X coordinates and depth above one from the initial identity camera, FOV 48 degrees and default near/far planes 1/100. Apple documents that automatic transactions update presentation state at the next run-loop iteration. The standalone synchronous test had not reached that boundary. The corrective packet adds an explicit test flush and groups production updates into a nonanimated transaction; **all X/Y/depth clipping assertions remain unchanged**. This diagnosis does not claim that a settled on-screen fitted view was observed to be wrong. See [the independently reviewed correction](spatial-native-correction.md). The next native run must verify it.

## Library/reference UI execution

**Seven of eight UI methods passed**, with one failed recovery-confirmation query. The passing methods covered archived deletion with cancellation/relaunch, project create/duplicate/rename/switch/relaunch, stale-save recovery, stale-save reload confirmation, unsaved library boundaries, guided-rig abstention/apply/undo, and empty-reference comparison. All were actual simulator UI execution at this source.

The full-library recovery method reached the second confirmation after its cancellation checks, then failed to select `confirmRecoveryReplacement`: the accessibility hierarchy exposed nested buttons with that same identifier. The method did **not** complete its replacement/relaunch assertions, and its earlier checks are not a complete recovery pass. [The correction report](recovery-ui-correction.md) records the exact hierarchy and reviewed query/identifier repair.

The room/precision and studio/export jobs were still executing at the next 09:45:03 UTC observation. Their final outcomes must be recorded separately. Neither a partial UI run nor these individual native passes establishes the full regression, accessibility, device-matrix or release gates.

## Preserved logs

- [ff8b683-native-tests.log](ff8b683-native-tests.log), exact artifact entry, SHA-256 `5cd4211c435000990bc7c520b2a94ad8266073a9064bcfff8ceee3ffe03ea3e3`.
- [ff8b683-library-reference.log](ff8b683-library-reference.log), full completed GitHub job log retrieved through the connector. SHA-256 `37a9a49ca3ecba3bde979e8902e6f0e3dfbe3c98a6c58971349a990750e23bc4`.

Native build evidence, artifact packaging and Xcode/SDK details remain in [native-build-ff8b683.md](native-build-ff8b683.md). `native_build` passes at this revision; overall regression fails. M01 remains active pending its complete persistence smoke requirements. No protected quality threshold is changed.

## Finalized room/precision result

Job138342789450 completed **4/5 UI methods passed**, with all three precision-editor scenarios passing. The room boundary scenario passed; the resize/notes scenario failed after opening notes when its accessibility label did not contain `Room width: 6.00 m`. The actual failed recording visibly shows that exact correct width and the retained subject offsets. Automatic AX snapshots expose only a root, so the framework-internal label reason remains unknown. The focused correction provides the immutable notes string explicitly as the accessibility label and retains every existing content assertion and timeout. [Evidence and correction](room-notes-native-correction.md).

The full [room/precision job log](ff8b683-room-precision.log) is retained with SHA-256 `b14f3bc632658a1a31b327a89619e217ed04ef31fc76399b547f65b5ac4a0624`. Studio/export remains in progress at this checkpoint.
