# W02R06 — host resources and bounded sweep work

Input: frozen LightingCore v1, `f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b`; debug Swift 6.0.3; Linux x86_64. Both inspected source files matched snapshot SHA-256 provenance.

**Executed:** required helper once, then its private executable once. Each execution made exactly 100 ordinary full-rectangle calls (102,400 midpoint cells), without warmup: emitter center (0,0,0), right +X, up +Y, size 1×0.6 m, intensity 1,000 cd; receiver (0,0,2) m, normal −Z. Both exited 0; last result 236.68465346184644 lux; checksum 23668.46534618463.

`/usr/bin/time` was unavailable; retained `measure.py` uses Linux `wait4` and monotonic launch-to-reap timing.

| Measurement | Wall | Peak RSS |
|---|---:|---:|
| Helper compile+run | 717.149 ms | 130,128 KiB |
| Standalone runtime | 34.183 ms | 16,268 KiB |

Standalone loop: 24.832474 ms; user/system CPU: 26.304/7.565 ms. Runtime includes process startup/exit; helper RSS is the wait4 high-water statistic including waited descendants, not simultaneous aggregate memory.

**Source bound:** `SurfacePhotometry.swift:196–209` fixes full integration at 32×32=1,024 cells. Clipping four corners by one half-plane produces ≤5 vertices, hence ≤3 fan triangles ×12×12=432 evaluations (134–186). Tiny-intensity recursion substitutes 1 cd before integration (118–125): at most one recursive entry, stack depth two, integration count unchanged. Scratch geometry is bounded independently of sweep size.

For S fixtures, one evaluation per light, F full and P partial rectangles: Q≤1,024F+432P≤1,024ΣLᵢ. **Scene.swift:64 validates 12 lights, not three**, so Q≤12,288S for validated scenes. This bounds photometric sample work only; no sweep or wall-time extrapolation was performed.

Evidence: `probe.swift`, `measure.py`, `commands.txt`, `measurements.json`, raw logs, copied sources and provenance. No production edits. Host diagnostics establish neither device performance nor physical calibration.
