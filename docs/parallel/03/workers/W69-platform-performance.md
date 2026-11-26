# W69 platform/performance — wave07

Runtime: `/root/wave07/w69_platform_performance`. Input: `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`. Private tree: `/tmp/keyfill03-7f4b/workers/W69-platform-performance`.

**Status: existing host receipts verified; no new execution.**

SHA256 checks matched all fourteen fixture binaries against the manifest, private tree, pinned Git blobs and retained root artifacts. All four manifest source hashes matched the private tree and both db7a5b5/36ed6a1 blobs. W61's existing receipt supplies unchanged Sources/Tests/scripts and 31 LightingCore inputs; that audit was not repeated.

The six parity log entries exactly match the manifest: six PASS, zero mask mismatches, near-field 84/84 invalid, maximum error at most 1. The eight precision entries likewise match: eight PASS with strict limit 1, observed maximum 0, zero mask mismatches, and invalid counts 49, 9, 19, 13, 19, 13, 19, 19. Nonzero invalid counts are preserved.

Preparation commands compile Swift against LightingCore objects; inspected generators call `StudyComputeInput` and `ReferenceStudyRenderer.render`, storing actual Float32 buffers and renderer validity. The C++ harness includes `StudyKernel.h` and checks every invalid-mask position. This supports actual Swift CPU/shared-Float32 host evidence, not a Double transcription or native Metal result.

Carry-forward stops at identical inputs. W67's lane04 artifacts at `88279ba0` rehash correctly. Its kernel `5bdba47a…` differs from the tested `1eca1836…`; width-aware eligibility, engine forwarding and kernel metadata guards were source-inspected only. Integrated lane04 needs owner/source-specific validation.

Retain the separate width24 FAIL (>4 fraction 0.00520833, maximum 24). Existing benchmark remains eight frame/twelve cancellation/four visibility workloads, diagnostic only. Ten corrected preview-host passes remain separate; the Apple job was reported running by the parent and was not refreshed or counted as passing.

Actually performed: instruction/source/log reads, Git identity reads, hashing and receipt parsing. No build/test/render/benchmark, source edits, refs or external messages. Two displays truncated; focused reads resolved the required evidence. No runtime outage or new behavioral failure. Working-token/checkpoint counter unavailable.

Full hashes, parsed gates and limitations: [W69-platform-performance.json](wave07-evidence/W69-platform-performance.json).
