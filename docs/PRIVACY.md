# Key & Fill prototype privacy and data-handling review

**Draft, 2026-11-23.** Not published, legal reviewed, or owner approved. Re-audit the final signed archive, dependencies, actual device behavior, Apple privacy report, and App Store Connect disclosures before release.

## Current implementation

- No app-owned backend, analytics, advertising, account system, tracking, or third-party package dependency in the current prototype. The local Swift package is compiled into the native app.
- Projects and their lighting values are stored in the application's Application Support directory. Archived projects remain recoverable; explicitly deleting an archived project removes that record from the current library, not prior exports, OS backups, or legacy migration copies. Platform backup behavior must be reviewed on a real device. No cloud synchronization is implemented by the app.
- The system PhotosPicker grants access to user-selected images. The system provider may retrieve iCloud-backed photos. The app reads a bounded temporary file, decodes only supported single still images, creates a reduced sRGB derivative, removes private ancillary PNG metadata, and retains it only in the active reference session. Actual PhotosPicker success, cancellation and retention must still be verified on physical devices.
- PDF and text exports are generated locally and contain scene data, not reference photos. The system share action is user-initiated; the chosen destination can retain the exported copy. The app cannot delete copies a recipient or another app owns.
- No AR camera access, purchase handling, external inference or other future capability is claimed by the current privacy configuration. Update the policy, manifest and permission descriptions when those features are implemented.

## Privacy manifest and required reasons

Apple documentation reviewed on 2026-11-23:
- https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons

The prototype manifest declares no tracking or data collection by the app. The file metadata category documents these scoped purposes:

| Reason | Current purpose | Source |
| --- | --- | --- |
| C617.1 | Determine type and size of local sandbox project files before bounded reads. | SceneFileStore, ProjectLibraryFileStore, ProjectStore |
| 3B52.1 | Determine type and size of the explicitly selected photo provider file before bounded reads. | ReferencePhoto.read(file:), ReferenceComparisonView PhotosPicker |

No timestamp or derived file metadata is uploaded or used for tracking by these paths. The source audit is not a binary API-symbol audit. The build check verifies plist structure and actual resource inclusion; it cannot prove runtime privacy, permission behavior, or compliance. Obtain device and signed archive evidence before passing the privacy gate.

## Remaining release work

Review legacy backup deletion UX and iOS backups; run a physical-device import/cancel/remove/relaunch and offline/network-observation matrix; inspect the signed archive and Xcode privacy report for linked required-reason APIs; finalize owner identity, privacy contact, policy publication URL, and accurate App Store privacy labels. Reassess after AR and StoreKit integration.
