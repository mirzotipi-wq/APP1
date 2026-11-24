# Independent document-envelope parser review

## Decision

The pending KF-031 correction is suitable for integration with the lead's complete exact-source verification. No demonstrated defect was found in the root-key scan or its encoding adaptation. This review does not certify a native Files provider, storage responsiveness, physical device or release gate.

Reviewed base: main `0d63dd872bbd20aaa72f9263b51e2208b6ee926f` plus the uncommitted document-key packet. The reviewed production file has SHA-256 `54834f5dd469bcccd7683ac49a95c4efa8b73de20960bdd0fd17f283b505b478`; the author's test file has SHA-256 `b5001328927bf361cfae2da14338eabef7fcd1ec73605205119c603a82f38800`. Only this review report was written in the repository by this reviewer. No staging, commits or production changes were performed.

## Source reasoning

The existing byte-limit check, version/closed-envelope decoder and scene/name validation remain intact. The additional scan rejects repeated root keys, including distinct JSON escape spellings that decode to the same name. It does not adopt or modify a library, choose a duplicate winner, or change canonical export encoding.

A JSON string is skipped as one lexical unit, with each backslash advancing over the escaped byte. Braces, brackets and commas inside that string cannot change depth or root-key state. Both object and array containers contribute to the same nesting depth. At depth one, only the string after an object opening or comma is interpreted as a key. Key escape interpretation is delegated to Foundation's string decoder. Full value decoding, field validity and supported encodings remain Foundation's responsibility.

The encoding sniff is valid for this already-decoded root-object domain: its first structural or whitespace character is ASCII, making UTF-16/32 byte order distinguishable by the first four bytes. Explicit BOM cases are checked first; UTF-8 stays on the original-byte path. A retained or stripped BOM cannot introduce structural ASCII punctuation. The helper therefore does not need a custom Unicode decoder or a second JSON value parser.

Work is bounded by the existing 8 MiB wire limit. The scan is iterative and linear in the transcoded input size, with no recursive container stack. UTF-16/32 conversion and the byte array add bounded memory; UTF-16 can expand into UTF-8 for some characters, so the wire byte cap must not be described as an 8 MiB peak-memory cap. Closed-envelope decoding limits valid root names to the three known fields; repeated names are rejected as soon as observed. The scanner returns when the original root closes; large trailing whitespace was already handled by Foundation and need not be scanned again. This is a complexity review, not a measured device memory/latency result.

## Independently executed adversarial sweep

Swift 6.4.3, Debian 13 x86_64, optimized standalone probes. The first probe linked the author's actual Release core objects. The final probe compiled a fresh copy of the exact reviewed document source, with only `import LightingCore` prepended to resolve its unchanged domain dependencies; the local type takes precedence over the imported module's document type. Both result files were byte-identical. Counts below refer to one sweep, not the sum of repeated executions.

| Check | Actual result |
| --- | ---: |
| Unique envelope inputs accepted by the Foundation/domain baseline | 1,152 retained equal values and canonical bytes |
| Unique inputs rejected by that platform baseline | 128 also rejected |
| Duplicate envelope variants | 3,840 rejected |
| Duplicate variants the old-style baseline accepted | 3,456 now rejected |
| Accepted deep-container cases | 7 unchanged |
| Platform-rejected deep-container cases | 3 also rejected |
| Exact 8 MiB encoding boundaries | 5 accepted; each plus one byte rejected as too large |
| Independent malformed payload cases | 19 rejected |
| Every proper prefix of a valid document | 136 truncated payloads rejected |
| Differential mismatches or unexpected acceptance | **0** |

The systematic sweep covers all six permutations of the three root members; mixed literal and escaped root-key spellings; alternating uppercase/lowercase Unicode hex escapes; integer-equivalent version notation; six leading/separator/trailing whitespace forms; quotes, backslashes, braces, brackets, commas and Unicode in names; real light arrays; unknown nested values; and nested duplicate scene keys that intentionally remain under the existing scene-decoder semantics.

