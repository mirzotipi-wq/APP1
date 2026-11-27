# W08-04 configuration documentation

Committed **4cb6824ca7adac6c2706c9cb1a73a814dd4fd647**, changing only `docs/parallel/01/CONFIGURATION.md`. The document maps exact SwiftPM inclusion/exclusion, native target/resource membership, reproducible commands and evidence limits.

Verified all 179 expanded-manifest hashes against frozen HEAD Git bytes: zero mismatches. The earlier 175-input scope already included assets/Metal/headers; it omitted the privacy resource. The expanded scope adds that resource, two workflows and the shard selector, but excludes other CI helpers. Sparse resource absence is not a repository defect.

Root receipts at `7bdea15c771d7dfeeb3f20d011b3c02e4bc5b34f` show package dump/describe exit 0 and Debug **431 tests, zero failures**. Original Release failed during compilation with signal 9; cause remains unproven. A separate compiler-mode retry is pending. XcodeGen, Apple typecheck and native/UI execution remain unverified. Source inventory is 189 native methods, 36 required UI methods and two diagnostics.

Startup state checks and committed-diff whitespace check passed. This worker ran no builds, tests or pushes. Git status is clean. `receipt.json` and `source.patch` preserve commands, hashes, limits and the patch. The three Void producer limitations remain unchanged.
