# W04R08 — nil versus black neutral card

**Result:** No nil/black conflation found in one static source trace. Fresh execution evidence; not recovered original logs.

**Provenance:** HEAD `47de6afe6afe24a7822f4276950f70bd3db9f57d`; inspected code matches production snapshot `58b3ca43943e18d0fc7800189b08365f424d9c9e` and frozen module source `1b286885cb803ba17e159713651515ab119e17f1` (both scoped `git diff --exit-code` commands returned 0). No module was executed.

**Trace:** `StudioView.swift:903` embeds the inspector. `NeutralCardInspector.swift:108,117` computes and stores the optional card. `Colorimetry.swift:172–173` propagates an active light's unsupported illuminance to nil, through `StudioOptics.swift:131–136` into `SurfacePhotometry.swift:114–119`. Plane separation `abs(depth) < max(0.05 m, longest side / 4)` rejects before the dark-side branch. Consequently even a back-side receiver within that guard is unsupported. The inspector's nil branch (`:33–42`) displays “Meter unavailable” plus fixed explanatory text, without a black swatch or zero estimate.

Valid emitter-back-side darkness (`SurfacePhotometry.swift:119`) and wholly nonpositive receiver incidence (`:148`) return zero. When all active contributions are zero, `Colorimetry.swift:167–178` retains a valid sample and `:139` returns RGB zero. The inspector displays lux and RGB values (`:122–141`); its decorative swatch is accessibility-hidden, while illuminance has an explicit label/value and RGB has a spoken label. `StudioMeterReadout.swift:9–10,25–27` preserves exact zero with lx units. Zero-candela lights are intentionally skipped (`Colorimetry.swift:171`).

**Limits:** Fixed unsupported text contains no scene/user names, but gives no plane-specific recovery distance. This is source evidence only: no UI, VoiceOver, layout, device, privacy-network, numerical-accuracy, or calibration audit. Point 1% and area 5% gates remain unchanged. Exact successful commands, source excerpts, and hashes accompany this report.
