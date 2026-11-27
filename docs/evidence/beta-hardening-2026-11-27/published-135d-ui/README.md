# A091 — terminal 135d UI accounting

Source `135d3b4755d97bbb8fcff993d8dfd532a8d48b93`, [run 46031166740](https://github.com/mirzotipi-wq/APP1/actions/runs/46031166740), attempt 1. All nine required UI jobs failed during build-for-testing, before any XCTest method started. Each original job log independently contains the same iOS 18 availability error at `LightingProjectDocument.swift:116` and build exit 65. This is an observed build failure, not 44 failed test methods.

| Shard | Job ID | Expected | Started | Passed | Unstarted | Build exit |
|---|---:|---:|---:|---:|---:|---:|
| app-accessibility | 140617447812 | 1 | 0 | 0 | 1 | 65 |
| beta-accessibility | 140617447998 | 1 | 0 | 0 | 1 | 65 |
| beta-workflow | 140617447790 | 4 | 0 | 0 | 4 | 65 |
| library-reference | 140617447775 | 9 | 0 | 0 | 9 | 65 |
| lighting-export | 140617447845 | 2 | 0 | 0 | 2 | 65 |
| plan-gestures | 140617447821 | 3 | 0 | 0 | 3 | 65 |
| room-precision | 140617447785 | 5 | 0 | 0 | 5 | 65 |
| studio-optics | 140617447890 | 10 | 0 | 0 | 10 | 65 |
| studio-smoke | 140617447837 | 9 | 0 | 0 | 9 | 65 |

## Execution and evidence boundaries

All simulator-selection steps succeeded. Every simulator warm-up and selected UI command was skipped after the build failed. Exact method accounting and finalized-result export then failed closed; each log explicitly reports no finalized XCTest result bundle. No startup failure or cancellation was observed. The original decoded logs contain zero `Test Case` markers, including zero unrecognized or foreign method events.

Both Default and AXXXL visual readers also failed because their attachment manifest was unavailable. No required Default/AXXXL or supplemental beta originals were produced. Artifact upload/download step success alone is not screenshot evidence. No artifact archive was downloaded by this worker.

The run was terminal failure at `2026-11-27T16:22:51Z`. Newer af6 run `46033956426` was created at `2026-11-27T16:28:47Z`. These failures therefore precede the later source run; they are not attributed to a superseding push.

## Retained files

Integrate `receipt.json`, `per-shard-accounting.json`, `expected-methods.json`, the nine `*-excerpts.log` files, `visual-review-summary.json`, `later-run-timing.json` and this README. The original API run/job JSON and decoded logs under `raw/` are private complete source material; their hashes and byte lengths are retained. Raw log bytes were reconstructed from the decoded tool response with only the patch transport's extra terminal newline removed, then checked against original scalar count, line count and terminal-newline metadata. Excerpts remove ANSI coloring and preserve original line numbers.

This worker made no repository edits, started no tests/builds, requested no retries, changed no gates and transferred no other-revision passes. A080 separately reconciles the native-unit/macOS job; this packet covers the nine UI shards only. The newer compatible candidate needs its own exact-source Apple results.
