# W96 resource and recovery accounting

Task `/root/wave10/w96_resource`; private input `342e3280e3eb077d55e122c8bfb88b4062b431ed`. Linux x86_64/Python 3.12.14. Read-only source/archive reconciliation; no Swift execution, benchmark, rendering, cleanup, source edit or commit. Exact command, host, source/artifact hashes and time-scoped inventory: [receipt](wave10-evidence/W96-resource.json); [audit](wave10-evidence/W96-resource-audit.py).

## Resource limits

- Mannequin width ≤144, height ≤96: 55,296 RGBA + 13,824 mask bytes. Rectangle budgets remain 64 interactive/1,024 reference samples; twelve validated lights permit 768/12,288 samples per surface. Inspected sources match retained W86 hashes.
- Fixed mesh: 5,248 triangles. Cached normal/area fields contribute 32 scalar bytes each, 167,936 bytes (164 KiB) logically. This excludes SIMD padding, capacity, allocator overhead and the rest of the mesh; it is not measured Swift allocation or RSS.
- CPU cancellation polls at most every eight pixel evaluations. The preview’s 80-ms debounce is separate; neither establishes cancellation latency through validation/setup.
- Engine-owned completed cache: ≤4 frames, ≤262,144 RGBA bytes and ≤65,536 mask bytes. Caller retention, conversions, scratch arrays, geometry and Metal allocations are outside those payload bounds.
- Light-name validation depends on Unicode/UTF-8 input size. Eighty graphemes is not a byte bound; cache keys remove names only after validation.

## Preserved accounting

The campaign records four executor outages. Wave02/03/04/06 and upload recovery narratives lack common event IDs; their independent deduplication is unresolved. All survive without fabricating an extra pass. Fourth-upload recovery records 51 unique blobs verified later. Debug/Release signal-9, empty exit-1 retry and ambiguous-`pow` compilation remain unsuccessful attempts; later corrected runs are separate.

Wave09 cleanup followed recorded remote preservation at `92dc7a69` and 35 artifact checks. Its first attempt removed W81–W83, stopped before W84’s unexpected ` A` status, then resumed only after both candidate files matched published `aaa3f376` bytes. Historical trees need not remain present; W96 removed nothing.

Ledger/report sizes are a timestamped snapshot, not final 100-worker certification. Four active slots include root and leader; followups/unused trees are excluded. Exact token counters are unavailable: word/byte proxies cannot certify 12k usage or a 60% checkpoint. No global M02/M03, device or release acceptance is asserted.
