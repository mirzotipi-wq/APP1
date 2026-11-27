# Execution helpers after the interruption

The original host is unavailable. Paths under/tmp in historical reports describe
the actual earlier runs; they are not promises that those files still exist.

prepare_worker.py is a portable transcription of the setup helper used for the
created workers. Its generalized argument form has not been executed since the
outage. Read it before running in a restored environment.

Example:

```sh
python3 docs/parallel/02/tools/prepare_worker.py /path/to/APP1 /tmp/keyfill-workers w02r09 HEAD
```

Inspect available memory and disk first. Build at most one Swift package at a
time with--jobs1 in a private scratch path. A read-only compiled module/archive
may be reused as input by tiny worker probes, but every probe must have private
source/output paths and must record the exact module-source revision. Do not
label probes against an old module as testing newer source.

Create fresh worker contexts with at most three concurrent workers plus root,
or two workers plus a separate acceptance coordinator plus root. Assign exactly
one wave/role from WAVE-TASKS.md. Record tool-returned agent IDs after successful
creation, never planned IDs. Finish W02R09/R10 before waves03–10.

Keep reports, probe source, command logs and measured results; do not commit
toolchains, modules or executables. Root integrates serially and verifies a
remote commit/ref before removing any worker-owned worktree. The wave01 cleanup
was performed only after exact retained artifact hashes matched the remote
checkpoint; repeat that preservation rule.

If shell push has no credential, use the connected GitHub Git-data tools:
create trees from the reviewed snapshot, create a commit with the current
branch head as parent, update only finish/02-photometry-color with expected_sha,
then fetch/check the remote ref and tree. An API-created commit may differ
in author metadata from a local preparatory commit; require identical trees.
Never force-update or overwrite another contributor's branch advancement.
