# Key & Fill prototype privacy and data-handling review

**Draft, updated 2026-11-24.** Not published, legally reviewed, or owner approved. Re-audit the final signed archive, dependencies, actual device behavior, Apple privacy report, and App Store Connect disclosures before release.

## Current implementation

- No app-owned backend, analytics, advertising, account system, tracking, or third-party package dependency in the current prototype. The local Swift package is compiled into the native app.
- Projects and their lighting values are stored in the application's Application Support directory. Archived projects remain recoverable; explicitly deleting an archived project removes that record from the current library, not prior exports, OS backups, or legacy migration copies. Platform backup behavior must be reviewed on a real device. No cloud synchronization is implemented by the app.
- The system PhotosPicker supplies user-selected images without requesting broad photo-library access in the current implementation. The system provider may retrieve iCloud-backed photos. The app reads a bounded temporary file, decodes only supported single still images, creates a reduced sRGB derivative, and removes original photo metadata. Generated structural and color-management PNG chunks remain. The derivative and tonal summary are kept only in the active reference session. Cancelling or failing a replacement preserves the previous photo and guided work; explicit Remove, closing the view or applying a rig releases those app references. The photo is hidden while the scene is inactive. Actual picker behavior, inactive snapshots, cancellation and retention still require physical-device verification; this is not a secure-memory-erasure claim.
- PDF and text exports are generated locally and contain scene data, not reference photos. The system share action is user-initiated; the chosen destination can retain the exported copy. The app cannot delete copies a recipient or another app owns.
- Editable project copies contain the project name and scene settings, including the scene's per-light UUIDs for editable light identity. They omit the project-library record ID, active/archive state, reference photos, room measurements and edit history. Project and light names remain user-entered content. The user chooses a destination through the system file exporter. Import reads only a user-selected JSON file, holds security-scoped access during coordinated bounded reads, validates the document, then creates a separate project with a fresh project ID through the existing conflict-checked store. A selected file provider may download or retain files according to its own settings. Actual provider, cancellation and device behavior remain unverified.
- Room measurement notes are a separate, user-initiated text export of the committed room dimensions, subject offsets, rig rotation, equipment names and calculated placement/footprint warnings. The preview and system share action use the same immutable text. These notes contain no reference image, source photo metadata, source URL, project-library identity or undo history. Closing the room view does not remove copies already shared to another destination.
- Photo and editable-project file reads share `BoundedFileReader`: it checks the opened descriptor with `fstat`, rejects non-regular files and a final symbolic link, bounds actual bytes, and checks cancellation. The respective 32 MiB photo and 8 MiB project limits do not rely solely on earlier pathname metadata. Project-file coordination and security scope remain in `ProjectDocumentIO`; the helper does not grant access by itself.
- No AR camera access, purchase handling, external inference or other future capability is claimed by the current privacy configuration. Update the policy, manifest and permission descriptions when those features are implemented.

## Privacy manifest and required reasons

Apple documentation checked again on 2026-11-24:

- [Required-reason API categories and approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Photos picker selection and provider retrieval](https://developer.apple.com/documentation/photokit/selecting-photos-and-videos-in-ios)

The prototype manifest declares no tracking or data collection by the app. The file metadata category documents these scoped purposes:

| Reason | Current purpose | Source |
| --- | --- | --- |
| C617.1 | Determine type and size of local sandbox project files before bounded reads. | SceneFileStore, ProjectLibraryFileStore, ProjectStore |
| 3B52.1 | Determine type and size of explicitly selected photo or editable-project provider files before bounded reads. | BoundedFileReader (Darwin.fstat), called by ReferencePhoto.read(file:) and ProjectDocumentIO; selection through PhotosPicker or fileImporter |

The existing reasons remain unchanged: Apple lists `fstat` in the file-timestamp API category even though this helper uses only file type and size. No file timestamp or filesystem metadata is uploaded or used for tracking by these paths. The source audit is not a binary API-symbol audit. The build check verifies plist structure and actual resource inclusion; it cannot prove runtime privacy, permission behavior, or compliance. Obtain device and signed archive evidence before passing the privacy gate.

## Remaining release work

Review legacy backup deletion UX and iOS backups; run physical-device local/iCloud photo and document import, cancellation/replacement, removal/relaunch, inactive snapshot, exported-content and offline/network-observation checks; inspect the signed archive and Xcode privacy report for linked required-reason APIs and confirm Release excludes debug fixture behavior; finalize owner identity, privacy contact, policy publication URL, and accurate App Store privacy labels. Reassess after AR and StoreKit integration. See the [current source-review scope and remaining device matrix](evidence/2026-11-24-autonomous/privacy-source-review.md).
