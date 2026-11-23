# M01 transaction safety and historical visual review

## Verified portable evidence

Verified portable run 45276217297, core job 138048582160: 95/95 Debug and 95/95 Release, zero failures; all three concurrent tests passed; native syntax and state validation, portable fixture rendering, Float32 host parity and artifact upload passed. Simulator job 138048582525 in progress, macOS package step.

- [Exact source commit](https://github.com/mirzotipi-wq/APP1/commit/f46ec3b73d2f4c716009c1eb32447e0ba26bec23)
- [Core job](https://github.com/mirzotipi-wq/APP1/actions/runs/45276217297/job/138048582160)
- [Core artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45276217297/artifacts/14868515676)

## Historical visual evidence

Downloaded historical iPhone 17 Pro simulator artifact 14865356504 (b8d0ef90a690e80686fd6821981ec97da163dfa4). Read manifest and visually inspected six genuine PNGs (1206×2622): PDF preview, plan, study, camera, projects, optics. Current project title was washed out by disabled-button styling; two stacked header controls cost canvas height. Four-page native Letter PDF fixture opened with Poppler; inspected diagram and equipment-page renders, legible at rendered size; no current-source or physical-device inference. SceneKit subject remains primitive; no quality promotion.

- [Historical artifact](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/artifacts/14865356504)
- Manifest screenshot names: Lighting-plan-preview, Studio-plan, Studio-light-study, Studio-camera, Project-library, Studio-optics. 1206 x 2622 px each. Native PDF fixture is four-page US Letter; inspected pages 1 and 2.
- This is a visual self-review, not independent accessibility testing. No new rendering, privacy, export or device gate pass claimed. Actual share/open remains required.

## Current source refinement

Compact adaptive project header (44-point action targets, fallback for long titles/accessibility text size) and represent current project as readable selected status, not a disabled button. Extend the existing native library flow to assert current project status, switch identity and enabled project actions.

Acceptance: enabled actions remain available, active row is selected status with full name and no disabled open button; switching updates status; verify header and both layout paths on small phone/large text; retain existing UI suite and real attachments. Current CI is pending. No protected contract changed.
