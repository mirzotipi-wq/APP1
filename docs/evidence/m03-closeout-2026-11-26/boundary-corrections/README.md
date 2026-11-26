# Boundary corrections found during the 100-worker review

These corrections build on `02797d359f699a90e72c7629d3dba2ba7de04b95` (the intervening `df7c3b7` commit changes documentation only). They are M02/M03 code work, with Apple execution still required on their integrated source.

## Findings and corrections

1. **Exact native text must reach bounded validation.** Swift strings can compare equal despite different UTF-16/scalar representations. An 80-character composed name uses 320 scalars; its canonically equivalent decomposed paste uses 400. All five native text synchronization comparisons now use exact UTF-16 equality. The caller receives the paste, rejects it, restores the accepted text and prior selection, and keeps submission blocked. Two native regressions also cover canonical-equivalent external resets and identity changes. These are native test source; a Linux parse is not a UIKit execution.
2. **A scalar budget must not publish a partial grapheme.** Leading whitespace followed by repeated joined family emoji exposed a partial final emoji after the display prefix was truncated and then trimmed. The bounded display drops the final uncertain grapheme when scalar truncation occurs, before trimming. It still inspects at most 321 source scalars and preserves stored project names. The new test checks seven leading-space offsets and all three layout budgets.
3. **An already achieved target does not need an inverse solve.** A subnormal illuminance exactly produced by the current source was rejected after independently rounded inverse division and forward integration. The solver now retains that exact source after all source, scene, unit-response and maximum-range validation. Zero, unsupported geometry, maximum range and the existing `1e-9` accuracy requirement are unchanged. This is a core/import edge; the decimal UI grammar cannot directly enter the reproducing subnormal target.
4. **Returning a slider to its starting value must preserve redo.** Nil preview/lens defaults and nil softbox rotation became explicit defaults after an out-and-back gesture. Synthesized scene equality then treated the visually unchanged scene as a new edit. An active-history helper restores the original optional representation only when effective values match. The three production settings bindings use it. Light matching uses UUIDs; manual aim remains distinct from following the subject. The helper preserves unrelated changes and stops restoring representations when its transaction ends or resets.
5. **Invisible name edges must not defeat row identities.** Accepted names such as `Studio` and `Studio ` followed by a zero-width joiner received no visible ID distinction. Removing the ignorable character exposed a trailing blank in the comparison key. Comparison keys now trim their edges after removing those characters. Displayed and stored scalars remain unchanged; affected rows and deletion confirmations receive distinct project IDs. The new five-name regression failed against the preceding exact presentation implementation before the correction.

## Executed local evidence

| Check | Actual result | Evidence |
|---|---|---|
| New emoji and subnormal regressions against preceding production source | Both tests failed as expected | `regressions-before.log` |
| Same two regressions after correction | 2/2 passed | `regressions-after.log` |
| Portable Debug suite, Swift 6.2.1 / Linux | 365/365 passed | `core-debug.log` |
| Portable Release suite, Swift 6.2.1 / Linux | 365/365 passed | `core-release.log` |
| Actual `StudioSliderTrackingTests`, compiled with production adapters and `LightingCore` on Linux | 19/19 passed, including eight nil/explicit-default out-and-back cases inside the new method | `slider-tracking-linux.log` |
| Final focused history suite with isolated manual-aim assertion | 19/19 passed | `history-debug-final.log` |
| Exact production row presentation with actual `ProjectLibraryPresentationTests`, compiled on Linux | New case failed before correction; all 9 methods passed afterward | `presentation-before.log`, `presentation-after.log` |
| Python tooling suite | 92/92 passed | `python-tooling.log` |

The final manual-aim-only negative assertion was added after the full Debug execution and passed in the subsequent focused history execution; the full Release suite includes it. The integrated CI reruns the complete suites. No Linux result here claims an Apple runtime, Metal execution, screenshot review or platform audit.

Required inventory after the changes is **154 native methods and 35 required UI methods**, plus the separately available two platform diagnostic methods. The 24 original Default/AXXXL screenshots remain required. No requirement, selected method or tolerance was removed to accept these corrections.

## Integrated followup

Source`9faebc5` also includes the cardinal room, camera/contrast and CI corrections described in the parent packet. Final local execution is 366 Debug/366 Release/100 tooling; required original screenshots increase from 24 to 26 by adding Camera selection at both sizes. The earlier counts andlogs above remain historical observations.
