# PDF lighting plan and native test repair evidence

Date: 2026-11-23  
Base: 4ab9f9442c9d0e0b804ee852ef31cadcf1861766  
Implementation: 27ec422f7e5cd4f80d216b3e7931416ced2d861e  
Review: assistant self-review; no independent photographer, device or customer review.

## Portable acceptance

Linux x86_64, Swift 6.2.1. Package reconstructed from GitHub blobs; exact new source and test blob IDs below. Commands:

- `swift test --jobs 2`: 68 tests, 0 failures, 0 skips; 0.403 s XCTest execution.
- `swift test -c release --jobs 2`: 68 tests, 0 failures, 0 skips; 0.138 s XCTest execution.
- `swiftc -frontend -parse App/*.swift NativeTests/*.swift UITests/*.swift`: syntax only, not Apple SDK type checking.

Ten added fixtures cover units, equipment values, world-to-plan uniform scaling, aiming and rotated footprints, coincident markers, extreme bounds, grid spacing, pagination, invalid scenes and bounded Unicode. Crowded labels are distinct while actual equipment anchors remain unchanged. Equipment schedules include each source exactly once. No project or photo data uploaded. These tests establish portable domain behavior, not native document appearance or real-device performance.

| File | Git blob |
|---|---|
| Sources/LightingCore/LightingPlan.swift | 58ba8808b1584c64135e1d0505489337b0a91597 |
| Tests/LightingCoreTests/LightingPlanTests.swift | fff3f25df5c5c1a33bbad09331e10276175e25dc |
| App/LightingPlanPDF.swift | d1094e35bd659841b8656e4b9a13de36f314ad5c |
| App/LightingPlanExportView.swift | 90cb2bbd3b99f13999518ffd9cef6d6cce9210cd |
| NativeTests/LightingPlanPDFTests.swift | 1ee0de72b47c98e59e463ee39af52c0270b9408e |
| UITests/LightingPlanExportUITests.swift | 4d61db9205a351e0743062c262c372e5d77b9067 |

## Earlier Apple runner evidence and correction

[Job 137999059454](https://github.com/mirzotipi-wq/APP1/actions/runs/45262040915/job/137999059454), revision 001de5a5627721975206ae8ffdbdc507d44eae7a. Environment macOS 26.6.1 Intel, Xcode 26.6 (17F113), Apple Swift 6.3.3, iOS simulator SDK 26.5. Generated Xcode project; unsigned Debug simulator build reported BUILD SUCCEEDED. Mac portable suite passed 58 tests. [Unsigned simulator artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45262040915/artifacts/14860922461).

The XCTest target then failed compilation at StudioSmokeTests.swift lines 39, 83, 120, 159, 181 (undefined addAttachment). Testing canceled because build failed; exit 65; Release step skipped. [Evidence artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45262040915/artifacts/14862985221). Corrected five existing calls plus new PDF/UI attachment calls to XCTestCase.add(_:). No test removed. Rerun required.

## Current status and boundaries

[CI 45265352398](https://github.com/mirzotipi-wq/APP1/actions/runs/45265352398) queued at observation. New native PDFKit tests open generated PDF data for both paper sizes and check pages, dimensions and content; UI test opens preview and checks share action and unchanged unsaved state. These tests have been authored but not executed on Apple SDK. No native PDF attachment or visual inspection yet. Native build, persistence smoke and export gates remain unverified for current source. M01 active; all later milestones pending. No claim of App Store readiness, signed build, calibrated realism, real-device performance or independent approval.
