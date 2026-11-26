# Worker021 — wave3 acceptance freeze

Input: `c76e176fa60d29f8ebd49845d7e8ea883c11b64f`. Actual context `/root/w021`; report/ledger only.

## Frozen acceptance

- Keep CPU Double oracle, six parity fixtures, eight precision cases, packed ABI, UI, CI, cache limits and existing tests unchanged. Exact invalid-mask parity, mean RGB error <=1, fraction(error>4) <=0.005 and strict precision maximum <=1 remain requirements.
- Add width-specific eligibility for valid widths 24...192 divisible by3; preserve legacy one-argument forwarding to192. Both engine predicate and direct production Metal render must use the actual width. Reject invalid dimensions before derived arithmetic.
- Align eligibility with StudySetup camera clearance, ignore zero-output emitters only for the relative-distance restriction, and retain scene validation, near-field and panel-frustum checks.
- Use the declared 32*Float.ulpOfOne*distance shell and floor(pixelCount/510) permitted geometric pixel budget, with O(height) interval union and correct odd-width center handling. This reserves at most0.5 mean-channel error and less than half the0.005 outlier fraction for hypothetical worst-case shell changes; it is an engineering routing heuristic, not a universal GPU, strict-maximum or mask-parity proof.
- CPU-only or invalid sphere requests must bypass unchecked Metal initialization without selecting CPU permanently. Later eligible work must retain the opportunity for validation/Metal. Preserve fixture bypass, cache behavior, scene errors, cancellation and existing catch order. Valid scenes with invalid width must retain invalidResolution.
- Add exact width24/focal161.27198111190464 no-light regression; returned CPU frame equals the shipped ReferenceStudyRenderer. Core tests must assert oracle pixels(9,0)/(14,0) are black, cover invalid widths/cameras, disabled far emitters, odd widths and width-specific routing. Preserve three existing actual-Metal methods and all tolerances.

## Evidence status

Read AGENTS, fixed lane acceptance/owner requests and narrow renderer, eligibility, core/native tests at clean baseline. Nine fresh children will be recorded only after actual creation; source writers023/024 were created first. No Swift build, native test, actual Metal execution or injected-failure lifecycle test was run by worker021. Integration/builds remain exclusively coordinator-owned. Final wave outcomes and durable blob map will be added after focused independent review.
