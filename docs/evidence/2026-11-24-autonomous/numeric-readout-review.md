# Independent numeric-readout follow-up review

## Decision

No demonstrated correctness blocker was found in the pending numeric-readout correction. Proceed with the lead's exact-source integration and retain native accessibility/layout verification as unresolved. This is a follow-up by the existing wave-ten document-parser reviewer, not an additional specialist or a native/device certification. No production source was changed, staged or committed by this reviewer.

Reviewed `StudioNumericInput.swift`, `PrecisionValueButton.swift`, `ExactNumericReadoutTests.swift` and [the correction report](numeric-readout-correction.md), against main `9724cc2` plus the pending correction.

## Correctness and editor behavior

The finite-value guard keeps nonfinite descriptions out of the decimal-expansion path. Decimal expansion starts from Swift's own round-trip text, preserves the sign (including negative zero), and predicts the complete length before inserting zero padding. Very small or large values retain scientific notation instead of becoming zero or allocating hundreds of digits. Exponent parsing and digit-array indexing consume that trusted Swift-generated ASCII representation, not raw imported text.

Localization maps the already selected digits/sign/decimal symbol without another floating-point rounding pass. The editor's decimal draft uses ASCII digits and a locale separator, and is accepted only after the unchanged strict parser returns an identical Double bit pattern. The one-character leading-zero omission is limited to the otherwise 33-character boundary allowed by the existing decimal grammar.

If no exact bounded draft exists, the native sheet displays the current scientific value, starts an empty replacement field and explains how to preserve or replace it. Source inspection confirms that unchanged Apply still closes without writing through the binding. Entering and then clearing a replacement also preserves the current value, matching the displayed instruction. A changed nonempty draft must pass the existing range/parser validation before any assignment. Cancel remains a dismissal. Scientific display does not enable exponent input or weaken the 32-character / 96-byte parser bound.

This verifies source logic and portable formatting. Actual VoiceOver pronunciation of `e` notation and bidirectional signs, Dynamic Type wrapping, keyboard behavior and sheet lifecycle require native execution.

## Independent execution

A standalone optimized probe freshly compiled the actual `StudioNumericInput.swift`, without SwiftPM or the shared build lane. On Swift 6.4.3 / Debian 13 x86_64:

- **13,507 finite readouts** across **1,039 locale identifiers** preserved identical Double bit patterns after canonicalizing locale symbols.
- **9,351 exact decimal drafts** parsed back identically within both original parser bounds.
- **4,156 unavailable drafts** returned nil explicitly rather than rounding a value into the field.
- The longest numeric readout was **34 characters**, including localized sign-control characters; no unit was counted in that measurement.
- **Zero round-trip, sign, draft-bound or precision mismatches.**

The identifiers combine this runtime's `Locale.availableIdentifiers` with explicit Arabic, Persian, Hebrew, French, Bengali, Nepali, Burmese and numbering-system variants. An identifier may fall back according to Foundation; this is not a promise that every custom numbering system has a distinct native presentation. Thirteen fixed values cover ±zero, fine ordinary decimals, the 32-character boundary, ±least subnormal and ±greatest finite values. These are parameter checks in a command-line probe, not 13,507 XCTest methods. The author and lead's XCTest runs are recorded separately.

## Measured helper cost

The probe warmed the helper, then measured seven samples of 1,000 deterministic calls per mode/locale using a monotonic clock, consuming output lengths in a checksum. The workload mixed ordinary, tiny and extreme finite values. Median elapsed microseconds per complete readout:

| Locale | Previous six-fraction formatter | Corrected exact helper |
| --- | ---: | ---: |
| `en_US_POSIX` | 1.755 µs | 23.348 µs |
| `fr_FR` | 2.849 µs | 23.598 µs |
| `ar_EG` | 3.070 µs | 15.940 µs |
| `fa_IR` | 1.915 µs | 15.475 µs |

The extra per-call work is measurable on this shared Linux host, consistent with deriving ten digit strings and a sign for each call. These timings do not show an iPhone frame-time failure or a device performance gate result. No caching, global mutable locale state or speculative optimization was introduced. Measure actual editor update frequency and device cost before changing that design.

## Evidence and reproduction

Executed compile command from the repository:

