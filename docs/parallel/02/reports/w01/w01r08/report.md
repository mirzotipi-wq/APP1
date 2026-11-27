# W01R08 — target-lux accessibility/privacy

Revision: `f150f98e35dd735927075aac4d2f8b02295c6a67` (assigned baseline). Source unchanged.

## Findings and boundary

- **Units are represented in source semantics.** `App/LightTargetLuxView.swift:35–38` passes the text-field accessibility label “Desired illuminance in lux” and a zero/off hint. Current illuminance and required intensity use native `LabeledContent` with `lx` and `cd` values (`31–32`, `44–46`). The result has no explicit “candela” pronunciation override. Wrapper forwarding and actual spoken output were not tested.
- **Unsupported state is exposed after Apply, not during preview.** Preview uses `try?` and omits the result on failure (`44–47`). Apply catches the error into state (`108–119`), rendered as a textual `Label` with identifier `targetLuxError` (`55–59`). Core strings identify unsupported geometry and the supported candela range (`Sources/LightingCore/LightOutputAdjustment.swift:15–18`); invalid-target text explicitly says lux (`11–12`). No explicit announcement/focus transfer is present. This establishes available error text, not verified VoiceOver announcement behavior. No confirmed accessibility defect follows from this static check; silent preview failure is a concrete discoverability limitation.
- **Inspected operations are local.** The view parses local draft state, invokes calculation, and hands a resulting light to `onApply` (`17–21`, `108–119`). The inspected core excerpt validates inputs and copies/adjusts the source (`32–54`). No transfer operation appears in reviewed statements. The remainder of core logic, called helpers, and callback internals were outside this check; this is not an app-wide privacy conclusion.

## Evidence

Actual commands, workdir `/tmp/keyfill02-workers/w01r08`:

```sh
rg --files -g AGENTS.md -g '!private-output/**'
cat AGENTS.md
git show HEAD:App/LightTargetLuxView.swift | nl -ba
rg -n -A 45 'var errorDescription' Sources/LightingCore/LightOutputAdjustment.swift
```

All exited 0. No builds, execution tests, UI checks, or network operations.

Artifact: `/tmp/keyfill02-workers/w01r08/private-output/report.md`.
