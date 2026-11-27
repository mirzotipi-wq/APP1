# CIE source and derived comparison table

Source credit: **CIE 2019, Colour-matching functions of CIE 1931 standard colorimetric observer, International Commission on Illumination (CIE), Vienna, AT.**

- DOI: [10.25039/CIE.DS.xvudnb9b](https://doi.org/10.25039/CIE.DS.xvudnb9b)
- [Official dataset page](https://cie.co.at/datatable/cie-1931-colour-matching-functions-2-degree-observer)
- [Official CSV](https://files.cie.co.at/Publications-datasets/CIE_xyz_1931_2deg.csv)
- [Official metadata and license declaration](https://files.cie.co.at/Publications-datasets/CIE_xyz_1931_2deg.csv_metadata.json)
- Source and derived `table.csv` / `table.json` data license: [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/).

Changes: the tabulated 1 nm colour-matching functions were integrated against eight ideal Planck spectra to produce chromaticity coordinates. Actual Swift outputs and diagnostic differences were added. This is a derived calculation, not an official CIE blackbody table or a claim of CIE endorsement. The original 471-row CSV is not included.

Retrieved 2026-11-26; 24,021 bytes, 471 rows spanning 360–830 nm.

```
MD5     17cca777db64b17170f06f67ce9d3ab7
SHA-256 fa663e3535a7e0763a745993a1f0a192eb0275ac46ad2d1befd7626841e713c1
```

Diagnostic analytic observer coefficients come from the production implementation documented as Wyman, Sloan, and Shirley, JCGT 2013, Equation 4, in `Sources/LightingCore/Colorimetry.swift`. They are kept separate from the independent CIE tabulation reference.
