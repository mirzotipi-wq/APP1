# W01R06 resource bound review

Revision: f150f98e35dd735927075aac4d2f8b02295c6a67 (provided baseline).

**Bounded; no demonstrated resource defect in this scope.**

`SurfacePhotometry.swift:120–146` starts with four ordered rectangle corners and clips against one affine half-plane. There are at most two strict-sign edge crossings; at most three original corners survive on the partial branch. Zero-incidence endpoints are appended once and generate no crossing duplicates. Therefore polygon count ≤5; `reserveCapacity(5)` alone is not the proof.

The triangle fan (`151–172`) has ≤3 triangles. Each nondegenerate triangle executes 12×12=144 quadrature iterations, so partial evaluation ≤432 samples. Full evaluation (`182–195`) executes exactly 32×32=1,024 samples. Early returns and degenerate triangles reduce work.

`Scene.swift:64` rejects >12 lights. Evaluating every rectangle once in a validated scene therefore requires ≤12,288 full-path samples, or ≤5,184 when all take the partial path.

Source-level storage: four corner elements, four incidence elements, ≤5 polygon elements, and one fixed global 12-pair quadrature table. Per-call scalar/vector temporaries and arrays are local; no sample-result array, cache, recursion, asynchronous task, or growing retained state appears here. These are logical element bounds, not measured allocator bytes.

Commands run: `pwd && rg --files -g 'AGENTS.md' -g '*SurfacePhotometry*' -g '*Scene*' -g '*PROTOCOL*' -g '*QUALITY*' -g '*ARCHITECT*' -g '*protocol*' -g '*quality*' -g '*architecture*'`; `cat AGENTS.md agents/OPERATING_PROTOCOL.md docs/QUALITY.md docs/ARCHITECTURE.md && nl -ba Sources/LightingCore/SurfacePhotometry.swift && rg -n -C 4 'maximum.*[Ll]ight|max.*[Ll]ight|12|light.*count' Sources/LightingCore/Scene.swift Sources/LightingCore/SceneLightCreation.swift`.

Limits: static review only; no builds/tests/timings/device-performance claims. Colorimetry, repeated adjustment evaluations, and Study excluded by tightened scope. Source unchanged.
