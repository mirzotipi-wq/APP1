# W01R10 — independent neutral-card normalization check

Revision inspected: `f150f98e35dd735927075aac4d2f8b02295c6a67` (HEAD verified). Read `AGENTS.md`; source remained unchanged.

**Result:** the matched-white-balance, 1000 lx, zero-stop neutral 18% card has analytic expected sRGB `(0.42694613346378979, 0.42694613346378979, 0.42694613346378979)`.

All source references below are in `Sources/LightingCore/Colorimetry.swift`:

- Lines 65–66 normalize each valid blackbody to `Y = 1`. Lines 154–160 accumulate `totalLux = Σ lux` and `xyz = Σ(color × lux)`, therefore `incidentXYZ.y = Σ lux` algebraically; line 164 stores both.
- Lines 162–163 scale by `0.18 / 1000` before applying preview settings. At 1000 lx, the relative signal has `Y = 0.18`; the lux reference cancels the illuminance dimension.
- Lines 104–109 and 121 adapt the matching illuminant toward D65 and multiply by `2^0 = 1`. Lines 122–139 convert to RGB, tone-map, and encode sRGB. Ideal neutral tone is `0.18 / 1.18 = 0.15254237288135594`, above the transfer-function breakpoint.
- White balance and exposure occur only in the subsequent display transform; they do not enter the accumulated `totalLux` (for valid settings/scenes).

Actual independent arithmetic command (exit 0):

```sh
python3 -c 'q = 0.18 / (1 + 0.18); s = 1.055 * q ** (1 / 2.4) - 0.055; print(f"tone_linear={q:.17g}\nsrgb={s:.17g}")'
```

**Limits:** an analytic scalar and source-level dimension/normalization check only. Rounded matrix constants can produce tiny channel deviations from the ideal neutral scalar. No Swift execution, builds, UI/device validation, physical calibration, or blackbody integration sweep was performed.
