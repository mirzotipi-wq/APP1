# Historical beta failure originals — worker A084

Source 2fc7647314d3ae6fa22d95284e778c6c5badbe4a, run 46019722045, job 140578197755. This packet is historical failure evidence, not current candidate acceptance.

## Provenance and direct inspection

Downloaded original compact artifact 15214266531 with the connected GitHub artifact API. The 621,894-byte ZIP independently matches SHA-256 169a3693a9845eb6b85b2b6f9380565b11420eb5e5d56a5ce4a6d2c0a7e67d3a before bounded extraction. Every extracted file is hashed in artifact-verification.json. Paths, sizes and symlinks were checked. Both exported PNGs were directly viewed with the image tool; no image was regenerated, cropped or altered. The original ZIP and all 29 extracted files remain. The compact archive has two failure-observation PNGs and zero of eight required supplemental beta screenshots. Manifest references to omitted videos/raw UI snapshots do not mean those files were downloaded.

## Feedback observer defect

57741EAE-C32F-442C-BC91-4D677FDB9670.png visibly shows the Beta feedback button at the bottom of the Settings form. Original hierarchy B59CD28D-4BB8-4378-A7EF-2CF2812F0BCC.txt records its full frame (16,768,370,52) and Settings CollectionView (0,62,402,812), with navigation bar ending at 132. The scroll bar is at 100%.

The existing non-full reveal path uses a 100-point inset from the application frame. On the recorded 402 × 874 frame, that ends at 774 and rejects this button's center 794, even at the form's scroll end. The original log retains repeated bottom-directed drags and the failure. The current adaptive full-row change intentionally left this non-full branch unchanged.

Compiled the actual, unchanged StudioViewportGeometry.swift with a portable fixture reconstructed from all 257 original hierarchy nodes. Its actual Settings viewport is (0,132,402,742), fully containing the button. Passing the covered studio's undo as either hittable or absent gives the same correct sheet viewport. This supports the narrow feedback route using the existing full-visibility path, retaining hittability and real interaction assertions. It does not establish a native interaction pass.

## Welcome title observation

93FF3851-EC46-44B2-B3BA-8ECCE05C0CF0.png visibly shows the full three-line welcome title. Original hierarchy BCD4C175-2657-4B13-8FD9-FC3FB508BEAC.txt lines 34 and 35 show two StaticText nodes with studioWelcomeTitle: one empty-label wrapper and one exact label Start your first portrait. Both carry truncated diagnostic values.

The original log finds the title, captures the application, then fails before any drag or geometry attachment. Combined with the historical helper's control flow, this strongly supports target.snapshot throwing, the try? suppressing its error, and a nil observation target causing the early break. The exact thrown error was not retained; duplicate-query ambiguity is a supported inference, not a directly logged exception.

The actual pure geometry replay over 163 original nodes fully contains both frames within (0,116,402,597.3). A narrow identifier-plus-exact-label query with a uniqueness assertion selects the real intended title while preserving the existing layout probe, font, pixel-height and full-containment checks. The current lineSpacing change does not remove duplicate identifiers. Actual intrinsic Text height and native query behavior still need fresh execution.

## Limits

No repository source/test/gate edits, Apple builds, native test runs, CI retries or current-source acceptance claims. Linux replay uses rounded hierarchy frames and reconstructs the root application frame from Main Window plus the 3× screenshot. It cannot establish live hittability, native query error identity, absence of clipping, or current candidate results. The geometry-probe executable is reproducible scratch output and should not be committed; main.swift, JSON nodes and geometry-probe.log are the reproducible witness.
