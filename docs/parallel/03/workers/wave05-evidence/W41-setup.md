# W41 wave 5 setup

Immutable input: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`. Actual runtime ID: `/root/wave05` (parent confirms tool returned task_name only).

Initial persistent git HEAD matched input, branch `finish/03-cpu-study-mannequin`; existing wave4 reports/evidence/protocol edits were left untouched. Initial control clone lookup failed: `/tmp/keyfill03-7f4b/worker-control` did not exist. `/tmp` had 4.2 GiB free; persistent volume had 46 MiB. Recreated shared no-checkout clone, sparse pattern `/*` plus `!/docs/evidence/`, original GitHub promisor origin and detached input. Created own and W42 detached trees sequentially. No cleanup.

Read AGENTS.md, acceptance contract, worker protocol, operating protocol, handoff/state, product/architecture/roadmap/quality/design. `python3 scripts/agent_cycle.py check` exited 0 (structure only); `next` exited 0 and identified M03 editing/accessibility/persistence.

`docs/parallel/02` and `docs/parallel/04` are absent from this immutable tree. Consumer cross-lane source must be retrieved separately and attributed; absent documents do not count as reviewed. Relevant production source is `Sources/LightingCore/ReferenceStudy.swift`, not a separate StudyLighting.swift.

No Swift compilation, render, native test, GPU execution, benchmark or physical check was run by W41. Root serializes heavy work. Acceptance will require a preserved baseline failure, focused post-fix supported geometry/packed-layout/finite-BRDF results, and unchanged ordinary-render/parity/cancellation guarantees. Tiny physical illumination must remain effectively black in RGBA8; preserving a positive representable Double signal is a numerical API concern.

Observer corrections: W41 attempted to parse root raw stdout while its initial suffix was `.json`; JSON parsing failed because it was text. Root subsequently renamed it byte-for-byte to `W42-original-result.log` and retained provenance. A later relative listing of untracked evidence from the immutable W41 tree returned absent; the absolute persistent evidence path was then listed successfully. Neither lookup changed artifacts or indicates a source-tree loss.

One coordinator ledger-edit attempt stopped on an erroneous assertion that W46 had not yet been registered; the prior ledger remained unchanged. The corrected-patch artifact had already been written, then the metadata update was rerun against the existing W46/W48 rows without duplication.
