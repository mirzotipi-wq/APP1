# W04R06 — rectangle resource bound

**Result:** Numeric-kernel work and source-level storage are bounded; no defect found in this scoped audit.

**Revision:** HEAD `47de6afe6afe24a7822f4276950f70bd3db9f57d`. `SurfacePhotometry.swift` blob `d100c4d9e99a8f2ff802d7dd4ce9aa6683cadb5c` is identical at production `58b3ca43943e18d0fc7800189b08365f424d9c9e` and helper-module snapshot `1b286885cb803ba17e159713651515ab119e17f1`. No module execution or package build.

**Proof:** Lines 119–132 return zero before scaling or recurse with intensity exactly 1. The threshold is `2^-1012`, so the inner call cannot recurse: at most one recursive edge/two rectangular-call frames. Scaling occurs before geometry arrays are created, so integration and geometric storage are not doubled.

Four affine corner incidences are monotone along the same x direction in both rows, including rounded ties. Strict checkerboard signs are impossible. Partial clipping retains at most three original vertices and introduces at most two crossings: five vertices, three fan triangles, and `3 × 12 × 12 = 432` quadrature evaluations. The mutually exclusive full-face path evaluates `32 × 32 = 1,024` cells. Early returns and degenerate triangles reduce work.

Storage is constant: four corners, four incidence vertices, at most five polygon vertices with `reserveCapacity(5)`, twelve shared Gaussian pairs, and three-element `Position.isValid` arrays. No per-sample array or growth with intensity. These are source-level element bounds, not measured heap-allocation counts/bytes.

`StudioPhotometry.illuminance/frame` also call `StudioLight.isValid`, whose name trimming/counting has input-dependent cost. That wrapper is explicitly outside this numeric-kernel bound; lane01 already owns the concern.

**Evidence:** `python3 private-output/audit.py` passed source assertions and all 36 admissible partial sign patterns; `raw.txt` retains results, hashes and numbered excerpts. No production edits or accuracy/device/calibration claims; 1% point/5% area gates unchanged.
