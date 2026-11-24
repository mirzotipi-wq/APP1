# Meter symbol correction

## Observed defect

The actual native log for source `ff8b683098a720b4c7abdddf212f85a79f3cfd39` records two warnings at 09:34:08 UTC on 2026-11-24:

```text
[Invalid Configuration] No symbol named 'light.metering.center.weighted' found in system symbol set
```

The invalid resource name appeared in both the primary Meter action and the Light meter & test card disclosure label in `App/StudioView.swift`. The log demonstrates a missing symbol resource; it does not establish a failed tap, missing text label or complete visual failure.

## Narrow correction

Both resource names are now `sun.max`, a standard brightness/light symbol. Apple uses this exact name in the [SwiftUI Label documentation](https://developer.apple.com/documentation/swiftui/label) and demonstrates `sun.min` / `sun.max` as brightness indicators in [What's new in SF Symbols 5, WWDC23](https://developer.apple.com/videos/play/wwdc2023/10197/). This is an established symbol available for the project's iOS 17 minimum, rather than a newly introduced symbol requiring a newer deployment target. Only the two symbol strings changed; labels, identifiers, sizing, history and actions retain their existing source.

The generic light-level image is appropriate for the existing ideal-light meter and neutral test card. It does not suggest that a photographic center-weighted metering algorithm has been implemented.

## Verification and limits

- `swiftc -frontend -parse App/StudioView.swift` passed with Swift 6.4.3 on Debian 13 x86_64.
- `git diff --check -- App/StudioView.swift` passed.
- An exact comparison with `HEAD:App/StudioView.swift` confirmed that replacing the two old symbol strings with `sun.max` accounts for the complete source diff.
- No mirror test was added for this resource-name correction. Apple SDK execution and visual confirmation remain for the next native run; Linux parsing cannot look up an SF Symbol or prove its rendered appearance.

The retrieved native log is `/workspace/scratch/73dcd6a65726/verification/ff8b683-native-tests.log`, SHA-256 `5cd4211c435000990bc7c520b2a94ad8266073a9064bcfff8ceee3ffe03ea3e3`. Corrected `StudioView.swift` SHA-256: `f2d1276c3870a1a3ce3e72ae810a21511862f6bf6474df1e0352995fe7511d83`.

No staging, commit, native visual pass or release-gate promotion was performed by this specialist follow-up.
