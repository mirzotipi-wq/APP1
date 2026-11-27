# A098 — explicit PDF metadata key

At exact source `af6b7e56bb5d2b550ebefcc5fd7bb2afc4c20867`, original Apple compiler logs rejected `pdf.documentAttributes?[.titleAttribute]`: the dictionary context is `AnyHashable`, which does not supply that static member.

The one-expression repair uses `PDFDocumentAttribute.titleAttribute.rawValue`. Apple documents the dictionary as `[AnyHashable: Any]?`, the title constant as `PDFDocumentAttribute`, and that attribute as a String-backed RawRepresentable. The explicit raw String key avoids both contextual-member inference and an assumption about equality between a wrapped attribute and the metadata dictionary's string key.

The exact expected title remains `Key & Fill - Lighting plan`, matching the unchanged exporter's `kCGPDFContextTitle` metadata value. Missing metadata, a failed lookup or a different title still fails the same assertion. All five native PDF method identities, PDF content/region/footer/privacy checks and every other byte of the test file are unchanged.

DEBUG and Release syntax checks and the targeted diff check passed. These are Linux syntax checks only. No Apple type check, PDFKit lookup, rendering or native execution is claimed. Fresh Apple CI must compile and execute the unchanged assertion.

`receipt.json` records exact hashes and primary Apple documentation URLs. `change.patch` is the complete source change. No commit, deployment setting, production file or gate was changed by this worker.
