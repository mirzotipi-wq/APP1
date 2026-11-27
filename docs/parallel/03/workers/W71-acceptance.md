# W71 — image acceptance

**Runtime:** `/root/wave08`. **Input:** `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. Private detached tree: `/tmp/keyfill03-7f4b/workers/W71-acceptance`; output: `/tmp/keyfill03-7f4b/builds/W71-acceptance`.

## Findings

Accept the retained twelve-scene CPU image evidence at this unchanged LightingCore source. I directly viewed the original and final contact sheets and the historical clipped-camera PNG. All twelve scene JSON and PPM pairs are byte-identical; independently computed final artifact hashes match the comparison manifest. All 31 LightingCore inputs match the final rendering source manifest. Contact-sheet display sizes differ; exact equality applies to the underlying fixtures.

The images preserve their geometry, shadows, relative exposure and color. The crown shape appears in the original bust views. Dark rim-only surfaces are part of the direct-light model; the saved validity mask is the appropriate unsupportedness evidence. W72 independently parses all image/mask bytes.

The separate no-light overhead diagnostic originally emitted a 144×96 frame with 11,708 unsupported pixels. The corrected result records `invalidCamera` and publishes no clipped-camera image. The 0.20 m clear-camera image remains unchanged. These records do not show a new rendered error screenshot or an application UI test.

## Source finding and candidate

W78 found, and W71/W80 independently confirmed, that a retained previous same-subject frame with unsupported pixels loses its textual invalid cue. Root authorized the existing W74 worker to prepare a minimal private-tree correction: qualify the old count in the image accessibility label and the existing updating/paused status container. The current warning, identifiers, pipeline, task body and tests remain unchanged. W80 found no source blocker. Root integrated the candidate and passed syntax/diff checks; [its receipt](../evidence/preview-previous-warning-inputs.json) leaves Apple SwiftUI compilation pending. Source36 native results predate the correction. See [the followup](W74-implementation-followup.md).

## Execution and limits

Read the required contracts and startup documents. Ran source/artifact hash reconciliation and `agent_cycle.py check`/`next`; the latter are structural checks only. No renderer, benchmark, Swift suite, native UI, Metal, VoiceOver or physical-device test was run by W71. Existing root executions remain separately attributed. Original failures are retained. No new runtime interruption occurred; four prior outages are historical context. Exact token counters are unavailable, so the 12,000-token target and 60% checkpoint are not measured claims.

Evidence: [acceptance receipt](wave08-evidence/W71-acceptance.json), [serial setup](wave08-evidence/W71-setup.json). Wave staffing and specialist dispositions are in [wave08.json](wave08.json).
