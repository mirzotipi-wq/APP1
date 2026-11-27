# actualworker050 — original AXXXL inspection

Source `2fc7647314d3ae6fa22d95284e778c6c5badbe4a`, run 46019722045, job 140578197692, compact artifact 15211285565. SHA-256 independently matches `b9406c40d3a16b104e442f7f787139fb99c1ff1bedfa4b4ddb8acce0c3fc02d4`; all 24 extracted files byte-match that ZIP.

**Finding:** fixed-drag overshoot fits the observed reachability failure, but the originals also expose poor AXXXL light-row layout. Neither observation establishes permanent unreachability or acceptance.

The Fill row is approximately 540.333 pt high inside a 597.333 pt viewport beginning at y=116. Full containment requires top y=116…173. Twelve pre-drag observations repeatedly alternate outside that 57 pt interval: 496.333→−12.333→494.667→−8→488.667→33→551→88.667. Pinned `StudioContentReachability.swift` uses the same 48%-viewport gesture after every unsuccessful observation. No distance-dependent correction occurs.

**Capture timing matters:** y=88.667 is the last pre-drag measurement, not the final screenshot position. The twelfth reverse drag runs before failure capture. Both original hierarchies place Fill at y=518, height=540.3, matching the original unreachable/failure PNGs: Fill begins near the lower viewport and continues behind the fixed footer. Those screenshots do not contradict the geometry or prove stale AX frames.

**Visible product defect:** the nonadaptive rack HStack (`StudioView.swift`) leaves only about 82–86 pt for text. Original AXXXL images show “Bare point” and “5,600 K” split into narrow fragments, producing a nearly screen-height row. This readability issue remains even if a finer gesture reaches full containment. Viewport-edge cropping alone is not evidence of permanent text loss.

Directly viewed all three retained AXXXL captures, both failure screenshots, and Default Plan-selection, Inspector and Precision-keyboard originals. AXXXL Scene/Meter and mode labels are readable; the selected Fill caption is visible. Default controls appear legible and the keyboard image visibly contains `4321.5`.

The manifest contains 17 required images (14 Default, 3 AXXXL), two failure PNGs, four text attachments and itself. Six required images were visually reviewed here; eleven required AXXXL images were never reached. No source edits, compilation, retries, pushes or acceptance claim.
