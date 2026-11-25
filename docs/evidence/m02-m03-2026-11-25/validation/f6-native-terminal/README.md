# f6 native terminal evidence

Run 45604744523; simulator job 139182923426; tested revision f6f43dde19be7a554bc5c6924e3239c18b34d1be.

`terminal-excerpts.log` contains 151 exact, ordered selected lines from the decoded GitHub terminal log. It is intentionally an excerpt, not the complete job log. It includes all 110 native pass outcomes, all three required Metal pass lines, six parity metric rows, build commands/success markers, suite totals and selected provenance/artifact lines. `terminal-summary.json` is a derived parsing receipt; `terminal-job.json` and artifact metadata preserve connector responses for this job and selected artifacts.

`source-and-attachment-verification.json` records empty source comparisons from b298 to f6 and f6 to a1ef for App, Sources, NativeTests, UITests and project.yml; it also confirms that all 110 source-declared native methods appear in the actual outcome set. The source identity remains f6, not a claim that the replacement workflow already completed.

The compact artifact was downloaded and verified against its GitHub digest and ZIP CRC. Its inventory and unchanged XCTest attachment manifest are included, while its six PDF binaries and ZIP are retained only in the owned temporary evidence directory. That manifest is attachment provenance, not a separate test-count receipt. The full native/build archive and both application archives were inventoried through GitHub metadata, not downloaded or independently rehashed by this worker.

`copy-manifest.json` records exact copied-file hashes plus a hash, byte count and line count for the complete decoded terminal log retained outside the repository. No complete job log, application archive, PDF binary or unrelated artifact is copied here. The complete decoded log digest describes decoded UTF-8 text returned by the GitHub connector, not the underlying compressed server archive.

See ../../followups/followup-f6-native-terminal.md for findings and scope.