Nine encoding/BOM forms were accepted by this runtime: UTF-8 with/without BOM, UTF-16 BE/LE with/without BOM, UTF-32 BE with/without BOM, and UTF-32 LE without BOM. UTF-32 LE with BOM was rejected by the same baseline and remains rejected. The five exact-byte-boundary cases use UTF-8 and explicit UTF-16/32 byte orders without BOM. This is measured runtime compatibility, not a declaration that every Apple Foundation version accepts the same forms.

Malformed cases include extra roots, missing delimiters, raw control characters in keys, unpaired surrogates, unknown escapes, invalid UTF-8, leading-zero/nonfinite/overflow version tokens, unsupported root shapes and extra envelope fields. The existing 18/18 author-targeted Debug and Release results are separately recorded in [document-key-integrity.md](document-key-integrity.md); they were inspected, not relabeled as newly run tests by this reviewer.

The first review harness mistakenly used an embedded tab/newline as a *project* name. The existing name validator rejected that fixture during construction before the sweep could complete. The harness was corrected to use valid project names, while those characters remained in light-string coverage permitted by the existing scene contract. This was a review-fixture error, not an application regression; the initial source remains in scratch and its hash is listed below.

## Remaining limits

This is an envelope-only correction. It deliberately does not change duplicate-key handling in nested scene objects, the scene's unknown-field behavior, or Foundation's overall JSON grammar policy. No global strict-JSON uniqueness claim should be added. Unsupported duplicate-version inputs may continue to report the existing unsupported-version error before this scan; they still fail import rather than selecting/adopting a scene.

The finite sweep strengthens the specific lexical/encoding implementation review; it is not a formal proof over every JSON input. Native Apple compatibility will be exercised by the existing portable-on-macOS CI job and full native workflow. The lead must complete the full integrated Debug/Release suite and retain current native/device gates until their actual evidence arrives.

## Reproduction and raw results

The scratch files are under `/workspace/scratch/73dcd6a65726/verification/document-parser-review/`. The complete probe source and final output are embedded below so the review remains reproducible after scratch expires. From the repository, copy the reviewed source with the single import prefix:

```sh
printf 'import LightingCore\n' > /tmp/DocumentUnderReview.swift
cat Sources/LightingCore/LightingProjectDocument.swift >> /tmp/DocumentUnderReview.swift
```

Then compile either embedded probe with Swift 6.4.3, supplying the already-built Release `LightingCore` module and object files. The executed command used:

```sh
swiftc -O -parse-as-library \
  -I /workspace/scratch/73dcd6a65726/verification/document-key-build/out/Intermediates.noindex/LightingCore.build/Release-linux-x86_64/LightingCore-t.build/Objects-normal/x86_64/Modules \
  /workspace/scratch/73dcd6a65726/verification/document-parser-review/DocumentUnderReview.swift \
  /workspace/scratch/73dcd6a65726/verification/document-parser-review/probe.swift \
  /workspace/scratch/73dcd6a65726/verification/document-key-build/out/Intermediates.noindex/LightingCore.build/Release-linux-x86_64/LightingCore-t.build/Objects-normal/x86_64/*.o \
  -o /workspace/scratch/73dcd6a65726/verification/document-parser-review/exact-probe
```

Replace `probe.swift` with `malformed.swift` for the malformed/prefix supplement. These probes use existing compiled domain dependencies but freshly compile the scanner under review. They do not invoke SwiftPM or alter its shared build lane.

### Hashes

- `probe.swift`: `e96a8c468e7b2ea778269a948d01225c45a25bc3bd1c4a4377e180eac04798e0`.
- `DocumentUnderReview.swift`: `59a1b182a6b9dfeb12749da2db22eed2b30d4a3bb9d1a55f17ba7229497f97a3`.
- `exact-result.json`: `c0d6de440087e16b4eea9f597d466c4299f3d83b26a06dcacd603a3c415986d8`.
- `malformed.swift`: `3851cc4f3813e35c45512d59dbf4c23796204b458d8b55e38ddc58f8f7915be6`.
- `malformed-result.json`: `0fcebf68cf8f9781beed92b81692a5d4157332febbff8ae1a153faf230bb1ff9`.
- `probe-initial-invalid-name-fixture.swift`: `a533faccc567adcb2dede8ad9a8121a2832232d47001fdcde1443ab7d8183574`.

