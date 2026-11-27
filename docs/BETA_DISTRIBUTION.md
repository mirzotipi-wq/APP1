# Beta archive preparation

`scripts/prepare_beta_archive.py` validates explicit owner inputs and prints a
concrete **unsigned iPhoneOS archive plan**. It is preparation tooling only: no
commands execute and no files are written, on Linux or macOS. There is no
`--execute` option. A successful plan means its local inputs passed validation;
it does not mean an archive was built, signed, uploaded, tested, or approved.

The source configuration in [`project.yml`](../project.yml) currently uses
`com.example.keyandfill`, marketing version `0.1.0`, build `2`, no development
team, and a blank StoreKit product identifier. These are development defaults,
not owner-approved distribution values. The preparation script leaves that file,
the app's project library, product configuration, and feature access unchanged.

## Required owner values

| CLI option | Required value and local validation |
|---|---|
| `--bundle-id` | Owner's reverse-DNS app identifier, 2 or more components, at most 255 ASCII characters; component letters/digits/hyphens, no leading/trailing hyphens. `com.example`, `org.example`, `net.example`, and descendants are rejected case-insensitively. |
| `--team-id` | Owner's Apple development team ID: exactly 10 uppercase ASCII letters or digits. |
| `--version` | Three decimal components, each 0–9999, without leading zeroes; for example `0.1.0`. |
| `--build-number` | A new owner-selected build integer from 1 to 9999, without leading zeroes. |
| `--output` | Absolute path to a **new artifact directory outside the checkout**, with an existing directory as its parent. |

Version/build bounds are deliberately conservative tool policy. The script
checks syntax only; it cannot verify ownership, team membership, registration,
or whether App Store Connect has already used a build number. Apple associates
uploaded builds with the bundle ID and version and uses the build string to
identify a build; the owner must reconcile those values with the actual app
record before distribution ([Apple: Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)).

No identifier, credential, signing identity, provisioning profile, or account is
discovered from the environment or selected automatically. Enter the actual
owner values yourself; the script does not accept credentials. All scalar
inputs are bounded. Whitespace and Xcode expressions are rejected in
identifiers/version/build. Paths permit ASCII letters, digits, spaces,
apostrophes, `/`, `_`, `-`, and `.`, up to 1024 characters; control characters,
`..`, command separators, command substitution and build-setting expansion
syntax are rejected. Accepted spaces/apostrophes are quoted in the text view.
Existing files, directories and dangling symlinks at the output path are refused.
An existing `KeyAndFill.xcodeproj` beside `project.yml` is also refused. Prepare
from a clean checkout without a generated project; existing development projects
must not be overwritten by an archive plan.

## Generate and review a plan

Run this from the checkout after setting the shell variables to actual
owner-provided values. `BETA_OUTPUT` must be a fresh absolute artifact directory,
for example a new directory under an existing local build folder.

```sh
python3 scripts/prepare_beta_archive.py \
  --bundle-id "$BETA_BUNDLE_ID" \
  --team-id "$BETA_TEAM_ID" \
  --version "$BETA_VERSION" \
  --build-number "$BETA_BUILD_NUMBER" \
  --output "$BETA_OUTPUT" \
  --dry-run
```

Omitting `--dry-run` produces the same preparation-only behavior. Append `--json`
for a structured plan containing the validated inputs, command argument arrays,
output paths, host restriction, and SHA-256 hashes of `project.yml` and
`Package.swift`. Those two hashes identify the project specifications, **not the
complete app source**; retain the source revision and any working changes
separately when collecting build evidence.

The plan contains three commands, in order:

1. `mkdir` creates the new artifact directory and fails if it exists.
2. `xcodegen generate` reads the existing spec and writes a fresh
   `KeyAndFill.xcodeproj` beside `project.yml` in the source checkout. Both
   `--project` and `--project-root` explicitly select the source root.
3. `xcodebuild ... archive` requests the `KeyAndFill` scheme in `Release` for
   generic iOS/arm64, with explicit bundle, team, version and build overrides.
   `CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=NO` and an empty signing
   identity keep this an unsigned archive plan. Automatic package resolution
   and package updates are disabled; the current package dependency is local.

`KeyAndFill.xcarchive`, `DerivedData`, and `Archive.xcresult` are planned within
the fresh output directory. Command data is represented as argv arrays, never
passed to a shell by this script. The
default text view uses shell quoting for review. A future authorized runner
must use `subprocess.run(argv, shell=False, check=True)` rather than evaluating
the displayed text.

### Local package path constraint

