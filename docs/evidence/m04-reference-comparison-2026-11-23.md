# M04 independent reference comparison cycle — 2026-11-23

## Scope and acceptance

M01 remains active. Work on reference import/inspection is independent of the pending native persistence gate. Acceptance: bounded file transfer; no source identifiers/metadata retained by the app; correct orientation and SDR derivative; empty/error/cancel/remove states; real Study preview; two camera-relative, explicitly assumed rigs; unknown direction abstains; scene edits through existing undo and save boundary. No new paid service, permission broadening or network backend.

## Source and observations

| Source | Work | Actual CI evidence |
|---|---|---|
| 60caa0dba5dece3bddbf38c6a4330593d160c713 | Native private reference comparison | [78 Debug / 78 Release, pass](https://github.com/mirzotipi-wq/APP1/actions/runs/45268985440/job/138023414860); [unsigned simulator app](https://github.com/mirzotipi-wq/APP1/actions/runs/45268985440/artifacts/14863024540); UI pending |
| e7332c873d94d56b9fb33e6b5f053668569922cb | Guided two-rig generator | [84 Debug / 84 Release, pass](https://github.com/mirzotipi-wq/APP1/actions/runs/45269217130/job/138024225540); six added domain tests; unsigned Debug app build passed; UI tests in progress |
| 3628de66bbd2e03e890194c44c55120f572b7ede | Tone distribution, privacy/UI follow-up | [Core](https://github.com/mirzotipi-wq/APP1/actions/runs/45269453791/job/138025049210): 89 Debug / 89 Release, zero failures; [core artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45269453791/artifacts/14864311985); [simulator](https://github.com/mirzotipi-wq/APP1/actions/runs/45269453791/job/138025048902): queued |

Guided test verifies 3 directions × 3 softness options × 4 fill options × 3 rim options = 108 combinations and 216 valid candidate scenes, preservation of camera/subject/lens/preview settings, scene codec round trip, direction relative to a rotated camera, soft-source width/distance consistency and assumed 400 lx / 4:1 key-fill plane ratio. It also verifies unknown-direction and unsupported geometry abstention. This is not an evaluation of image reconstruction accuracy.

The image summary uses at most 16,384 opaque samples, linear Rec.709 luminance on sRGB input, percentiles expressed as neutral SDR gray, and deep shadow/highlight fractions. Partial alpha is excluded. No sensor clipping, lighting position, color temperature, exposure, skin or reflectance is inferred. The preview uses a neutral sphere/plane and is uncalibrated. Native tests cover orientation/metadata and bounded input, file representation and original bytes; the system Photos picker, removal/cancellation, background snapshot behavior, SDK test execution, genuine screenshots and device privacy are outstanding.

## Documentation consulted

- [Apple Photos picker](https://developer.apple.com/documentation/photokit/bringing-photos-picker-to-your-swiftui-app)
- [Core Transferable imported FileRepresentation](https://developer.apple.com/documentation/coretransferable/filerepresentation/init(importedcontenttype:shouldattempttoopeninplace:importing:))
- [Image I/O thumbnail creation](https://developer.apple.com/documentation/imageio/cgimagesourcecreatethumbnailatindex(_:_:_:))

## Gate decision

M01 core last fully verified revision 3628de66bbd2e03e890194c44c55120f572b7ede, 89 tests per configuration, zero failures. Latest native build and persistence smoke unverified; prior successful unsigned build is not a physical device or test pass. M04 inference/reference privacy gates unverified. Evidence-only scorecard stays at 20/100; no release readiness claim or independent reviewer. Actual release gate evidence, not implementation volume, controls progress.
