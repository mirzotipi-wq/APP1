# Known nonregular imports before file coordination

## Observed native failure and hypothesis

The completed simulator job for source `0fce248b4e61bace88002b40f6c56fddedb19c8a`, job [138314533584](https://github.com/mirzotipi-wq/APP1/actions/runs/45355893140/job/138314533584), passed nine bounded-reader tests, three PDF tests and six document-I/O tests. Its combined symlink/directory/FIFO test began at 08:49:41Z and did not finish before cancellation at 08:57:50Z. The exact selected lines remain in [0fce248-native-test-excerpt.log](0fce248-native-test-excerpt.log). This reviewer read those lines and the associated implementation. The available log does not identify which of the three items stalled, and it does not prove an internal Foundation blocking mechanism.

The source did demonstrate an ordering weakness: `ProjectDocumentIO` entered `NSFileCoordinator` before rejecting a known nonregular selected pathname. Its authoritative descriptor checks occurred only inside the coordinator accessor. This correction rejects those known invalid items before invoking coordination; native rerun must determine whether the observed stall is resolved.

Reviewed base: main `9724cc26b8de80aaad28474674cbdb80e442b926`, whose executable packet is `0d63dd872bbd20aaa72f9263b51e2208b6ee926f`. Other specialists' pending envelope/numeric corrections were not changed.

## Implemented correction

`BoundedFileReader.rejectKnownNonRegularFile(at:)` requests final-path metadata through `lstat`. A known symlink, directory, FIFO or other nonregular type is rejected. A regular type proceeds. A metadata lookup failure is deliberately left to the coordinator/provider, which may materialize or relocate the selected file; the preflight does not open or read its contents. Non-file URLs and unrepresentable filesystem paths remain invalid, and actual task cancellation is checked first.

`ProjectDocumentIO` calls the preflight after acquiring security scope and before constructing/entering file coordination. The same scope remains open through provider access and actual bounded reads. Shared translation of reader errors preserves the existing import error categories.

The pathname result is **not** a security authorization or proof about a later file. Inside the coordinated accessor, the existing `O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC` open, descriptor `fstat`, actual-byte bounds and cancellation checks remain unchanged. A regression replaces a path with either a symlink or FIFO after a successful metadata preflight and verifies that the later descriptor read still rejects it without changing unrelated bytes.

## Native test correction

The previous combined test is replaced by three separately named XCTest methods for symlink, directory and FIFO. Each observes the real asynchronous import through a five-second XCTest expectation, records a failure if completion is missing, requests cancellation on exit, and checks the original file bytes. It does not await a stalled task indefinitely after XCTest has already reported a timeout. A test-only locked result holder allows the body to inspect a completed outcome without an unbounded second wait.

All original type-rejection and source-preservation assertions remain. No required input was removed, no timeout is converted to success, and no fixture is skipped. The native document-I/O class grows from seven to nine methods; the bounded-reader class grows from nine to thirteen. Native unit discovery remains automatic, with the six UI classes still assigned exactly once by the separate shard check.

## Actual verification

Linux x86_64, Swift 6.4.3. Only the platform module/namespace was adapted in a scratch copy (`Darwin` to `Glibc`); the metadata and descriptor algorithms and XCTest assertions were otherwise retained. The scratch package is `/workspace/scratch/73dcd6a65726/verification/native-import-posix` and is separate from the app and shared build lane.

- **13/13 Debug and 13/13 Release tests passed**, zero failures. These include all nine earlier descriptor tests and four new preflight tests.
- New coverage: real symlinks/directories/FIFOs rejected by metadata, regular/missing metadata paths left for coordination, non-file URL rejection, cancelled-task rejection, and path replacement after preflight still rejected by the descriptor reader.
- `swiftc -frontend -parse` passed for all four changed native source/test files.
- Native shard coverage, agent-state structural validation and the four-file whitespace check passed.
- A comment was clarified after the POSIX runs to say that the app requests metadata without opening/reading contents, without claiming what an arbitrary provider might do internally. The native test moved its existing source-byte assertion before the timeout guard, so even a failed timing case checks preservation. Neither change affects the executed POSIX helper/test logic.

Commands:

```sh
swift test --package-path /workspace/scratch/73dcd6a65726/verification/native-import-posix --jobs 2
swift test --package-path /workspace/scratch/73dcd6a65726/verification/native-import-posix -c release --jobs 2
swiftc -frontend -parse App/BoundedFileReader.swift App/ProjectDocumentIO.swift NativeTests/BoundedFileReaderTests.swift NativeTests/ProjectDocumentIOTests.swift
python3 scripts/native_test_shards.py check
python3 scripts/agent_cycle.py check
```

Raw logs preserve the host's original timestamp, which differs from the connector clock:

- `native-import-posix-debug.log`: `fbbba271cf8f10b4f27c6c7f9860105f7f78e75d125d350870b1d9e38489243b`.
- `native-import-posix-release.log`: `d798272104c8982ea2f81d4412ee07afbd8e05fca20abcf6b845c19be91af7c8`.

## API basis and limits

Apple's archived [lstat/fstat manual](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/lstat.2.html) documents that lstat describes the final link itself, while fstat describes the opened descriptor. Apple's [file-system programming guidance](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html) recommends descriptor operations to preserve file identity and distinguishes link-following behavior. The existing cross-thread cancellation design remains consistent with Apple's [NSFileCoordinator.cancel documentation](https://developer.apple.com/documentation/foundation/nsfilecoordinator/cancel()). These official sources were checked during this review; no quoted passage was copied into production code.

The early metadata check is a conservative rejection for a **known current path**, not a guarantee that every provider syscall or coordination attempt completes within a particular time. A pathname can change afterward, unknown metadata still coordinates, and intermediate-directory symlinks remain outside the final-component no-follow promise. Authoritative descriptor validation protects the actual read; this change does not claim to eliminate every possible coordination race or operating-system stall.

The five-second expectation bounds the native test observation and exposes a regression as a failure; it is not an application timeout or a device performance guarantee. The actual split native tests, regular-file/provider round trips, presenter cancellation and complete Apple suite must still run at the integrated revision. Syntax parsing and Linux POSIX execution do not establish Apple SDK compilation, NSFileCoordinator behavior, Files provider behavior or physical-device acceptance. No gate is promoted by this packet.

## Frozen source hashes

| File | SHA-256 |
| --- | --- |
| `App/BoundedFileReader.swift` | `f420bf7876ee9d556c69b1682300e402640046983f7cf34cabe8d0508469e36c` |
| `App/ProjectDocumentIO.swift` | `84c163b88c41cb9b3535ac4c74d0c0dae3c5ce7628c5890b70b4656ce3167f85` |
| `NativeTests/BoundedFileReaderTests.swift` | `748cacfa66e0a9ace34e7ba1bf4c8fe05a1093bac8d7d6612b319ffae1a22dc8` |
| `NativeTests/ProjectDocumentIOTests.swift` | `c97fa8adce643b32cc759e1c260e805a27aba9dcce82670e5f840e8c14fa3a39` |
