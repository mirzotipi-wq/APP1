# W43 API — tiny-emitter contract review

- Source: `c9ff1a71c173774e7b7c794e475f8bdf5d633853`; detached tree `/tmp/keyfill03-7f4b/workers/W43-api`, verified HEAD and clean status.
- Result: **conditionally compatible**. A private output scale need not alter the public API or packed-row contract. This is source/arithmetic evidence, not a Swift test pass.
- Read the four assigned instruction/acceptance files, ReferenceStudy.swift, Scene.swift, StudyFloat32Eligibility.swift, and all StudyFloat32EligibilityTests.swift.

## Required constraints

1. Preserve scene validation before activity filtering. Scene.swift:33–36 accepts every finite nonnegative candela through 100,000, including positive subnormals; malformed zero-output lights still fail structural validation. Preserve `originalCandela > 0` (ReferenceStudy.swift:236) as activity. Positive tiny output requires its frame and guards; zero/negative-zero creates neither. Never infer activity from a divided or Float-packed value.
2. Define the narrow trigger on **Double** per-sample candela: positive original output AND (per-sample value is subnormal OR rounds to zero). Use normalized candela 1 for point/directional or 1/N for rectangles, outputScale = original candela. Ordinary samples retain their current path and accumulation order. Float underflow alone must not broaden this trigger.
3. Each normalized emitter needs separate unoccluded-lux, visible-lux and material/visibility-adjusted XYZ accumulators; scale each completed quantity once, then add it to scene totals. Do not scale global totals, recover groups by subtracting global totals, or reassociate ordinary contributions. Every sample in an area shares the scale.
4. Preserve unconditional area guards before shortcuts (ReferenceStudy.swift:301), sample-distance rejection before incidence/emission/occlusion (304–328), sample positions/order, clipping, and existing backface behavior. Tiny positive light can produce zero representable XYZ and still invalidate a near receiver.
5. Pack `Double(normalizedCandela * outputScale)` before Float conversion. Preserve six parameter rows, three rows/sample, three rows/area, one-based area index, and area count (272–283, 411–435). CPU rectangles remain 64/1024 samples; StudyComputeInput remains interactive/64. Never omit zero-packed samples or guards.
6. Leave StudyFloat32Eligibility unchanged: activity uses original positive Double (line 22); its 20 m precondition includes *all* lights (line 17), even inactive ones. Existing inactive invalid-aim exemption remains; tiny positive invalid aim remains invalid. No eligibility threshold or ABI field is needed.

## Actual checks and limits

57 JavaScript binary64/binary32 edge cases (N=1/64/1024, minimum subnormal, division ties, least-normal trigger boundaries, 1e-40, 900) preserved both baseline Double packed intensity and Float value. For a 0.1 m square at 0.1 m, minimum-positive candela yielded old lux 0 but normalized-group positive lux for grids 8/32. A copied area-guard predicate at 0.049 m rejected positive tiny output despite packed Float0; zero produced no guard. This demonstrates the failure of Float-based activity, not execution of the Swift API.

Evidence: `docs/parallel/03/workers/wave05-evidence/W43-api-arithmetic.js` and `W43-api-arithmetic.json`. The saved JS is runnable with Node. No Swift/build, production edits, commit, push, or cleanup. A read-only rg additionally named two nonexistent presumed kernel filenames; no kernel conclusion depends on them.

Root follow-up: run Swift regressions for tiny/zero/invalid-aim point, directional and rectangle emitters; both rectangle qualities; near masks despite packed Float0; row/count equality; unchanged eligibility and ordinary fixture bytes.
