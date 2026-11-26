# w084 — fallback contract, initial review candidate

Worker `/root/w081/w084` is one actual contract writer with no children. Input is `53d7302931ccaadd7a2ad29c55fd94a695c5997e`; production source remains `69eb9c5096c863e9c8be1c5e53d9faff0d9c3014`. I read the role packet and all ten mandatory project files. The scoped branch instructions supersede historical main/global-state tasks.

The new contract describes unchecked, validated Metal and permanent CPU states; deliberate CPU routes; exact startup/render errors; retry only on eligible cache misses; successful-frame admission; selective Metal invalidation; submitted-command completion; and caller adoption responsibilities. It preserves the distinction between backend provenance and engine selection. CPU remains authoritative, cache budgets apply per engine, and no atomic cancellation, GPU preemption or physical-memory claim is made.

Source review confirms the A→B→A consumer bypass: after B confirms downgrade and is cancelled, the view can mark its retained A/Metal frame current without consulting the engine. This remains owner03/20 work. The contract links the unapplied owner patch and hosted regression specification, preserves the different preview baselines, and claims no UI implementation or runtime pass.

Retained source6 evidence reports174 Debug native methods including25 cache methods, both builds and finalized accounting/export. Source7 has29 cache methods, with four additions still awaiting Apple execution; its379/379 portable passes do not establish native behavior. Actual simulator Metal, scripted lifecycle assertions, CPU payload counters and physical-device measurements remain separate.

Executed operations were28 immutable GitHub reads:26 successful and two404 responses, followed by UTF-8 candidate creation. In-memory extraction checked the method inventory and focused source paths. No shell, status/history command, agent_cycle, hash-object, build, test, SDK probe, CI poll/rerun, local directory creation, source/ref mutation or global-state update occurred. Planned worker/results paths remain uncreated.

The initial contract is blob `11cbd4278db167fa50e5c93ba5cc99f03687074f`, mapped to `docs/parallel/04/FALLBACK_CONTRACT.md` and `evidence/w084/FALLBACK_CONTRACT.v1.md`. Inputs are blob `50846823b84055b6703fcf2ec2939d374add9b05` at `evidence/w084/inputs.v1.json`; evidence paths are relative to `docs/parallel/04`. [receipt.v1.json](../evidence/w084/receipt.v1.json) maps every returned object, including this report.

This is preserved v1, not final freeze. Parent requested narrower pre-submission wording, an early-return table introduction and explicit observed-failure precedence. Remaining sibling feedback will be incorporated in a separately retained revision; the original will not be overwritten.
