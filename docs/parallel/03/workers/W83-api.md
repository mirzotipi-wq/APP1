# W83 API — wave 09

**Outcome:** no admitted production caller defect established; source review and bounded Python artifact checks complete. No production edits or new Swift/native execution.

**Identity:** actual runtime/task `/root/wave09/w83_api`; private worktree `/tmp/keyfill03-7f4b/workers/W83-api`; input `fb6ebdb7f9f73dab22b55df6f7919ef2f26eaad7`, tree `80b37a028b29c61e816587f1a26a714269aa17e1`. Sources/Tests/scripts trees equal CPU `db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5`. JSON records immutable file blobs/SHA256s; private tree remains clean. Root's later UI source is outside this input.

**Findings:** decoder validates bounded dimensions before multiplication, exact bytes, alpha 0/255 and transparent-magenta sentinel. Opaque magenta stays valid. Parity rejects overflow, malformed bytes/masks, nonbinary flags, inconsistent counts and nonopaque display alpha; it requires every mask position to match. Sparse maximum RGB error is intentionally diagnostic.

Two limits are contractual, not reproduced product defects. First, opaque display RGBA cannot preserve compute flags by itself: retained near-field bytes have 84 flags; alpha restoration leaves zero alpha flags with identical RGB. Current Metal decoding uses fresh transport bytes, and fixture writers restore alpha from the separate mask. Second, the internal initializer permits flag=1 with nonmagenta RGB; parity does not independently validate that implication. No current producer violation or public construction route was found.

Packed ABI remains six parameter rows and three float4 rows per sample/area, with zero/one-based area tags. Kernel pointers lack independent buffer lengths and therefore rely on trusted packing; current immutable input/private consumer preserve that boundary.

**Executed:** `rg`, focused `sed`/`cat`, git identities, SHA256s, and `python3 docs/parallel/03/workers/wave09-evidence/W83-probe.py` (absolute script path recorded). All six retained binaries passed length, row/count, finite-value, tag, sentinel and invalid-count checks. Twelve retained final masks are correctly sized/binary/zero. Original twelve raw masks are absent: no original-mask equality claim; camera diagnostics remain separate.

**Evidence/limits:** `wave09-evidence/W83-api.json` and reproducible `W83-probe.py`. Retained 391/0 core and 164/0 native results were read, not rerun. No builds, renders, benchmarks, commits or pushes. Source/byte inspection is not Swift or Metal proof. Checkpoint qualitative; token counters unavailable.