### Systematic sweep output

```json
{
  "acceptedUnique" : 1152,
  "baselineDuplicatesAccepted" : 3456,
  "coverage" : {
    "utf8" : {
      "acceptedUnique" : 128
    },
    "utf8-bom" : {
      "acceptedUnique" : 128
    },
    "utf16be" : {
      "acceptedUnique" : 128
    },
    "utf16be-bom" : {
      "acceptedUnique" : 128
    },
    "utf16le" : {
      "acceptedUnique" : 128
    },
    "utf16le-bom" : {
      "acceptedUnique" : 128
    },
    "utf32be" : {
      "acceptedUnique" : 128
    },
    "utf32be-bom" : {
      "acceptedUnique" : 128
    },
    "utf32le" : {
      "acceptedUnique" : 128
    }
  },
  "deepAccepted" : 7,
  "deepRejected" : 3,
  "duplicateCases" : 3840,
  "exact8MiBEncodings" : 5,
  "foundationRejectedUnique" : 128,
  "mismatches" : [

  ]
}
```

### Malformed/prefix output

```json
{
  "failures" : [

  ],
  "malformedCases" : 19,
  "truncatedPrefixes" : 136
}
```

### Systematic probe source

```swift
import Foundation
import LightingCore

struct FoundationEnvelope: Decodable {
    let schemaVersion: Int
    let name: String
    let scene: LightingScene
}

@main struct Probe {
    static func baseline(_ data: Data) throws -> LightingProjectDocument {
        let envelope = try JSONDecoder().decode(FoundationEnvelope.self, from: data)
        guard envelope.schemaVersion == 1 else { throw LightingProjectDocument.DocumentError.unsupportedVersion }
        return try LightingProjectDocument(name: envelope.name, scene: envelope.scene)
    }
    static func quoted(_ text: String) throws -> String {
        String(decoding: try JSONEncoder().encode(text), as: UTF8.self)
    }
    static func key(_ text: String, seed: Int) -> String {
        var output = "\""
        for (index, value) in text.utf8.enumerated() {
            if ((seed &* 1103515245 &+ index &* 12345) >> (index % 11)) & 1 == 0 {
                output += String(format: index % 2 == 0 ? "\\u%04x" : "\\u%04X", Int(value))
            } else { output += String(Unicode.Scalar(value)) }
        }
        return output + "\""
    }
    struct WireEncoding {
        let name: String
        let encoding: String.Encoding
        let bom: [UInt8]
    }
    static let encodings: [WireEncoding] = [
        .init(name: "utf8", encoding: .utf8, bom: []),
        .init(name: "utf8-bom", encoding: .utf8, bom: [0xef,0xbb,0xbf]),
        .init(name: "utf16be", encoding: .utf16BigEndian, bom: []),
        .init(name: "utf16be-bom", encoding: .utf16BigEndian, bom: [0xfe,0xff]),
        .init(name: "utf16le", encoding: .utf16LittleEndian, bom: []),
        .init(name: "utf16le-bom", encoding: .utf16LittleEndian, bom: [0xff,0xfe]),
        .init(name: "utf32be", encoding: .utf32BigEndian, bom: []),
        .init(name: "utf32be-bom", encoding: .utf32BigEndian, bom: [0,0,0xfe,0xff]),
        .init(name: "utf32le", encoding: .utf32LittleEndian, bom: []),
        .init(name: "utf32le-bom", encoding: .utf32LittleEndian, bom: [0xff,0xfe,0,0])
    ]
    static func wire(_ text: String, _ encoding: WireEncoding) -> Data {
        Data(encoding.bom) + text.data(using: encoding.encoding)!
    }
    static func main() throws {
        let permutations = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
        let whitespace = ["", " ", "\t", "\r", "\n", " \r\n\t"]
        let names = ["Portrait", "{\"scene\": [1,2]} , :", "\\", "\\\"", "a\\\\\"b", "نور\u{200c}پردازی", "💡", "A\u{301}", "[]{}:,' /", "last \\", "comma, closing ]}", "\"name\" and \\", "x\tinside", "x\ninside"]
        let keys = ["schemaVersion", "name", "scene"]
        var acceptedUnique = 0, rejectedUnique = 0, duplicateChecked = 0
        var baselineDuplicatesAccepted = 0, mismatches: [String] = []
        var coverage: [String: [String: Int]] = [:]
        for seed in 0..<128 {
            var scene = LightingScene.portrait()
            scene.lights[0].name = names[(seed + 3) % names.count]
            let expected = try LightingProjectDocument(name: names[seed % (names.count - 2)], scene: scene)
            let sceneText = String(decoding: try SceneCodec.encode(scene), as: UTF8.self)
            // Unknown nested data is valid JSON and intentionally remains under
            // the existing scene decoder's semantics. Its keys are not envelope keys.
            let nested = String(sceneText.dropLast()) + ",\"reviewOnly\":[{\"name\":\"scene\",\"scene\":[\"\\\"[,]{}\\\\\",null,true,false,1.0,[]]}, {\"name\":1,\"name\":2}]}"
            let values = [seed % 2 == 0 ? "1" : "1.00e+0", try quoted(expected.name), nested]
            let order = permutations[seed % permutations.count]
            let ws = whitespace[seed % whitespace.count]
            let members = order.map { key(keys[$0], seed: seed + $0) + ws + ":" + ws + values[$0] }
            let unique = ws + "{" + members.joined(separator: ws + "," + ws) + "}" + ws
            for encoding in encodings {
                let data = wire(unique, encoding)
                if let original = try? baseline(data) {
                    acceptedUnique += 1
                    coverage[encoding.name, default: [:]]["acceptedUnique", default: 0] += 1
                    do {
                        let candidate = try LightingProjectDocument.decode(data)
                        if candidate != original || candidate != expected { mismatches.append("unique equality \(seed) \(encoding.name)") }
                        if try candidate.encode() != original.encode() { mismatches.append("canonical bytes \(seed) \(encoding.name)") }
                    } catch { mismatches.append("unique rejected \(seed) \(encoding.name): \(error)") }
                } else {
                    rejectedUnique += 1
                    if (try? LightingProjectDocument.decode(data)) != nil { mismatches.append("baseline-rejected accepted \(seed) \(encoding.name)") }
                }
                for duplicated in 0..<3 {
                    var ambiguousMembers = members
                    let duplicate = key(keys[duplicated], seed: seed + 157) + ":" + values[duplicated]
                    ambiguousMembers.insert(duplicate, at: (seed + duplicated) % 4)
                    let ambiguous = ws + "{" + ambiguousMembers.joined(separator: ws + "," + ws) + "}" + ws
                    let bytes = wire(ambiguous, encoding)
                    duplicateChecked += 1
                    if (try? baseline(bytes)) != nil { baselineDuplicatesAccepted += 1 }
                    if (try? LightingProjectDocument.decode(bytes)) != nil {
                        mismatches.append("duplicate accepted \(seed) \(encoding.name) key \(keys[duplicated])")
                    }
                }
            }
        }
        var depthAccepted = 0, depthRejected = 0
        let plainScene = #"{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"lights":[]}"#
        for depth in [1,2,31,127,255,500,510,511,512,513] {
            let nested = String(plainScene.dropLast()) + ",\"reviewOnly\":" + String(repeating:"[",count:depth) + "\"{}[\\\"\\\\]\"" + String(repeating:"]",count:depth) + "}"
            let input = Data(("{\"scene\":" + nested + ",\"name\":\"Depth\",\"schemaVersion\":1}").utf8)
            if let old = try? baseline(input) {
                depthAccepted += 1
                if (try? LightingProjectDocument.decode(input)) != old { mismatches.append("depth \(depth) changed") }
            } else {
                depthRejected += 1
                if (try? LightingProjectDocument.decode(input)) != nil { mismatches.append("invalid depth \(depth) accepted") }
            }
        }
        let basic = "{\"schemaVersion\":1,\"name\":\"Boundary\",\"scene\":" + plainScene + "}"
        var byteBoundaries = 0
        for encoding in encodings where encoding.bom.isEmpty {
            var bytes = wire(basic, encoding)
            let pad = wire(" ", encoding)
            let count = (LightingProjectDocument.maximumBytes - bytes.count) / pad.count
            bytes.append(Data(repeating:0,count:0))
            for _ in 0..<count { bytes.append(pad) }
            guard bytes.count == LightingProjectDocument.maximumBytes else { fatalError("boundary alignment") }
            let original = try baseline(bytes)
            if (try? LightingProjectDocument.decode(bytes)) != original { mismatches.append("boundary rejected \(encoding.name)") }
            bytes.append(32)
            do {
                _ = try LightingProjectDocument.decode(bytes)
                mismatches.append("oversized accepted \(encoding.name)")
            } catch let error as LightingProjectDocument.DocumentError {
                if error != .tooLarge { mismatches.append("wrong oversized error \(encoding.name)") }
            } catch { mismatches.append("unexpected oversized error \(encoding.name)") }
            byteBoundaries += 1
        }
        let result: [String:Any] = ["acceptedUnique":acceptedUnique,"foundationRejectedUnique":rejectedUnique,
            "duplicateCases":duplicateChecked,"baselineDuplicatesAccepted":baselineDuplicatesAccepted,
            "deepAccepted":depthAccepted,"deepRejected":depthRejected,"exact8MiBEncodings":byteBoundaries,
            "coverage":coverage,"mismatches":mismatches]
        let json = try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys])
        print(String(decoding:json,as:UTF8.self))
        if !mismatches.isEmpty { exit(1) }
    }
}
```

