# Exact bounded numeric readouts and imported-value drafts

## Reproduced defect

The independent [product/accessibility review](product-accessibility-review.md) found that the current numeric-control and slider accessibility helper rounded every value to six fractional digits. Source baseline: `0d63dd872bbd20aaa72f9263b51e2208b6ee926f` on main. Stored Doubles and the strict decimal parser were intact, but accepted `0.0000001` and `-0.0000001` were presented as `0 m` and `-0 m`. A new focused XCTest reproduced **four failing assertions in one test** before the correction: those two tiny values, `1.23456789`, and `73.123456789`.

This is numerical presentation integrity, not a claim of achievable physical placement accuracy. The original unrounded value remains the source of truth.

## Correction and explicit notation policy

`StudioNumericInput.formattedValue` now starts with Swift's round-trip `Double` textual representation. Apple's [Double.description documentation](https://developer.apple.com/documentation/swift/double/description), checked on 2026-11-24, guarantees that finite values can be converted back without a rounding error. The implementation expands the decimal exponent only when the result fits **32 ASCII decimal characters**. Otherwise it retains the bounded scientific notation using `e`, preserving the exact digits, exponent and sign. It checks the predicted length before allocating zero padding, so a subnormal cannot create a hundreds-of-digits label.

Locale-specific decimal symbols, digit glyphs and signs are applied to that exact text; no second floating-point formatting pass rounds it. Integers used to obtain the digit glyphs are formatted through Foundation's integer style. Grouping is never introduced. Existing ordinary English, French, Persian and Arabic presentation remains covered. Scientific notation is a display policy only: the input parser still rejects exponents and grouping and retains its original 32-character / 96-byte bounds and domain validation.

The new `editableText` helper returns an exact decimal draft with ASCII digits and the user's decimal separator, or nil if it cannot fit and round-trip. At the boundary, the existing grammar's `.125` form can save one leading-zero character for an otherwise 33-character draft. Every returned draft is checked through the existing parser and compared by Double bit pattern, including negative zero.

`PrecisionValueEditor` uses that draft instead of the former twelve-fractional-digit rounding. When an imported value has no bounded decimal draft, the sheet shows its actual scientific value and explains: leave the replacement field empty to preserve it, or enter a new decimal value. The field starts empty. The existing unchanged-Apply guard preserves the imported value, and Cancel remains unchanged. No exponent parser, range change, slider snapping, stored-value mutation or persistence API change was added.

Nonfinite values are not valid scene data; the readout defensively presents Unavailable and `editableText` returns nil.

## Executed verification

Environment: Swift 6.4.3, Debian 13 x86_64. The worker used the isolated `verification/numeric-readout-build` scratch path; the integration lead's exact-source build lane was not used.

- Before: **1 test, 4 assertion failures**, proving the six-digit readout defect.
- After: **17/17 targeted Debug tests and 17/17 targeted Release tests passed**, zero failures. This includes all seven existing parser/scene numeric tests, all four existing accessibility-value tests and **six new readout/draft regressions**.
- The existing test that expected `73.123457 mm` for `73.123456789` was strengthened to require `73.123456789 mm`; its unchanged-scene and no-grouping assertions remain.
- New cases cover accepted fine decimals, four locales, positive and negative zero, least positive subnormal and its negative, least normal magnitude, greatest finite magnitude, exact 32-character draft boundaries, unavailable drafts, unchanged encoded scene bytes and continued rejection of scientific/grouped/overlong input.
- **512 deterministic bit-pattern candidates** were generated, of which **512 were finite**; nonfinite candidates are excluded explicitly. Every finite candidate is checked for an identical round-trip bit pattern and a bounded numeric label. These are parameter cases within one XCTest method, not 512 separate XCTest tests.
- `swiftc -frontend -parse App/PrecisionValueButton.swift` passed.
- Owned source/test whitespace checks passed.

Exact commands:

```sh
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/numeric-readout-build --jobs 2 --filter ExactNumericReadoutTests.testAcceptedFineDecimalsRetainTheirActualReadout
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/numeric-readout-build --jobs 2 --filter 'ExactNumericReadoutTests|StudioAccessibleValueTests|StudioNumericInputTests'
swift test --scratch-path /workspace/scratch/73dcd6a65726/verification/numeric-readout-build --configuration release --jobs 2 --filter 'ExactNumericReadoutTests|StudioAccessibleValueTests|StudioNumericInputTests'
swiftc -frontend -parse App/PrecisionValueButton.swift
```

The commands used the installed Swift toolchain directory `/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin` at the front of PATH. Raw host timestamps differ from the connector clock and are preserved without rewriting.

## Limits and next verification

The full exact-source integration suite belongs to the integration lead. Native syntax parsing does not establish Apple SDK type checking, actual sheet layout, keyboard behavior or VoiceOver pronunciation of scientific notation. Those current native/device observations remain required. No accessibility, editing, native-build or release gate is promoted by this focused packet. The bounded precise readout is not a physical accuracy or calibration claim.

## Source hashes

| File | SHA-256 |
| --- | --- |
| `Sources/LightingCore/StudioNumericInput.swift` | `13a5fe865e9ea5226f4118123cc1b0f6cef3571dc5916a2d5fd16a0f6a4949be` |
| `App/PrecisionValueButton.swift` | `721d08e1de410ea560ff99dd6c4d376d5bf5848e7cea273a70728150fee1b508` |
| `Tests/LightingCoreTests/StudioAccessibleValueTests.swift` | `9dced17343935033b47088297c029e494cd9a3b1b05a09b935c7dbb1f348e590` |
| `Tests/LightingCoreTests/ExactNumericReadoutTests.swift` | `0a50774c9c44f3f1c8c691089660a8294e3ca09322b748eb469695b7a0bcd99b` |

## Raw evidence hashes

- `numeric-readout-before.log`: `571e6af54dff0701a7c47894436b0c93faf3e17c8842dc314b92a46189b95b89`.
- `numeric-readout-after-debug.log`: `acaca9dc82507e4367c0e8e97d7b5c738056c1e2b130a274060dc94b3f701a78`.
- `numeric-readout-after-release.log`: `15dfe2910e24b9297457c5835e5e1902d5b5a1989d878e7b01785c74728b7a1b`.