```sh
swiftc -O Sources/LightingCore/StudioNumericInput.swift \
  /workspace/scratch/73dcd6a65726/verification/numeric-readout-review/probe.swift \
  -o /workspace/scratch/73dcd6a65726/verification/numeric-readout-review/probe
```

The installed Swift 6.4.3 toolchain was first on PATH. The probe/result are at the paths above; hashes bind the reviewed source and actual output. The complete source is embedded below to preserve reproducibility. No optional testing followed this bounded probe.

- `StudioNumericInput.swift` SHA-256 `13a5fe865e9ea5226f4118123cc1b0f6cef3571dc5916a2d5fd16a0f6a4949be`.
- `PrecisionValueButton.swift` SHA-256 `721d08e1de410ea560ff99dd6c4d376d5bf5848e7cea273a70728150fee1b508`.
- `ExactNumericReadoutTests.swift` SHA-256 `0a50774c9c44f3f1c8c691089660a8294e3ca09322b748eb469695b7a0bcd99b`.
- `probe.swift` SHA-256 `61b4a0662d8d41d98494dfa6f4b266e2f27f8a37696be2fb0a1e54e01ca3c0d7`.
- `result.json` SHA-256 `8489f0414b48a5dc5c29cb24f83761ff2fb384be01d2e680161173baafba86a1`.

### Raw timing samples

```json
[
  {
    "callsPerSample": 1000,
    "locale": "en_US_POSIX",
    "medianMicroseconds": 1.754921,
    "microsecondsPerReadout": [
      1.948658,
      1.722273,
      1.603346,
      1.76057,
      1.742243,
      1.754921,
      1.781902
    ],
    "mode": "previousSixFractionDigits"
  },
  {
    "callsPerSample": 1000,
    "locale": "en_US_POSIX",
    "medianMicroseconds": 23.348419999999997,
    "microsecondsPerReadout": [
      15.000236000000001,
      14.690189,
      23.348419999999997,
      24.231437999999997,
      24.229345000000002,
      23.589236,
      22.952573
    ],
    "mode": "currentExactReadout"
  },
  {
    "callsPerSample": 1000,
    "locale": "fr_FR",
    "medianMicroseconds": 2.849062,
    "microsecondsPerReadout": [
      3.01504,
      2.803816,
      2.847962,
      2.7923299999999998,
      2.8964630000000002,
      2.856874,
      2.849062
    ],
    "mode": "previousSixFractionDigits"
  },
  {
    "callsPerSample": 1000,
    "locale": "fr_FR",
    "medianMicroseconds": 23.597989000000002,
    "microsecondsPerReadout": [
      23.241201,
      23.786929,
      23.437522,
      23.597989000000002,
      24.018974,
      24.599454,
      23.533474
    ],
    "mode": "currentExactReadout"
  },
  {
    "callsPerSample": 1000,
    "locale": "ar_EG",
    "medianMicroseconds": 3.070291,
    "microsecondsPerReadout": [
      3.232161,
      3.070291,
      3.143841,
      3.075599,
      2.6335390000000003,
      1.980686,
      1.823764
    ],
    "mode": "previousSixFractionDigits"
  },
  {
    "callsPerSample": 1000,
    "locale": "ar_EG",
    "medianMicroseconds": 15.939768,
    "microsecondsPerReadout": [
      14.953033999999999,
      15.539019,
      47.164633,
      22.398541,
      15.939768,
      18.242071,
      14.106962
    ],
    "mode": "currentExactReadout"
  },
  {
    "callsPerSample": 1000,
    "locale": "fa_IR",
    "medianMicroseconds": 1.915429,
    "microsecondsPerReadout": [
      1.873247,
      2.395,
      1.818245,
      1.761301,
      2.141795,
      1.9180730000000001,
      1.915429
    ],
    "mode": "previousSixFractionDigits"
  },
  {
    "callsPerSample": 1000,
    "locale": "fa_IR",
    "medianMicroseconds": 15.474817999999999,
    "microsecondsPerReadout": [
      14.9167,
      13.753648,
      15.474817999999999,
      13.960042999999999,
      23.776239,
      25.073065999999997,
      24.609579
    ],
    "mode": "currentExactReadout"
  }
]
```

### Complete probe source