### Malformed/prefix probe source

```swift
import Foundation
import LightingCore

@main struct MalformedProbe {
    static func main() throws {
        let scene = #"{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"lights":[]}"#
        let basic = #"{"schemaVersion":1,"name":"Copy","scene":"# + scene + "}"
        let invalid = ["", "{}", "[]", "null", "1", "\"x\"", basic + "{}", String(basic.dropLast()),
            basic.replacingOccurrences(of:"\"name\":", with:"\"name\":,"),
            basic.replacingOccurrences(of:"\"Copy\"",with:"\"\\uD800\""),
            basic.replacingOccurrences(of:"\"Copy\"",with:"\"\\uDC00\""),
            basic.replacingOccurrences(of:"\"Copy\"",with:"\"\\q\""),
            basic.replacingOccurrences(of:"\"name\"",with:"\"na\nme\""),
            basic.replacingOccurrences(of:"\"Copy\"",with:"\"unterminated\\\""),
            basic.replacingOccurrences(of:"\"schemaVersion\":1",with:"\"schemaVersion\":01"),
            basic.replacingOccurrences(of:"\"schemaVersion\":1",with:"\"schemaVersion\":NaN"),
            basic.replacingOccurrences(of:"\"schemaVersion\":1",with:"\"schemaVersion\":1e999"),
            basic.replacingOccurrences(of:"\"name\":",with:"\"unexpected\":null,\"name\":")]
        var failures: [String] = []
        for (index,text) in invalid.enumerated() {
            if (try? LightingProjectDocument.decode(Data(text.utf8))) != nil { failures.append("malformed \(index) accepted") }
        }
        var badUTF8 = Data(#"{"schemaVersion":1,"name":""#.utf8)
        badUTF8.append(contentsOf:[0xc3,0x28])
        badUTF8.append(Data((#"","scene":"# + scene + "}").utf8))
        if (try? LightingProjectDocument.decode(badUTF8)) != nil { failures.append("bad UTF8 accepted") }
        let truncations = Array(basic.utf8)
        for count in 0..<truncations.count {
            if (try? LightingProjectDocument.decode(Data(truncations.prefix(count)))) != nil { failures.append("truncated at \(count) accepted") }
        }
        let result: [String:Any] = ["malformedCases":invalid.count + 1,"truncatedPrefixes":truncations.count,"failures":failures]
        print(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]),as:UTF8.self))
        if !failures.isEmpty { exit(1) }
    }
}
```
