# A097 — final-source UI compilation failure accounting

Source: `af6b7e56bb5d2b550ebefcc5fd7bb2afc4c20867`.
Run: [46033956426](https://github.com/mirzotipi-wq/APP1/actions/runs/46033956426).
Observed terminal metadata: 27 November 2026, 16:50:27 UTC. The run concluded failure and was last updated at 16:47:42 UTC.

## Finding

All nine required UI jobs failed during `build-for-testing`, with exit 65 and the same compiler diagnostic in `NativeTests/LightingPlanPDFTests.swift:188`:

```
type 'AnyHashable' has no member 'titleAttribute'
```

The failed assertion indexes `pdf.documentAttributes` using the context-dependent `.titleAttribute` spelling. The error is in the native test bundle compiled by the shared scheme; it blocks the otherwise unrelated UI groups before execution. This packet does not implement or validate its repair.

| Required group | Job ID | Expected methods | Started | Passed | Executed failures | Unstarted |
|---|---:|---:|---:|---:|---:|---:|
| Room / precision | 140628197690 | 5 | 0 | 0 | 0 | 5 |
| Library / reference | 140628197602 | 9 | 0 | 0 | 0 | 9 |
| Studio smoke | 140628197800 | 9 | 0 | 0 | 0 | 9 |
| Lighting export | 140628197721 | 2 | 0 | 0 | 0 | 2 |
| Beta workflow | 140628197716 | 4 | 0 | 0 | 0 | 4 |
| Plan gestures | 140628197745 | 3 | 0 | 0 | 0 | 3 |
| Beta accessibility | 140628197684 | 1 | 0 | 0 | 0 | 1 |
| Studio optics | 140628197693 | 10 | 0 | 0 | 0 | 10 |
| App accessibility | 140628197673 | 1 | 0 | 0 | 0 | 1 |
| **Total** | | **44** | **0** | **0** | **0** | **44** |

The inventory comes from Git at the exact source revision. Every original decoded UI job log contains zero `Test Case` markers. Each job selected an available simulator successfully, then failed its build. Warm-up and the selected UI test command were skipped. No simulator startup failure or cancellation was observed. Required-method accounting and finalized-result checks failed closed; each log explicitly reports no finalized XCTest result bundle and no `native-tests.log`.

These are 44 unstarted methods, not 44 failed or skipped XCTest methods. Both downstream visual readers failed their original screenshot provenance step. No prior source's UI passes are transferred.

## Original capture evidence

Two compact archives were downloaded and their complete bytes independently hashed against GitHub's declared digests before bounded ZIP enumeration:

| Artifact | ID | Bytes | SHA-256 |
|---|---:|---:|---|
| App accessibility compact | 15216237096 | 304 | `8d6a80bc181ba6630e8bed73cd79c61731f70cabb2524fd207cd0bc473eb24e2` |
| Beta accessibility compact | 15217920849 | 580 | `867ba7ead607579be3978b17222ce9562f548a0aa317438084230a1521ac4255` |

They contain only unavailable trace-status text: skipped test step, missing start/end timestamps and unavailable shell outcome. There are no images, PDFs or attachment manifests. Thus this run produced **zero of 28 required Default/AXXXL originals** and **zero of eight supplemental beta originals**. A green artifact-upload or trace-export step does not mean that screenshots or trace events exist.

## Verification and retained files

`reconcile.py` checks the exact run/source, nine terminal job outcomes, step statuses, compiler diagnostics, build exits, no test events, missing result bundles, 44 unique required identities and the two archive checksums. Its execution completed successfully. All nine saved decoded logs match the fetched text's UTF-8 byte, Unicode scalar, UTF-16 code-unit, newline and carriage-return counts: 2,727,255 bytes total.

Integrate `receipt.json`, `per-shard-accounting.json`, `expected-methods.json`, `source-hashes.json`, `failing-source.json`, nine `*-excerpts.log` files, `compact-artifact-verification.json`, `artifacts-observed.json`, `log-transport-counts.json`, `reconcile.py`, this README and the two original compact ZIPs. The full decoded logs, complete run/job metadata and clearly named partial snapshots may remain private analysis; include them if exact local reproduction of `reconcile.py` is desired.

## Limits

No repository changes, builds, tests, retries, live app interaction, current-source screenshot inspection, signing or distribution were performed by this worker. This packet covers UI jobs only. Current-source portable/macOS/native details belong to the separate A094/A095 receipts. It supplies no native/UI acceptance, layout acceptance or beta-ready claim. Any subsequent repaired revision needs fresh execution.
