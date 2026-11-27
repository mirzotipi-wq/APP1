# Wave 07 owner-request analysis

This is a lane03 review artifact for root integration, not an acknowledgement from another owner. Input is `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; no production source changed in this review.

## Immutable request snapshots

| Lane | Observed head | Request blob |
|---|---|---|
| 02 photometry/color | `b5c1f008446f8b33f3ee97f8fefe6675058ef347` | `e03d008c10197c960c75f5168ee1c8a46b7949cd` |
| 04 GPU/cache | `88279ba0ee0262ea6c880580c8a85b56342abbff` | `7ff42021d0e4f2166b8750c233474083bbc26d79` |

W67 fetched these heads and immutable files. Exact bytes, git-blob verification and source SHA256 receipts are retained in `W67-source-receipts.json` and the W67-prefixed artifacts. Later branch movement is outside this snapshot.

## Tiny intensity: CPU response and open GPU policy

Lane03's db7 CPU correction integrates each tiny emitter at unit output and restores its requested Double output once, preserving ordinary accumulation and packed layout. The complete Sources, Tests and scripts tree IDs remain identical at 36ed; all 31 LightingCore inputs match the final source manifest (`W61-source-compatibility.json`).

Lane02 separately asks GPU routing/packing to reject or route positive per-cell values becoming Float subnormal or zero unless a validated scaled representation is provided. Latest reviewed04eligibility lacks that explicit intensity policy. Keep this request open with lane 04; CPU lane 03 must not silently claim agreement or implementlane 04 owned routing.

The proposed *near-field guard skipping* explanation was falsified by source inspection at both pins. Point/directional distance is checked before intensity math, contribution validity before the zero-lux return, samples are not skipped solely for zero packed candela, and rectangle area guards precede the sample loop. Existing eligibility also evaluates positive Double lights and rejects near-field geometry. Positive numerical underflow alone therefore does not prove lost unsupported-mask positions, an RGB8 mismatch, or an admitted runtime defect. W64 authored no optional probe after this finding; no fresh Swift/C++/native run is claimed.

## Width24 and camera eligibility

The lane03 actual-Swift fixture remains separate evidence:24×16, no lights, zero unsupported pixels; shared-host comparison mean0.107639, maximum24, fraction(error>4)=0.00520833, zero mask mismatches, FAIL at the unchanged0.005limit. Both original logs and binary remain preserved. The six required parity and eight strict precision fixtures do not erase this diagnostic counterexample.

Latest lane 04 source implements an actual-width conservative shell guard and CPU routing for the narrow non-axial near-vertical camera cone; exactly vertical views retain eligibility. W67 inspected production width forwarding and core/native regression assertions, including the exact width24 fallback followed by eligible Metal rendering. These source checks are not actual04native verification. Keep acceptance of the integrated guard tied to04/19 native execution and source identity; preserve the prior actualSwift failure. The lane 04 engine and width-aware helper must be integrated together. The tested shared-kernel hash differs from latest lane 04; the old six-plus-eight host passes cannot be reassigned to that changed source without its own validation. No CPU basis or photometric-threshold change is requested.

## Preview and broader ownership

The existing preview entry remains `ReferenceStudyPreview(scene:subject:)`. Keep cancellation checks after engine await and immediately before adopting image/error/backend state. The pre-cancelled-begin correction belongs to36ed; the latest lane 04 request already recognizes the publication guards. Name-only request canonicalization remains optional and deferred; scene validation must remain complete.

GPU/cache routing belongs to lane 04; malformed host-parser inputs belong to lane 19; shared composition and validation bounds belong to lane 01; global integration/state belongs to lane 20. This artifact does not promote M02/M03 globally or establish native UI, physical calibration, device performance, or manual accessibility acceptance.
