# W47 — consumer contract review

**Verdict: conditionally compatible.** Lane02's tiny-output request and lane04's Float32 contract need no ABI change. This reviews the supplied candidate design, not W44's implementation.

## Provenance

Input: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`; clean private worktree. `ReferenceStudy.swift` Git blob: `ace5e59027b6a05484e129be233928b85a3e7a7b`; SHA256: `86ca1199487d567af8e444e714eabca8252b500bc33b40763d7b258d505977cf`.

Exact fetched and hash-verified receipts:

- Lane02 `CONSUMER-REQUESTS.md`: blob `c78ae135a3232da2b61005ce3f841c9465048e30`, requested from `finish/02-photometry-color`.
- Lane04 `OWNER_REQUESTS.md`: blob `8d83e9e9b639d862c521de5d8e3d3c9c5a5db700`; assignment pins commit `c76e176fa60d29f8ebd49845d7e8ea883c11b64f`. Branch/commit membership was not independently queried.

## Compatibility conditions and falsifiers

1. Keep `outputScale` private, default 1. Normalize only positive original candela whose computed per-sample Double is subnormal/zero. Zero-output lights remain absent. Ordinary accumulation order stays unchanged.
2. Accumulate unit total lux, visible lux and XYZ **per emitter**, then multiply each by that emitter's original candela once. Scaling individual contributions before accumulation recreates underflow; scaling a mixed-light aggregate corrupts additivity.
3. Pack `normalizedCandela * outputScale` in Double before Float conversion. Never pack bare unit candela, store scale in color.w, or add rows. Preserve six parameter rows, three sample rows, three area rows; area tags, positions, normals and ordering remain unchanged (`ReferenceStudy.swift:270`, `:431`).
4. Retain all 64/1024 rectangle samples, contiguous area groups and near-field guards even when packed intensity is zero (`:236`, `:249`, `:301`, `:307`). Dropping dark samples can change unsupported masks.
5. Tiny positive CPU output versus Float32 zero is an intentional precision-domain difference. Requiring Float32 to retain these Double values would conflict with the frozen contract. Do not expand GPU eligibility or claim meter agreement establishes rendering acceptance.

## Actual checks and remaining evidence

Two receipt Git hashes and the original source SHA256 matched. Twenty-one Python IEEE-754 scalar packing comparisons across sample counts 1/64/1024 preserved existing Float32 bytes; all triggered tiny cases packed zero. These are scalar witnesses, **not shipped Swift/Metal tests**. No copied-JavaScript numerical probe, Swift execution, build, source edit, commit, push or external message by W47.

Root's recorded actual Swift 6.2.1 Linux baseline remains **56 failures / 166 checks** (`W42-original-inputs.json`); W47 did not rerun it. After integration, require actual candidate Swift tiny-output/additivity/visibility evidence, packed-byte checks, six parity cases, eight precision cases, twelve render hashes and exact invalid masks. Preserve the separate lane04 width24 silhouette failure; this candidate does not resolve it.

Evidence: `wave05-evidence/W47-contract-checks.json`, both `W47-lane*-*.md` receipts, and `W47-check-command.sh`. No interruption observed; truncated initial local-read output was reread.
