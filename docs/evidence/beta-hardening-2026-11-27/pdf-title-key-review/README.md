# A099 — independent PDF metadata-key review

Decision: approve the minimal repair, pending actual Apple compilation and execution.

The review independently verified the primary Apple declarations: `documentAttributes` is optional `[AnyHashable: Any]`; `titleAttribute` is a `PDFDocumentAttribute`; that attribute type is string-backed `RawRepresentable`. The explicit `PDFDocumentAttribute.titleAttribute.rawValue` resolves the unqualified-member error and uses a raw string key rather than relying on wrapper equality. Actual PDFKit behavior remains for native CI to verify.

The exporter still supplies `Key & Fill - Lighting plan` through `kCGPDFContextTitle`. The assertion retains this exact expected value and has no fallback for missing metadata, wrong type or a different title.

An exact comparison against `af6b7e5` confirms one expression replacement and every other byte unchanged. All five PDF method identities and every other expectation remain. DEBUG/Release syntax, targeted diff, and structural state checks passed; no Apple SDK type check, native test, PDF generation or visual review was performed.

The reviewed source and exporter hashes, exact commands, primary URLs and boundaries are in `receipt.json`. No repository mutation was made by this reviewer.