```swift
import Foundation
import Dispatch

@main struct NumericReview {
    static func canonical(_ text: String, locale: Locale) -> String {
        var result = ""
        for character in text {
            if String(character) == locale.decimalSeparator { result += "." }
            else if character == "−" { result += "-" }
            else if let digit = character.wholeNumberValue, (0...9).contains(digit) { result += String(digit) }
            else if character.unicodeScalars.allSatisfy({ CharacterSet.controlCharacters.contains($0) }) { continue }
            else { result.append(character) }
        }
        return result
    }
    static func main() throws {
        let values: [Double] = [0,-0.0,1e-7,-1e-7,1.2345678901234567,-1.2345678901234567e-14,
            1e-29,-1e-29,1e30,Double.leastNonzeroMagnitude,-Double.leastNonzeroMagnitude,
            Double.greatestFiniteMagnitude,-Double.greatestFiniteMagnitude]
        var identifiers = Locale.availableIdentifiers.sorted()
        identifiers += ["ar_EG", "fa_IR", "he_IL", "en_US_POSIX", "fr_FR", "bn_BD", "ne_NP", "my_MM",
            "en-US-u-nu-fullwide", "en-US-u-nu-mathbold", "zh-Hant-u-nu-hanidec", "en-US-u-nu-roman", "he-u-nu-hebr"]
        identifiers = Array(Set(identifiers)).sorted()
        var checked = 0, drafts = 0, unavailableDrafts = 0, longest = 0
        var mismatches: [[String:String]] = []
        for identifier in identifiers {
            let locale = Locale(identifier: identifier)
            for value in values {
                let text = StudioNumericInput.formattedValue(value, locale: locale)
                longest = max(longest,text.count)
                let restored = Double(canonical(text,locale:locale))
                if restored?.bitPattern != value.bitPattern {
                    mismatches.append(["locale":identifier,"source":String(value),"text":text,"canonical":canonical(text,locale:locale)])
                }
                if let draft = StudioNumericInput.editableText(value,decimalSeparator:locale.decimalSeparator ?? ".") {
                    drafts += 1
                    let parsed = StudioNumericInput.parse(draft,decimalSeparator:locale.decimalSeparator ?? ".",
                        in: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude)
                    if parsed?.bitPattern != value.bitPattern || draft.count > 32 || draft.utf8.count > 96 {
                        mismatches.append(["locale":identifier,"source":String(value),"draft":draft])
                    }
                } else { unavailableDrafts += 1 }
                checked += 1
            }
        }
        let timingValues: [Double] = [0,-0.0,1e-7,-1e-7,1.23456789,-73.123456789,100000,1e-29,
            -1.2345678901234567e-14,Double.leastNonzeroMagnitude,Double.greatestFiniteMagnitude]
        var timings: [[String:Any]] = [], checksum = 0
        for identifier in ["en_US_POSIX","fr_FR","ar_EG","fa_IR"] {
            let locale = Locale(identifier:identifier)
            for index in 0..<100 { checksum &+= StudioNumericInput.formattedValue(timingValues[index % timingValues.count],unit:"m",locale:locale).utf8.count }
            for mode in ["previousSixFractionDigits","currentExactReadout"] {
                var samples: [Double] = []
                for _ in 0..<7 {
                    let start = DispatchTime.now().uptimeNanoseconds
                    for index in 0..<1000 {
                        let value = timingValues[index % timingValues.count]
                        let text: String
                        if mode == "currentExactReadout" { text = StudioNumericInput.formattedValue(value,unit:"m",locale:locale) }
                        else { text = value.formatted(.number.precision(.fractionLength(0...6)).grouping(.never).locale(locale)) + " m" }
                        checksum &+= text.utf8.count
                    }
                    samples.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1000 / 1000)
                }
                timings.append(["locale":identifier,"mode":mode,"callsPerSample":1000,"microsecondsPerReadout":samples,
                    "medianMicroseconds":samples.sorted()[samples.count/2]])
            }
        }
        let result: [String:Any] = ["locales":identifiers.count,"finiteReadouts":checked,"exactDrafts":drafts,
            "explicitUnavailableDrafts":unavailableDrafts,"maximumReadoutCharacters":longest,"mismatches":mismatches,
            "timings":timings,"checksum":checksum]
        print(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]),as:UTF8.self))
    }
}
```
