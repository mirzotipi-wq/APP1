# Independent review: absent-Continue query guard

**Scoped approval; no blocking source finding.** Candidate `UITests/StudioContentReachability.swift` SHA256: `b2153c08e683875d3a0ac929993e4a1abf87ca2b206c24abd9206235b91f2a64`, against base `6f3da3341f350084eac4a05b35a5bfd408d50193`.

Independently verified that the complete helper file equals the base after substituting only the predicate and its two explanatory comment lines. The candidate is:

```swift
(!proceed.exists || !proceed.isHittable) && typingKey.isHittable
```

It retains the Continue-first evaluation order, real q/Q hit-test, original 10-second waiter, call sites, text-entry/confirmation assertions, and failure-only diagnostic body. The positive `typingKey.exists` lookup remains removed.

Apple's [isHittable documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielement/ishittable.md) states that a missing element is not hittable and that a true value requires an element that can be interacted with. Its [exists documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielement/exists.md) separately cautions that existence does not establish hittability. Thus, for a consistent UI state, the old `!H && K` and new `(!E || !H) && K` accept identical states under the documented implication `H ⇒ E`. Swift's short-circuit expression avoids the Continue hit-point query when the existence query reports absence; it never substitutes key existence or geometry for the required key hit-test. These remain sequential observations of a changing UI, not an atomic snapshot of both conditions.

I read the actual [6f3 library job](https://github.com/mirzotipi-wq/APP1/actions/runs/45641483928/job/139303177809) failure excerpt preserved here as `6f3-keyboard-readiness-excerpts.log` (SHA256 `264c718aee051a0afc12211f006b7bf1ac6114da492ba49ad71ce7975ec853a6`). The predicate starts at elapsed 76.28s, performs two further Continue resolution attempts, and first looks up the typing key at 85.44s: approximately 9.16s later. The subsequent immutable diagnostic traversal visits 142 nodes without truncation; its selected-node output contains q at node 100, a normal frame, and enabled=true, plus the other letter rows. No Continue/introduction node is printed. **This does not measure q's hittability during the predicate and does not prove a ready state was missed.**

That trace supports testing the absence guard as a narrow query-behavior correction. It does not establish the exact internal XCTest cause or promise a faster/pass result. When Continue is present, the candidate still incurs the added existence lookup. The historical failed run remains failed. No new Swift syntax parse or Apple execution was performed after the executor reset; real CI compilation and execution remain required. No product assertion, test inventory, audit scope, deadline, or retry policy changes are part of this candidate.
