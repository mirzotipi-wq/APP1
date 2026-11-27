# A090 — final candidate publication binding

Independent GitHub GETs at 2026-11-27 16:30:53 UTC confirm that `main` points to `af6b7e56bb5d2b550ebefcc5fd7bb2afc4c20867`, tree `3de272446b3594323485df984408250eff178559`, parent `135d3b4755d97bbb8fcff993d8dfd532a8d48b93`. All 16 root entries match local paths, modes, types and object IDs; the returned tree is not truncated.

All 258 source-manifest hashes match the working files, published commit and preserved local-equivalent commit `bab46f4b6d40452b7609daa14c3a67b093cb3f9e`. The manifest checksum matches its publication receipt. Exactly the declared parser and two UI-test paths changed from checkpoint 03. Concurrent `1a6362b` remains an ancestor. Both deployment files are byte-identical to the parent and retain iOS 17 / macOS 14.

The retained Debug and Release logs independently contain 594 distinct methods started and passed exactly once, with no failures, and their recorded command exits are zero. The completed local tooling output reports 120 tests and OK. These are readings of original executions, not reruns by this reviewer.

No Apple build or runtime result is claimed. Publication integrity, Linux validation and inventory counts do not establish beta acceptance, physical-device behavior, signing or distribution.

`receipt.json` gives the checks, limits and evidence hashes. `source-comparisons.json` retains all 258 input comparisons; `remote-verification.json` and `local-root-tree.json` retain the independent tree observations.
