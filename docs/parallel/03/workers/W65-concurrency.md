# W65 — concurrency review

**Status:** Source inspection complete; no concrete interface or ordering incompatibility found. No change proposed.

**Identity:** Wave 7 concurrency specialist; actual runtime ID `/root/wave07/w65_concurrency`; input `36ed6a1455dee7ca52b55f46d1a47262f5c98cc1`; clean detached tree `/tmp/keyfill03-7f4b/workers/W65-concurrency`. Assignment: reconcile preview adoption/pre-cancelled begin with latest pinned lane04 engine/cache ownership.

**Sources:** Preview blob `c96d5cb7a41143867efca160b309d71bfa993c96`; lane04 engine at `88279ba0ee0262ea6c880580c8a85b56342abbff`, blob `6f72a920bc8e14438997b07c6b45545c077509dc`. Full SHA256s, test/request blobs and verified W67 receipts are in `wave07-evidence/W65-concurrency.json`.

- Pre-cancelled `begin()` leaves the live ticket intact. The view task rejects cancellation before generation/frame mutation. `load` checks generation/cancellation before rendering, after await and after conversion; cancellation errors stay silent. These cooperative checks establish no claim of atomic cancellation against every scheduler interleaving.
- A → B → A calls `begin` before completed-A reuse, invalidating B. Image/error/backend fields publish together from one captured snapshot. The view permits a prior image only for the same subject; errors require exact request equality, and obsolete images hide backend/warning metadata. Inactive pending/previous states use static paused text.
- The engine interface remains compatible. Validated cache keys include subject and effective width; cancellation is checked before hit promotion. Preview guards also cover a cancellation arriving after engine return. Backend failure selects CPU and removes cached Metal frames; scene errors/cancellation do not constitute backend failure. A retained frame's badge describes its rendering provenance, not a promise about subsequent engine state.

**Actually executed:** Read the four required directives, relevant sources, ten test assertions and retained logs; checked detached HEAD/clean status; computed hashes and compared receipts. Existing root ten-test Linux pass has byte-identical preview/test sources; it was not rerun here. The historical nine-test receipt is distinct.

**Limits:** No builds, tests, native/SwiftUI scheduling, Metal, layout or physical execution. Width24 runtime verification remains lane04's; name-only canonicalization remains deferred. No source/test/script changes, commits, ref updates or external messages. No new runtime outage; one wrong-path lookup and one truncated search were corrected. Working-token/checkpoint counter unavailable.
