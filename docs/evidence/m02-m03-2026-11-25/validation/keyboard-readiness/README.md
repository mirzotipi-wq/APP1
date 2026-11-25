# Keyboard readiness: actual cbf failure and separate helper candidate

The cbf library evidence belongs to run **45623581873**, job **139252380291**, source **cbf94cecb113c1f03b0b8c7287e763655c14ec11**. The working helper candidate is based on **9eddd97c5e638edf1768332d9d83d7dc2cccb72a** and identified by its exact source/diff hashes. These are separate scopes; the candidate has no Apple execution result in this packet.

- [Actual keyboard/host investigation](../../followups/followup-cbf-library-readiness-host.md), [raw selected method lines](cbf-keyboard-excerpts.log), [selection provenance](excerpt-selection.json), [key query](key-query.txt), [name-field query](name-field-query.txt) and [attachment manifest](attachment-manifest.json).
- [Original bounded host log before tests](ui-host-before-tests.log), [after tests](ui-host-after-tests.log) and [parsed summary](host-capture-summary.json). Host snapshots are not continuous measurements, a causal finding or physical-device performance evidence.
- [Candidate semantics and validation](../../followups/followup-keyboard-helper-semantics.md), [exact diff](candidate.diff) and [exact validation receipt](source-validation.json).
- [Original source/derived-file index](investigation-source-index.json) retains binary/video/frame hashes and original scratch paths for provenance. Those binaries and the full test/job logs are not stored here. Query-only attachments do not contain a resolved AX hierarchy.

[Copy manifest](copy-manifest.json) binds exact copied files, newly selected excerpts/summary and both original/repository report hashes. Frozen receipt absolute paths and old report hashes remain deliberate original provenance; use the relative links above for repository files. No prior receipt was edited, and no new gate pass is asserted. Independent review is maintained separately by a097.
