# W01R05 — concurrency review

Revision: `f150f98e35dd735927075aac4d2f8b02295c6a67`. Source-only; no demonstrated race in the reviewed path. Read AGENTS, operating protocol, quality and architecture; broad startup/baseline belong to the root worker.

## State inventory

Paths below are under `Sources/LightingCore/`.

- `SurfacePhotometry.swift:4–49,66–79,134–197`: direction/rectangle fields are immutable Sendable values; the sole file-global quadrature table is `let` with value elements. Polygon and accumulation mutations are invocation-local.
- `Colorimetry.swift:4–8,24–48,54–66,99–139,146–164`: settings are mutable value structs; range constants, output values, and prepared transform fields are immutable. Spectral sums and gamut calculations mutate locals only; no cache.
- `StudioOptics.swift:18–47,53–94,99–138`: optics are mutable Sendable values, range constants and emitter frame are immutable; accessors and photometry functions only read inputs.
- `LightOutputAdjustment.swift:32–95`: `adjusted` and `maximum` copy `source`; only their candela changes. `Scene.swift:3–28,44–80` declares nested scene/light/position values Sendable and validates by returning a local migrated copy. This is value isolation, not synchronization of an externally shared mutable variable.
- `ReferenceStudy.swift:204–265,302–369`: prepared samples/guards/grid and each element are `let`, Sendable values; evaluation sums are local. Clipped sampling's temporary pointers remain inside one synchronous allocation/callback (`120–197`); no storage escapes.

## Consumer conclusion

Concrete chain: `ReferenceStudyRenderer.render` → `StudySetup` → `StudyLighting` → `PreviewColorimetry.blackbody` / `StudioPhotometry.frame`, then per-pixel `evaluate` → `PreviewColorTransform.display` (`ReferenceStudy.swift:438–459,481–533`). Setup derives camera, geometry, samples, and transform from the same by-value scene before rendering. Camera fields are immutable (`CameraFraming.swift:35–44`). Pixel/mask buffers belong to the invocation; returned image fields are immutable Data values (`ReferenceStudy.swift:375–390`). Separate correctly isolated input copies therefore cannot mix scene revisions through these helpers. UI publication ordering is outside this bounded review.

Cancellation callback is synchronous and nonescaping; renderer does not dispatch it. Counter checks precede pixel groups of eight and completion (`462–476,498,531`). Setup and one pixel's sample traversal are not interruptible. A request just after a check can allow eight more pixels; no wall-time claim follows. Caller must supply a concurrency-safe cancellation signal. No unsafe callback capture was demonstrated in this consumer.

## Evidence and limits

Ran `pwd`, `rg`, `cat`, `nl`/`sed`, `git status --short`, `git rev-parse HEAD`, and `git diff --stat`; exact inspection commands and unsuccessful path guesses are in `private-output/commands.txt`. Initial status/diff were clean. No build, tests, toolchain, installation, network, source edits, commits, or pushes. Runtime concurrency, stale UI publication, and timing remain unverified.

Artifacts: `private-output/report.md`, `private-output/commands.txt`.
