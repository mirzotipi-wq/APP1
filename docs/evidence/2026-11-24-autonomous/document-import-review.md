# Editable document adversarial review

The independent document specialist added six regressions, integrated in source `0fce248b4e61bace88002b40f6c56fddedb19c8a`. The exact source tree passed 212/212 portable tests in both Debug and Release. The targeted six-test Debug log is retained here; Apple provider/UI execution remains separate.

## Exercised preservation boundaries

Raw numeric overflow, nonfinite tokens and out-of-range coordinates cannot become scene values. Schema values must represent the supported integer; valid JSON number spellings such as `1.0` remain acceptable. Invalid UTF-8, lone surrogate escapes, prohibited null characters and extra JSON roots fail, while a valid escaped surrogate pair is retained.

A decoded copy cannot replace another window's newer save. The rejected transaction leaves stored bytes unchanged, and a reload permits importing a fresh project identity without losing the competing changes. A full 64-record library rejects import even when one record is archived. An individually valid approximately 4.2 MB document cannot make a combined library exceed its separate 8 MiB bound; failed encoding preserves the original file bytes.

## Residual duplicate-key ambiguity

A standalone probe against the actual LightingProjectDocument implementation on Swift 6.4.3 found first-wins behavior for duplicate envelope keys:

- `schemaVersion: 1` followed by `schemaVersion: 2` is accepted as version 1.
- The reversed order is rejected as unsupported.
- Duplicate names `First` then `Last` decode as `First`.

The current keyed decoder cannot detect this using its set of keys. Canonical exports have unique keys, successful import still creates a new project, and scenes remain validated and bounded. This is a residual interchange-format ambiguity, not demonstrated overwrite or data loss. No custom parser was introduced and first-wins behavior was not made a supported contract. Any future strict duplicate rejection should handle escaped keys and strings without an ad hoc regex, preserve supported valid JSON encodings and retain all current import protections.

## Opened-file validation

Reference-photo reading previously checked pathname metadata before opening. A source-confirmed replacement race could change what was opened. The shared BoundedFileReader now validates the opened regular-file descriptor and bounds bytes even if the file grows. The project caller retains security scope and NSFileCoordinator around that helper. An isolated Linux adaptation changed only Darwin imports/qualifiers to Glibc and passed nine real filesystem tests; this is explicitly not native Apple verification. Tests cover symlink/FIFO/directory rejection, path replacement, inode retention, growth and cancellation. See `bounded-reader-posix.log`.

Raw logs are preserved beside this report. No user photographs, external uploads or system-provider success are part of this evidence.
