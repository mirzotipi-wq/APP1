# A083 — independent UTF-8 compatibility review

Approved the minimal decoder substitution. The only executable diff replaces the new strict initializer with the long-supported failable Foundation UTF-8 initializer, on the same byte slice. ASCII, escaped-value, object-key, envelope and duplicate-key paths are unchanged. The discarded decoded value is used only to establish validity; BOM normalization cannot change imported content.

An isolated optimized Swift 6.0.3 probe compared 447,404 byte sequences across an independent scalar-range oracle, the prior initializer, the new direct initializer and the exact nonzero-offset ArraySlice form. All agreed on acceptance, including 30,039 valid sequences. Compile and execution exited0. The probe includes all one/two-byte sequences, boundary triples/quads,100,000 seeded mixed sequences, BOM/NUL and malformed suffixes, overlong/surrogate/out-of-range and truncated encodings.

Apple primary documentation lists the new initializer from iOS8/macOS10.10, below existing iOS17/macOS14 minima. Actual Apple compilation and runtime validation remain required. The author’s focused document suite is separate evidence. Historical benchmarks remain bound to their recorded source; this review makes no new performance claim.

No repository edits. The `probe` executable is reproducible scratch output; retain source/logs/receipt, not the binary.
