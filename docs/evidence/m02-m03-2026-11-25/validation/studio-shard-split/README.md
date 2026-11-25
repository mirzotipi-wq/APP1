# Required studio shard split candidate

Base published source **9eddd97c5e638edf1768332d9d83d7dc2cccb72a**; working source hashes in the [validation receipt](validation.json) identify the exact candidate. This packet records source partition and local validation, not Apple compilation, UI execution or a gate pass.

- [Work packet and rationale](../../followups/followup-studio-shard-split.md).
- [Exact candidate diff](candidate.diff), including the new StudioOpticsUITests file.
- [Frozen validation and complete 36-method mapping](validation.json): all method bodies preserved; eight classes assigned once; inventories 5/11/10/10; ten existing selector tests passed; YAML/29 bash/seven Python blocks and two Swift syntax parses passed.
- [Byte-identical moved optics block](moved-optics-block.swift.txt) and [copied setup/app/status helpers](copied-helpers.swift.txt).
- [Actual cbf budget evidence](budget-source-summary.json): nineteen completed passes, one interrupted final method, all ten optics passes, and the exact forty-minute step-timeout row. Its full original summary hash is preserved.

The original validation receipt's report path/hash identifies its frozen outside version; the [copy manifest](copy-manifest.json) separately binds this repository edition. All original shard deadlines, host/toolchain settings, maximum parallelism three, test actions/assertions and production source remain unchanged. One additional standard-host setup is required; no runtime speedup is established. Independent reviews are recorded separately.
