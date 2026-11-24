# Privacy source review — 2026-11-24

## Scope and conclusion

Reviewed the implementation based on main `0fce248b4e61bace88002b40f6c56fddedb19c8a` plus current working-tree changes to display names and export regressions. This is an independent source review by the wave-seven privacy specialist, not a physical-device, signed-binary, legal or owner approval.

No new source-confirmed upload path, hidden photo export or required-reason mismatch was established. Two documentation gaps were corrected: room-note sharing was absent from the draft, and the shared descriptor reader was absent from the file-metadata source table. The editable-copy description now explicitly acknowledges scene light UUIDs while distinguishing them from omitted project-library identities.

The reference UI's absolute “metadata-free copy” wording was also corrected, with root authorization, to “copy without the original photo metadata.” The sanitizer intentionally preserves generated structural/color-management PNG chunks. No manifest declaration or protected quality requirement was changed.

## Reviewed data paths

| Path | Source finding | Limits |
| --- | --- | --- |
| Photos selection | `ReferenceComparisonView` uses PhotosPicker and loads only a selected transferable; there is no broad photo-library authorization request in the app source. The selected picker value is reset. | System/provider downloads may occur; actual permission and network behavior unverified. |
| Photo derivative | `ReferencePhoto` bounds encoded input and declared pixels, applies thumbnail orientation, redraws sRGB pixels, then filters private ancillary chunks through `ReferencePNG`. Derived dimensions and tonal statistics are retained with the session. | Color/structural PNG chunks remain; do not claim zero metadata of every kind. Native orientation/alpha tests require Apple execution. |
| Photo lifecycle | Replacement cancellation or failure retains the previous reference and guided work. Remove, close and apply call `clear`; request identity/cancellation rejects stale completion. Inactive view hides the photo. | Releasing app references is not proof of secure zeroing, OS-cache deletion or successful app-switcher masking. |
| Editable copy | `LightingProjectDocument` encodes only version/name/scene. `LightingScene` includes per-light UUIDs, names and editable lighting/camera/preview values. The project-library ID and state, reference photo, room session and history are absent. | User-entered names may themselves contain personal content; a saved destination can retain copies. Imported light UUIDs are intentionally preserved; a fresh project ID is created. |
| Editable import | `ProjectDocumentIO` holds security-scoped access around NSFileCoordinator, reads the coordinator-supplied URL, bounds/validates data and returns a value. `ProjectLibraryView` uses request identity and the existing optimistic store transaction before adoption. | Actual iCloud/third-party provider materialization and cancellation remain unverified. |
| Shared file reader | `BoundedFileReader` opens with no-follow/nonblocking/close-on-exec flags, checks the actual descriptor type/size using fstat, bounds actual bytes and checks cancellation. | Final symlink rejection is not a claim against every intermediate-directory symlink or in-place concurrent write. |
| PDF and lighting text | Inputs are scene/plan values; reference image bytes and source URL are not passed. PDF sets generic application title/creator and renders equipment text/vector geometry. | Selected export destinations own their copies; native PDF metadata/content validation remains part of release review. |
| Room notes | The notes export the committed room and calculated equipment positions/footprints as the exact immutable text shown in its preview. No internal UUID, source URL, photo, project-library identity or history is emitted. | The room and equipment content is intentionally shared after the user's action. |
| Debug fixtures | ProjectStore fixture flags and conflicting-write simulation are within `#if DEBUG`; fixtures require `-ui-testing` and a validated UUID namespace. Normal project storage is separate. | Source guards are verified; inspect the actual Release archive for configuration and fixture exclusion. |

`Package.swift` declares no external package dependencies, and project.yml links the local LightingCore package. Targeted app/core searches found no URLSession, URLRequest, NWConnection, WKWebView, openURL, analytics or external endpoint implementation. That source inspection does not prove absence of every system-framework network action or linked-binary behavior.

## Manifest review

`Resources/PrivacyInfo.xcprivacy` still declares no app tracking, no tracking domains and no collected data types, with the file-timestamp category reasons C617.1 and 3B52.1. `project.yml` explicitly includes the resource in the app target; the workflow checks source and both unsigned build bundles.

Apple's approved reasons cover container file metadata and user-granted file metadata respectively. Apple includes fstat in the relevant API category, even when source code uses only type and size. The new wrapper does not create a third-party SDK or justify the SDK-only wrapper reason. Current source usage remains within the already declared purposes; no reason-code change was warranted.

Official references checked on 2026-11-24:

- [API categories and approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
- [Required-reason declaration responsibilities](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
- [Photos picker selection, out-of-process access and provider retrieval](https://developer.apple.com/documentation/photokit/selecting-photos-and-videos-in-ios).

## Actual verification

- `python3 scripts/verify_privacy_manifest.py` passed its source-structure/resource expectation check.
- Targeted source inspection covered the data paths above, not a signed-binary symbol audit.
- Native Swift syntax parsing of the wording-only UI edit and `git diff --check` passed.
- No Photos/Files picker, network observation, share destination, physical device or signed archive was exercised by this reviewer.

## Required device and archive evidence

| Scenario | Required observation |
| --- | --- |
| Local and iCloud photo selection | Only selected content is delivered; provider retrieval and offline failure are represented accurately. |
| Replace, cancel, remove, dismiss, relaunch | Prior photo survives cancelled/failed replacement; explicit removal/close removes app-visible derivative and no reference reappears from saved projects. |
| Inactive/app-switcher behavior | The reference photo is actually hidden at the relevant lifecycle transitions and snapshots. |
| Local/iCloud/third-party project import | Scope and coordination complete or cancel; no stale result is adopted; failed import leaves saved bytes and current edits intact. |
| PDF, text, editable copy and room notes | Chosen output contains precisely the documented user content and intended generic format metadata; no original photo/location metadata or library state leaks. |
| Backups, deletion and selected destinations | Device backup behavior and retained legacy/export copies match the user-facing description. |
| Release archive | Inspect linked required-reason APIs, packaged manifest/privacy report and exclusion of debug fixture behavior. |

Privacy, security and release gates remain unverified until their required native/device/archive evidence and owner review exist.
