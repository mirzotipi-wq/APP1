# Worker 076 — project name and filtered-library review

Reviewed the candidate source represented by local `3021aa9` (parent reports published equivalent `135d3b4`). No repository files changed.

## Result

No confirmed defect found in the focused naming/search/archive identity boundary. `ProjectNameDraft` performs a bounded scalar-count check before string comparison, retains rejected-paste state across restoration callbacks, validates Save and Return through one submitted-name path, and requires a deliberate replacement for shortened legacy names. `StudioDisplayName` rejects unsafe internal controls and bounds new names to 80 characters/320 scalars/1,280 UTF-8 bytes; labels sanitize legacy data without mutating stored names.

Library row presentation is computed from the entire library before search/archive filtering. UUID-prefix collisions expand against all records. Name actions capture UUIDs, and archived deletion freezes the full presentation and checks record equality before handing off the UUID command. A changing search cannot relabel or retarget an already presented delete confirmation.

## Actual check

Compiled the actual `StudioDisplayName.swift` and exact extracted `ProjectNameDraft` with a separate portable probe on Linux Swift 6.0.3. Compile and execution exit 0; 91 assertions passed. Cases include one million combining marks, stale-name submission after rejected paste, canonically equivalent restoration, empty/whitespace/invisible names, internal controls and bidi formatting, legacy replacement rules, joined emoji and RTL text, and the exact search scalar-prefix expression. The probe is not a UIKit/native test and makes no latency benchmark claim.

`receipt.json` binds all four reviewed production/native-test sources by SHA-256. `main.swift` contains the extracted draft and reproducible probe; `compile.log` and `probe.log` preserve actual output. The executable is reproducible scratch output and should not be committed.

## Remaining native interaction

Current-candidate UIKit composition/Return behavior, an oversized paste into the system search field, and a filtered archived-delete confirmation while a live library refresh changes the record remain unexecuted by this worker. Source guards and existing native test definitions do not substitute for those runs. No acceptance or release gate was changed.
