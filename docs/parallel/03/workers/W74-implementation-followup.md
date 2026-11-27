# W74 followup — previous-frame unsupported warning

Actual canonical runtime ID: `/root/wave08/w74_implementation`. This is the existing W74 worker's explicitly authorized supplementary source assignment for **W78-AX-01**, not a new worker. The original W74 report remains intact; its source-no-change statement describes the earlier image-review assignment and is superseded only for this followup.

Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. Candidate exists only in `/tmp/keyfill03-7f4b/workers/W74-implementation/App/ReferenceStudyPreview.swift`. No production-checkout source file was changed.

The candidate applies when the displayed image belongs to a previous request for the same subject and its unsupported-pixel count is positive. It appends that count to the previous-image accessibility label and displays **“Previous render: N unsupported pixels (magenta)”** inside the existing updating/paused status container. A single vertical stack contains both status and warning, avoiding another bottom-leading overlay. The previous warning carries no old lighting advice or backend label into the new request.

The existing current-frame warning is unchanged, including when inactivity occurs without changing the request. Existing accessibility identifiers, pipeline, task identity and source tests are unchanged. No helper or string-mirroring test was added.

**Executed checks:** `git diff --check` returned 0; `git diff --name-only` reports only the assigned Swift file; `git apply --check --reverse` against the saved patch returned 0. The bounded diff was inspected. This is source evidence only: no build, tests, rerender, benchmark or actual VoiceOver/UI reproduction. Root owns native compilation and integration. Candidate path and hashes were sent to W80 for independent review and to W71/root coordination.

Artifacts: [candidate patch](wave08-evidence/W74-previous-frame-warning.patch) and [source/check receipt](wave08-evidence/W74-previous-frame-warning.json).

- Original source SHA-256: `45a899619938e4a9c719f42af9c37d79e685c3a98d51465ca1995cc260595fc6`.
- Candidate source SHA-256: `612e922e16a900bf69cbc1bf13d9995912db535703a4b0bd85f372de1f1d44a5`.
- Patch SHA-256: `cf1a9ac9711102a7d81b3ea153a11bffaaa67cb585aa22b484af1dd65a223e05`.

Recommendation: review this minimal candidate, then integrate subject to native compilation. No commit, push or cleanup was performed; the image exhibit and original reports were not edited by this followup.
