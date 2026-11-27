# Actual built-bundle metadata failure and repair

## Observed failure

Published source `c19d5f8f9cae6bb88660e86954212cfb201cd84e` compiled its
Debug simulator application and uploaded artifact `15230427948`. Root downloaded
the original ZIP, verified its GitHub SHA-256 and inspected the actual nested
`KeyAndFill.app/Info.plist`. **Both custom metadata keys were absent**, including
`KEYFILL_SOURCE_REVISION`. The [inspection receipt](checkpoint-02-debug-app.json)
and [original binary plist](checkpoint-02-debug-app-info.plist) retain that
evidence. Worker 065 independently reproduced the omission from the same ZIP.

Standard bundle identity, version/build, camera permission, iOS 17 minimum and
simulator SDK/Xcode metadata were present. This is a custom-field configuration
failure, not a compile failure. Settings would correctly show Unavailable; it
could not identify this source build. The existing device-package guard requires
a matching embedded revision, so no device-package success is claimed.

## Cause and change

Apple's [information property-list guidance](https://developer.apple.com/documentation/bundleresources/managing-your-app-s-information-property-list.md)
explains that arbitrary user-defined `INFOPLIST_KEY_` settings do not create
custom keys. An explicit input plist can supply them while generated standard
values are merged by `GENERATE_INFOPLIST_FILE=YES`.

Repair source: `e5c63c1020d3c3ef193c1de5109d5d73e4566939`. `Resources/AppInfo.plist` supplies
the two existing custom variables; `Resources/UITestInfo.plist` supplies the
independent test bundle's revision. Each target names its template through
`INFOPLIST_FILE` and explicitly enables build-setting substitution. The files
are not target resource-copy inputs. Ordinary generated metadata and the blank
product configuration remain. No signing or entitlement activation is added.

Debug and Release simulator build steps now inspect the built app's actual
revision before uploading it or warming a simulator. UI build steps inspect the
app and every built UI-test bundle copy independently. Missing or disagreeing
metadata fails early with retained logs. The existing device identity check
remains required. Tests, fixtures, thresholds and runtime timeouts are unchanged.

## Validation and remaining evidence

Both templates parse with plistlib; project YAML, changed shell bodies and all
twelve embedded workflow Python bodies parse. Privacy/icon/source-partition and
whitespace checks pass. The [nine guard witnesses](metadata-guard-witnesses.json)
execute the exact workflow checks against the actual faulty plist, mismatching
revisions, absent test-bundle metadata and explicit valid synthetic fixtures.
The actual faulty plist is rejected. Synthetic guard acceptance is not an Xcode
build or propagation result. Worker 065 independently approved the explicit-template and actual-bundle
guard repair. Follow-up `933433d` adds only stderr redirection to the three
metadata logs; every workflow shell still parses. Fresh Apple build/artifact
inspection remains required after publication.

All application, portable package, Swift tests and existing tooling inputs are
byte-identical to `c19d5f8`; only build configuration, two metadata inputs and CI
bundle guards change. The 604 Debug/604 Release/120 tooling and original CPU
rendering/persistence results remain source-bound at c19. They do not prove the
new native configuration.