Keep the generated project beside the source spec. The repository's
`LightingCore` dependency uses `path: .`. XcodeGen's
[`PBXProjGenerator`](https://github.com/yonaskolb/XcodeGen/blob/master/Sources/XcodeGenKit/PBXProjGenerator.swift)
passes that path directly into `XCLocalSwiftPackageReference`; its
[`SourceGenerator`](https://github.com/yonaskolb/XcodeGen/blob/master/Sources/XcodeGenKit/SourceGenerator.swift)
separately rebases navigator references when the project output is relocated.
An external `--project` directory therefore cannot be assumed to preserve local
package resolution just because app source references look correct. This plan
keeps the spec, generated project and package root together, matching the
repository's normal generation layout. `--project-root` selects the spec's base
path, as defined by the upstream
[`ProjectCommand`](https://github.com/yonaskolb/XcodeGen/blob/master/Sources/XcodeGenCLI/Commands/ProjectCommand.swift)
and [`SpecFile`](https://github.com/yonaskolb/XcodeGen/blob/master/Sources/ProjectSpec/SpecFile.swift).

Manual execution requires a Mac with a selected Xcode/iPhoneOS SDK and XcodeGen.
Verify tool versions and source revision, regenerate the plan on that Mac,
recheck that both the output directory and generated project are absent, and
stop immediately if any command fails. The dry run does not reserve either
path, validate the Xcode installation,
or prevent a later process from occupying the path. Retain failed output and
choose a new directory for a retry. Do not remove a prior archive to make this
check pass; use a new clean checkout when a previous generated project is present.
The preparation tool has not itself executed or validated these archive
commands on an Apple host.

## What unsigned evidence establishes

| Evidence | Scope |
|---|---|
| Portable tests | Domain/tooling behavior on the recorded host and revision. |
| Native simulator tests and unsigned simulator build | Execution/build evidence for the selected simulator suites, configurations and source. |
| Unsigned iPhoneOS build or archive | Device-target compilation/linking and, if actually inspected, the resulting bundle/archive contents. It does not establish device installation, signing, TestFlight processing or distribution. |
| Signed TestFlight build | A separate owner-authorized signing/upload process, an actual accepted App Store Connect build, and recorded tester availability. No such outcome is supplied by this preparation script. |

To move from this preparation to TestFlight, the owner must supply and confirm
the registered bundle ID and app record, correct development team, version and
unused build number, valid signing/provisioning setup, and the intended testing
audience. The owner must approve signing and distribution under
[`QUALITY.md`](QUALITY.md). Review the required product/privacy/test evidence
and current Apple requirements before any distribution action; complete the
app's beta information and any required review/compliance steps using the
owner's authorized account. Apple's [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
and [upload documentation](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
describe that separate service workflow.

This script provides no provisioning-update flag, export command, upload,
TestFlight invitation, credential access, or StoreKit product setup. The blank
product identifier and existing free feature access remain intact. A future
commerce decision must follow the existing product/quality contracts; archive
preparation does not authorize a price or entitlement change.

## Retained unsigned device application

The `iOS Prototype` workflow is configured to retain the existing arm64 Release
device application after its compile/link, platform, architecture, icon and
privacy-manifest checks succeed. The separate artifact is named
`KeyAndFill-device-release-unsigned` and has a 14-day retention period. Its
creation is conditional on those checks; a pending or failed workflow is not
evidence that this artifact exists.

The artifact contains the zipped `KeyAndFill.app`, a `manifest.json` with the
source commit/tree, toolchain versions, bundle identity, file count, byte size
and ZIP SHA-256, and a short scope note. Packaging verifies ZIP integrity and
that the included Info.plist belongs to the checked application. It reuses the
existing build and does not perform another compilation. Failure logs remain
available separately as `arm64-device-release-build-evidence`.

This is an unsigned application for developer inspection. It is not an
installable beta or an `.xcarchive`; use the archive preparation procedure above
for owner-configured build preparation. Signing, physical-device validation and
distribution approval remain separate. Download availability must be checked
on the actual source-specific Actions run.

## Identifying a running build

CI supplies the checked-out Git commit through `KEYFILL_SOURCE_REVISION` to the
app and UI-test bundles. Settings shows the complete recorded revision, and a
reviewed beta feedback report includes it with an explicit contents notice.
Custom keys come from explicit app and UI-test plist templates merged with
Xcode-generated standard metadata. CI checks the actual built app and independent
test bundle before simulator startup; source settings alone do not prove the
fields were embedded.

Only a complete 40-character hexadecimal revision is accepted; a local build
without this value shows `Unavailable` and omits it from feedback. No revision
is guessed from the marketing version or build number.

The device bundle check verifies that its embedded revision matches the checked
out commit before packaging. The ZIP manifest includes both values. This ties
the generated artifact to its source identifier; it does not establish physical
device behavior or replace the manifest's tracked-source cleanliness record.

## Tooling verification

```sh
python3 -m unittest discover -s scripts/tests -p 'test_beta_archive.py' -v
```

The focused tests exercise required inputs, placeholder and malformed values,
command/build-setting injection, output collisions including dangling symlinks,
source-path protection, bounded spec reads, shell quoting, and the absence of
process execution or file writes on both simulated Linux and macOS hosts. These
tests do not substitute for running or inspecting an actual Xcode archive.
