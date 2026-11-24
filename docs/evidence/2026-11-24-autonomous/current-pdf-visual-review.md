# Actual native PDF visual review — source ff8b683

## Result and scope

On 2026-11-24, the reviewer rendered and visually inspected all eight pages of the two genuine PDF attachments exported by the native XCTest run at source `ff8b683098a720b4c7abdddf212f85a79f3cfd39`. The US Letter and A4 documents each contain an overview followed by three equipment pages. No clipped labels, missing equipment entries, overlapping equipment rows, or unreadable text were observed in this attached 12-light, imperial-unit fixture.

This is bounded visual evidence for these two documents. It does not pass the complete export gate, validate physical printing, establish accessible PDF reading order, or verify the system share sheet, a file provider, or a physical device. It does not certify later working-tree corrections. No new PDF was generated or substituted for the native attachments.

## Provenance

| Field | Exact evidence |
|---|---|
| Repository/source | `mirzotipi-wq/APP1` / `ff8b683098a720b4c7abdddf212f85a79f3cfd39` |
| Workflow | [45363578829](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829) |
| Native build/unit job | [138342789331](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/job/138342789331) |
| Artifact | [14905719667 — native-unit-and-build-evidence](https://github.com/mirzotipi-wq/APP1/actions/runs/45363578829/artifacts/14905719667) |
| Existing local ZIP | `/workspace/scratch/73dcd6a65726/verification/ff8b683-native-evidence.zip` |
| ZIP bytes / SHA-256 | `77402093` / `7fad93fa9c760d28ea88235a53b8c1122ea81b55c666e189a6fc3536f2f942b4` |
| Attachment manifest | `artifacts/native-attachments/manifest.json`, read directly from the existing ZIP |
| Attaching native test | `LightingPlanPDFTests/testNativePDFOpensAndContainsAllEquipmentInBothPaperSizes()` |
| Simulator identity in manifest | `iPhone 17 Pro`, identifier `12FCFD0F-7FCF-463F-A605-132A7E18B5D5` |
| Attachment status | Both manifest records have `isAssociatedWithFailure: false` |
| Local inspection directory | `/workspace/scratch/73dcd6a65726/verification/current-native-pdfs/` |

Only the two `.pdf` attachment entries were extracted from the existing archive. The 77 MB archive was not downloaded again. The manifest was read in memory. Rendered PNGs and text extractions are local derivatives of the original PDFs, retained in the inspection directory.

### Exact document identities

| Paper | Actual attachment entry | Bytes | Pages | Media box (points) | SHA-256 |
|---|---|---:|---:|---|---|
| US Letter | `artifacts/native-attachments/9B831D4C-AB60-4F62-9FC9-B18399B8B200.pdf` | 46,554 | 4 | 612 × 792 | `1c34e752cde0b588cf4db92c076ffbc6c0dba848318d6a40ebc296c72645386f` |
| A4 | `artifacts/native-attachments/F5AE0448-733F-402F-BCAF-64E473A3BD3A.pdf` | 46,499 | 4 | 595.28 × 841.89 | `e6fd590ed8e9567e605e4463e8d14ca6eb155dae338d0f337186df3f0bbbd54c` |

The manifest's suggested names are `Lighting-plan-letter_0_CE7367BB-49E8-4FED-A433-61C5C80AECA4.pdf` and `Lighting-plan-a4_0_E23AEF1D-3904-49B6-881C-4160581A57B7.pdf`, respectively. Export timestamps are `1795512882.286` and `1795512882.35`.

Both PDFs report version 1.3, title `Key & Fill - Lighting plan`, creator `Key & Fill`, and producer `iOS Version 26.5 (Build 23F77) Quartz PDFContext`. Both have zero page rotation, no encryption, no forms, and no JavaScript according to `pdfinfo`. Both report `Tagged: no`; visual readability must not be presented as tagged-PDF or screen-reader acceptance.

## Method

The assigned scope was an independent artifact review on `main`, with no source edits, staging, or commits. Repository instructions and the PDF skill were consulted. The acceptance test was to open the real attachments, inspect every page at a readable size, identify visible defects, and preserve exact provenance and limits.

For each PDF, the reviewer ran `pdfinfo`, `pdftotext -layout`, and Poppler `pdftoppm -r 150 -png`, then opened all four resulting page images with `view_image`. Poppler identified itself as version `26.05.0`. Letter renders are 1275 × 1650 pixels; A4 renders are 1241 × 1754 pixels. No image reskinning, mock export, or replacement rendering was used.

Supplemental PyMuPDF checks found all 12 exact equipment names once in each complete document and no extracted text span bounding boxes outside a page's media rectangle. These checks support content and page-boundary review; they do not replace visual inspection or prove the layout of untested strings.

The reviewer compared the attachments with the attaching test and exporter at the exact source revision, using `git show ff8b683098a720b4c7abdddf212f85a79f3cfd39:NativeTests/LightingPlanPDFTests.swift` and the corresponding `App/LightingPlanPDF.swift`. Source fixture values are twelve rectangular lights named `Fixture 1 unique` through `Fixture 12 unique`, x positions `index / 2` meters, y = 2 m, z = 1 m, 700 cd, 5600 K, and modifiers 1.2 × 0.6 m. Both attached plans use imperial display units and title `Portrait validation`.

## Page-by-page observations

| Page | Content in both papers | Visual result |
|---|---|---|
| 1 | Overhead diagram, subject/camera, lights 1–12, legend, scale/axis guidance, camera settings and assumptions | All 12 numbered badges are readable and remain within the diagram. Subject `S` and camera `C` are visually distinct. The dense fan of dashed aim lines and adjacent diffuser outlines remains understandable for this fixture. Legend, coordinates, assumptions and footer are visible without clipping. |
| 2 | Equipment 1–5 | All five complete rows appear. Each includes its name, modifier kind/dimensions, output, temperature, position, subject distance and aim. Rules separate rows; text stays clear of the footer. |
| 3 | Equipment 6–10 | All five complete rows appear, including two-digit light 10. No observed row collision, missing label, or clipped right-hand setting. |
| 4 | Equipment 11–12 | Both complete rows appear with correct continuation numbering. There is substantial blank space below them, consistent with the five-row page allocation. The rounding note and page 4/4 footer remain visible. This blank space is not missing equipment. |

The documents use dark body text on white, restrained amber numbering, readable section headings and consistent margins. Every page carries the plan title and document identity. Footer numbering runs 1/4 through 4/4 and identifies `Plan v1`, `Scene v4`, and the paper format. No material difference in readability was observed between these two paper sizes.

Visible values include subject `(0.00, 4.92126, 0.00) ft`, camera `(0.00, 4.92126, 9.84252) ft`, 50 mm focal length, a 36 × 24 mm sensor, 9.84 ft to the subject, 5600 K balance and 0.00 relative stops. Equipment rows visibly retain `700.0 cd`, `5600 K`, and `3.937008 ft × 1.968504 ft`, matching the source fixture's imperial conversion. Position values extend through light 12's x coordinate `19.685039 ft`; its displayed subject distance is `20.02 ft`. Aim rows show `(0.00, 4.92126, 0.00) ft` and `follows subject`.

The long coordinate values make the equipment pages information-dense, but they remain legible in the inspected images. The note explains that entered settings are rounded to six fractional digits while derived center-to-center 3D distances are rounded to two. The overview also discloses planning geometry, ideal luminous intensity in candela, relative camera/exposure behavior, and that reference images are not embedded. This fixture contains no reference image and therefore does not exercise privacy behavior with an imported photograph.

## Signed values and remaining equipment coverage

The attached documents use positive light/camera coordinates and zero exposure. They do **not** provide visual proof for negative positions, negative exposure, very long names or titles, localized number formatting, metric layouts, extreme imported values, invalid aim warnings, empty setups, or every modifier type.

The [actual native test log](ff8b683-native-tests.log) separately records all three `LightingPlanPDFTests` methods passing at this source, including `testPDFRetainsEnteredPrecisionInBothPaperSizesAndUnits`. Inspection of that test confirms negative camera/light coordinates, `-0.375 relative stops`, and fractional lens, temperature, output and modifier values are checked through native PDFKit text extraction in both papers and units. That method does not attach its PDFs. Its pass is genuine native text/content evidence, not visual inspection of those signed-value layouts. The empty-scene method similarly has no attached PDF for visual review.

No blocker was found in the supplied PDF images. The next PDF-specific visual evidence should use real attachments from the signed/precision, metric, empty and long-name fixtures. This recommendation does not invalidate the observed result for the two supplied documents or imply those unseen cases failed.

## Retained render hashes

All paths below are relative to `/workspace/scratch/73dcd6a65726/verification/current-native-pdfs/`.

| Render | SHA-256 |
|---|---|
| `9B831D4C-AB60-4F62-9FC9-B18399B8B200-1.png` | `174c45625b8a033cd22074c66d546057acdfddb5f7102e4562217cece5c68966` |
| `9B831D4C-AB60-4F62-9FC9-B18399B8B200-2.png` | `5ee99f4f7fff70ccb299550da444344def7a44ea0fbf09ea6827e31f82619bb9` |
| `9B831D4C-AB60-4F62-9FC9-B18399B8B200-3.png` | `b53f39945ad25ce0cb31e39b70e068f2b812e364fad87aacc3d7796ce6284046` |
| `9B831D4C-AB60-4F62-9FC9-B18399B8B200-4.png` | `e68d8d7a80c17e40d50da45220d6886fd5100008c179b0a2caa96bb245a8930f` |
| `F5AE0448-733F-402F-BCAF-64E473A3BD3A-1.png` | `754da4dd340588e026dac1787cc2fd51ca332bcb98e0e8869f7c00878a5bdea8` |
| `F5AE0448-733F-402F-BCAF-64E473A3BD3A-2.png` | `e647c1a720e57c70c54434e29c0b1793cc0560f3153349294ff31d13ec56766b` |
| `F5AE0448-733F-402F-BCAF-64E473A3BD3A-3.png` | `9ec050e40708d153d259c47268fca2d73fb61eceb02b14c817b71479b5910334` |
| `F5AE0448-733F-402F-BCAF-64E473A3BD3A-4.png` | `14ace4b921b3cd0a456e8cb2086ee1d40bc53ad878809eb8decbf76ea21bb797` |

## Gate interpretation

This review contributes actual native PDF opening, standard-paper dimensions, complete equipment content, unit/label inspection and rendered-page readability for the declared fixture. It does not convert the wider native job into a success, establish an actual system share/provider round trip, prove physical-device behavior, or promote M05/export or release readiness. The full export gate in `docs/QUALITY.md` remains dependent on its other required evidence. No production files, repository state files, staging area or commits were changed by this review.
