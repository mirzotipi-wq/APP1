# W08-06 resource/configuration audit

Reviewed frozen `46a161c` against native source `08e80c7`; repository remained clean.

No declared duplicate compilation or missing tracked resource was found. The app includes 47 Swift files, one Metal source, its adjacent header, three asset-catalog files, and one explicit privacy resource. Its only package dependency is `LightingCore`; `StudioComposition` is not exported or linked into the app.

The three portable composition files and four composition-test files exactly match root SwiftPM resolution. Exclusions cover every remaining App/NativeTests file, including assets, Metal and header. No UI-framework imports appear in the 93 resolved Swift inputs. The viewport helper is shared across separate native test modules.

Startup checks and source icon validation exited 0. The icon is 1024×1024 opaque RGB8 sRGB. Git-read privacy matches its validator despite sparse checkout absence. All 179 current manifest hashes match frozen HEAD; the old 175-input manifest omits privacy.

XcodeGen membership remains declarative. Generated phases, compiled assets, packaged privacy, default Metal library/function and native execution remain UNVERIFIED. Root's portable passes do not establish bundling; its original default Release SIG9 remains separate.

No source edits, builds or test suites. Exact commands, resource blobs/hashes, checks and limits are in `receipt.json`; `source.patch` is empty.

