# A016 — ignored JSON Unicode consistency

Baseline: `9e2313cbffb01d66249458c64087cb66c7652cca` plus existing unrelated working changes. Linux x86_64, Swift 6.0.3. Only the assigned parser and new regression file changed; no commits or pushes.

## Before

The unchanged parser accepted malformed Unicode in ignored scene metadata while rejecting the same bytes/escapes in the consumed project name. Four new methods ran before the fix: **47 assertion failures, exit 1**. Failures were 24 invalid UTF-8 cases (six byte variants in four ignored locations), 18 unpaired-surrogate escape cases (six variants in three locations), and five supported UTF-16/32 versions of an ignored unpaired escape. Valid metadata already passed. See `red.log`, `red-receipt.json`, and `LightingProjectDocument.before.swift`.

## After

The existing iterative duplicate-key scan validates every disjoint string token through one reused Foundation JSONDecoder. Ignored strings now follow the same Unicode validity rules as consumed strings; invalid input throws `invalidDocument`. Key comparison still uses decoded UTF-8 bytes, preserving NFC/NFD distinction and escaped-key duplicate detection. Valid unknown metadata remains accepted and discarded.

**28 focused document tests passed, zero failures, exit 0** (4.391 seconds test execution), including the same four new methods. Existing duplicate, deep/wide metadata, exact 8 MiB/one-byte-over, large-name and valid Unicode encoding cases pass. New positives include surrogate pairs, escaped controls including NUL, quoted punctuation, UTF-8 BOM, and supported UTF-16/32 forms. See `green.log` and `green-receipt.json` for exact commands and hashes.

Both commands used `swift test --jobs 2 --cache-path /workspace/scratch/b25ffdc7aed8/cache/swiftpm` with the requested Swift PATH and Clang module cache. Red filter: `ProjectDocumentIgnoredUnicodeTests`; green filter: `(LightingProjectDocumentTests|ProjectDocument.*Tests)`.

## Limits

No dependencies, extra whole-document pass, or unbounded rescan added: string tokens are disjoint and the existing pre-decode 8 MiB bound remains. This is Linux Debug evidence; full-suite, Release, Apple/native execution and standalone performance benchmarking were not run. Scope review was self-review; independent review remains for integration. Original failed evidence is retained.
