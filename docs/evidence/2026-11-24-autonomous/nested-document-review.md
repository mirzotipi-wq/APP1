# Independent nested-document integrity review

## Decision and scope

No demonstrated correctness blocker was found in the extension from envelope-only rejection to duplicate-name rejection in every object of an **external editable project document**. The candidate is suitable for the lead's complete exact-source integration, with the measured large-input CPU/memory limits below retained. This is a follow-up by the existing wave-ten document reviewer, not an additional specialist.

The root-only baseline was captured from the lead's frozen index while HEAD was `ff8b683098a720b4c7abdddf212f85a79f3cfd39`; its production document hash is `54834f5dd469bcccd7683ac49a95c4efa8b73de20960bdd0fd17f283b505b478`. The candidate document hash is `bf79fd894a96c7640bbc3802a2f631bcce98c6c2a90167e72e1ef22e05b31938`. Both document implementations were freshly compiled into a standalone probe, with a type rename for the baseline and an import of unchanged domain dependencies. The index was neither reset nor edited by this reviewer. Only this report was added to the repository.

This correction is confined to `LightingProjectDocument.decode`. Existing `ProjectLibrary` and `SceneCodec` stored-data decoding is unchanged. Unknown fields with unique names remain accepted under their existing decoder semantics; rejecting repeated names in unknown nested objects is an explicit part of the new external-document policy.

## Reproduced ambiguity

The actual root-only baseline accepted one document containing all of the following repeated nested members:

| Raw nested sequence | Actual decoded baseline value |
| --- | --- |
| `candela: 900`, then `candela: 200` | `900` |
| `name: "Key"`, then `name: "Fill"` | `Key` |
| Subject `x: 0`, then `x: 5` | `0` |

The candidate rejects that same document. The review does not turn this runtime's observed first-winner behavior into a format contract. [RFC 8259 sections 4 and 8.3](https://www.rfc-editor.org/rfc/rfc8259) recommend unique object names and describe comparison after escape conversion by the resulting Unicode sequence. A repeated name is therefore rejected instead of depending on a particular decoder's winner. The RFC also permits parser resource limits; the app's existing byte bound is preserved.

## Correctness review

Each object/array now has its own stack frame. Object frames begin expecting a key; array frames never interpret their string elements as keys. Object commas enable the next key, strings consume escapes as one lexical unit, and container close checks the matching kind before popping the frame. Parent key state survives entry into a child, and closing a child cannot pollute a sibling's key set.

After Foundation decodes a key token, its exact UTF-8 bytes are stored in `Set<Data>`. This rejects literal/escaped spellings of the identical sequence, including BMP escapes, surrogate pairs, backslashes and quotes. It preserves distinct scalar sequences such as precomposed `é` versus `e` plus combining acute, or a character with versus without a variation selector. A `Set<String>` would have conflated some canonically equivalent but distinct JSON names; the candidate avoids that compatibility defect.

Foundation still performs the envelope/value decoding and determines accepted encodings and nesting limits. The new helper uses Foundation to decode key escapes and converts key-decode failures to the established invalid-document error. It does not introduce a second number/value parser or broaden invalid-input acceptance. Existing malformed-value/encoding and byte-limit tests remain in the author's 24-test targeted run. That author's Debug/Release result is attributed to [nested-document-integrity.md](nested-document-integrity.md), not counted as a newly executed reviewer suite.

### Independent differential results

The optimized probe used Swift 6.4.3 on Debian 13 x86_64, against fresh baseline/candidate document copies and the already-built cycle-seven Release domain library. It did not invoke SwiftPM or use a shared build lane.

| Check | Actual result |
| --- | ---: |
| Duplicate variants checked | **1,440 rejected** |
| Those variants accepted by the old baseline | **1,296** |
| Accepted unique inputs | **1,944 preserved equal values and canonical bytes** |
| Unique inputs rejected by the platform baseline | **216 remained rejected** |
| Accepted deep unique inputs | **16 preserved** |
| Platform-rejected deep inputs | **6 remained rejected** |
| Deep duplicate inputs previously accepted | **16 now rejected** |
| Differential problems | **0** |

The duplicate matrix expands 24 independently constructed scene/light/position/optics/lens/preview/unknown-object cases across six root-member orders and ten encoding/BOM forms. Unique controls cover repeated names in sibling and parent/child objects, mixed nested arrays, repeated string values, escaped structural punctuation, empty keys, escaped control-character keys, NFC/NFD distinctions and variation selectors. Six whitespace forms are included. Nine encoding/BOM forms were accepted on this runtime; UTF-32 little-endian with BOM retained the baseline's rejection.

Deep cases use both arrays and repeated-name object layers at depths from 1 through 512, retaining whichever cases the existing Foundation decoder accepts. No new hard-coded depth promise is made. These counts describe finite probe inputs, not XCTest methods, Apple execution or a proof over every JSON text.

## Wide-object CPU and memory check

Source inspection confirms that insertion uses `scopes[index].keys.insert(...)` in place. It does not copy a frame's entire set to a local before every insertion. The temporary frame copy at close is used only to check delimiter kind, then removed; it is not mutated. Closed object key sets are released before siblings are scanned. This supports expected linear scan/hash work rather than accidental per-member full-set copying; it is not a worst-case hash-table proof.

Three samples each were measured for 10,000 and 20,000 unique ignored metadata keys, and one sample at the exact 8 MiB wire limit. The count/size boundary was deliberately chosen so a second validation pass cannot hide behind trailing whitespace alone.

| Unique keys | Wire bytes | Baseline median decode | Candidate median decode | Whole probe peak RSS |
| ---: | ---: | ---: | ---: | ---: |
| 10,000 | 120,504 | 2.036 ms | 37.104 ms | 24,292 KiB |
| 20,000 | 240,504 | 7.576 ms | 97.183 ms | 24,864 KiB |
| 699,008 | 8,388,608 | 319.090 ms | 2196.612 ms | 141,680 KiB |

All wide inputs preserved the decoded values and canonical bytes. The 699,008-key input was exactly **8,388,608 bytes**; appending one byte returned `tooLarge`. The guard still runs before decoding or scanning. The smaller inputs were not subjected to a plus-one-byte oversized check because that extra byte would remain within the limit.

The near-limit candidate took **2.197 seconds** versus **0.319 seconds** for the root-only baseline in this one shared-Linux observation. The increased cost is real: every nested name now requires escape decoding and set insertion. The finite 10k/20k and near-limit results do not show an accidental quadratic copy pattern, but host contention/caches and the small sample prevent a general latency bound. No caching, parser rewrite or speculative optimization was introduced by the reviewer.

Peak RSS is the Linux child-process `resource.ru_maxrss` measurement and includes fixture construction, Foundation/domain state and both baseline and candidate runs. It is **not** isolated scanner allocation, iOS app memory, physical-device evidence or a performance-gate result. The parser input cap does not cap peak memory at 8 MiB: transcoded bytes, the container stack and live sets of decoded names add storage. Set memory grows with simultaneously open objects' names, and wide individual objects can retain many keys until close.

Import decoding is already asynchronous. These measurements do not establish a blocked UI, cancellation latency on an iPhone or a device memory failure. They justify preserving the large-input cost in future import responsiveness/device testing. A separate external-document optimization would need to preserve all escape, encoding, Unicode-distinction and rejection semantics before integration.

## Reproduction and raw evidence

Scratch directory: `/workspace/scratch/73dcd6a65726/verification/nested-document-review/`. The baseline source is the frozen indexed file with `LightingProjectDocument` renamed to `BaselineDocument` and `import LightingCore` added. The candidate is the exact candidate source with that import added. Compile:

```sh
swiftc -O -parse-as-library \
  -I /workspace/scratch/73dcd6a65726/verification/cycle7-source/.build/out/Products/Release-linux-x86_64 \
  /workspace/scratch/73dcd6a65726/verification/nested-document-review/BaselineDocument.swift \
  /workspace/scratch/73dcd6a65726/verification/nested-document-review/CandidateDocument.swift \
  /workspace/scratch/73dcd6a65726/verification/nested-document-review/probe.swift \
  /workspace/scratch/73dcd6a65726/verification/cycle7-source/.build/out/Products/Release-linux-x86_64/libLightingCore.a \
  -o /workspace/scratch/73dcd6a65726/verification/nested-document-review/probe
```

Running the probe without arguments produces the differential matrix. `probe stress 10000`, `probe stress 20000` and `probe stress limit` produce the width observations. A Python subprocess wrapper imposed a 35-second limit and recorded each process's resource measurement; `/usr/bin/time` was unavailable. Every measured process exited 0 without stderr.

### Hashes

- `baseline-production.swift` SHA-256 `54834f5dd469bcccd7683ac49a95c4efa8b73de20960bdd0fd17f283b505b478`.
- `CandidateDocument.swift` SHA-256 `d4f9b1cbd5e476e08fd749bf1731aeba79a160bc26b4f1e11d84a8dc25b5e1d7`.
- `probe.swift` SHA-256 `9faaf458dc5b8d876732dfcd7ed6e5850dee8f20b19f208344e546858091cbbb`.
- `targeted.json` SHA-256 `629798bc25900f7c89585c04307a4a16ea77947d0ef125ddcc036bd2448c045c`.
- `stress-10000.json` SHA-256 `721b44bc5251da363367b05e37afc26925860d00e087f0bdf5504f75199fa133`.
- `stress-20000.json` SHA-256 `0f5f5dc81bb2a22ee4fbe09e3792cc3d6bcedff3142f18609d3d993fc648f09d`.
- `stress-limit.json` SHA-256 `07002ae3af46989947dd8b4a196ac5e5fc8143f06918a88e3b7c8828ce3d1829`.
- `measure.py` SHA-256 `d49ae1a935c548d57707fade46789ac54926e2b98f772d2059dd15a0898a07c2`.
- `stress-10000-resource.json` SHA-256 `77efab9f90d3e819cc8411d15b32ca9fe761c0d7b8a6646b9bad9a601144fdff`.
- `stress-20000-resource.json` SHA-256 `7e6e2cfb9ba9a42a52e340f04628da101943966c0f35931c682e96254d903a00`.
- `stress-limit-resource.json` SHA-256 `8c3e76540722324087f58b467b3331b5c20996044b8088360d4fb967e72ec414`.

### Raw differential result

```json
{
  "baselineDuplicateVariantsAccepted" : 1296,
  "baselineWinner" : {
    "decodedCandela" : 900,
    "decodedName" : "Key",
    "decodedSubjectX" : 0,
    "wireCandela" : [
      900,
      200
    ],
    "wireName" : [
      "Key",
      "Fill"
    ],
    "wireSubjectX" : [
      0,
      5
    ]
  },
  "deepDuplicatesPreviouslyAccepted" : 16,
  "deepUniqueAccepted" : 16,
  "deepUniqueRejected" : 6,
  "duplicateVariants" : 1440,
  "problems" : [

  ],
  "uniqueAccepted" : 1944,
  "uniqueRejectedByBaseline" : 216
}
```

### Raw width results

```json
{
  "10000": {
    "decode": {
      "baselineMilliseconds": [
        2.77768,
        2.035539,
        1.671198
      ],
      "candidateMilliseconds": [
        57.220545,
        37.10397,
        30.576251
      ],
      "keys": 10000,
      "plusOneByteRejected": false,
      "repetitions": 3,
      "valuesAndCanonicalBytesEqual": true,
      "wireBytes": 120504
    },
    "process": {
      "maximumResidentKiB": 24292,
      "elapsedSeconds": 0.35104500300076324,
      "exitStatus": 0,
      "stderr": ""
    }
  },
  "20000": {
    "decode": {
      "baselineMilliseconds": [
        6.257369,
        7.576474,
        8.983221
      ],
      "candidateMilliseconds": [
        102.187451,
        97.182805,
        88.93659
      ],
      "keys": 20000,
      "plusOneByteRejected": false,
      "repetitions": 3,
      "valuesAndCanonicalBytesEqual": true,
      "wireBytes": 240504
    },
    "process": {
      "maximumResidentKiB": 24864,
      "elapsedSeconds": 0.4358826969983056,
      "exitStatus": 0,
      "stderr": ""
    }
  },
  "limit": {
    "decode": {
      "baselineMilliseconds": [
        319.089552
      ],
      "candidateMilliseconds": [
        2196.61241
      ],
      "keys": 699008,
      "plusOneByteRejected": true,
      "repetitions": 1,
      "valuesAndCanonicalBytesEqual": true,
      "wireBytes": 8388608
    },
    "process": {
      "maximumResidentKiB": 141680,
      "elapsedSeconds": 3.1311657070000365,
      "exitStatus": 0,
      "stderr": ""
    }
  }
}
```

### Complete independent probe

```swift
import Foundation
import Dispatch
import LightingCore

@main struct NestedReview {
    static func position(_ extra: String = "", x: String = "0", y: String = "1.5", z: String = "0") -> String {
        "{\"x\":\(x),\"y\":\(y),\"z\":\(z)\(extra)}"
    }
    static func optics(_ extra: String = "", aim: String? = nil) -> String {
        "{\"kind\":\"rectangle\",\"widthMeters\":0.6,\"heightMeters\":0.9,\"aimTarget\":\(aim ?? position())\(extra)}"
    }
    static func light(_ extra: String = "", at: String? = nil, modifier: String? = nil) -> String {
        "{\"id\":\"00000000-0000-4000-8000-000000000001\",\"name\":\"Key\",\"candela\":900,\"kelvin\":5600,\"position\":\(at ?? position(x:"-1.25",y:"2",z:"1.5")),\"optics\":\(modifier ?? optics())\(extra)}"
    }
    static func scene(_ extra: String = "", subject: String? = nil, camera: String? = nil,
                      source: String? = nil, lens: String = #"{"focalLengthMillimeters":73.125}"#,
                      preview: String = #"{"whiteBalanceKelvin":5500,"exposureStops":0.75}"#) -> String {
        "{\"schemaVersion\":4,\"subject\":\(subject ?? position()),\"camera\":\(camera ?? position(z:"3")),\"lights\":[\(source ?? light())],\"cameraLens\":\(lens),\"previewSettings\":\(preview)\(extra)}"
    }
    static func document(_ scene: String, order: [Int] = [0,1,2], whitespace: String = "") -> String {
        let members = [#""schemaVersion":1"#, #""name":"Independent review""#, #""scene":"# + scene]
        return whitespace + "{" + order.map { members[$0] }.joined(separator: whitespace + "," + whitespace) + "}" + whitespace
    }
    struct Encoding {
        let name: String, encoding: String.Encoding, bom: [UInt8]
        func data(_ text: String) -> Data { Data(bom) + text.data(using:encoding)! }
    }
    static let encodings: [Encoding] = [
        .init(name:"utf8",encoding:.utf8,bom:[]),.init(name:"utf8-bom",encoding:.utf8,bom:[0xef,0xbb,0xbf]),
        .init(name:"utf16be",encoding:.utf16BigEndian,bom:[]),.init(name:"utf16be-bom",encoding:.utf16BigEndian,bom:[0xfe,0xff]),
        .init(name:"utf16le",encoding:.utf16LittleEndian,bom:[]),.init(name:"utf16le-bom",encoding:.utf16LittleEndian,bom:[0xff,0xfe]),
        .init(name:"utf32be",encoding:.utf32BigEndian,bom:[]),.init(name:"utf32be-bom",encoding:.utf32BigEndian,bom:[0,0,0xfe,0xff]),
        .init(name:"utf32le",encoding:.utf32LittleEndian,bom:[]),.init(name:"utf32le-bom",encoding:.utf32LittleEndian,bom:[0xff,0xfe,0,0])]
    static func printJSON(_ result: [String:Any]) throws {
        print(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]),as:UTF8.self))
    }
    static func main() throws {
        if CommandLine.arguments.count > 1 && CommandLine.arguments[1] == "stress" {
            try stress(); return
        }
        let duplicateScenes: [(String,String)] = [
            ("scene version",scene(#", "schemaVersion":99"#)),
            ("scene camera",scene(#", "camera":{"x":12,"y":1.5,"z":3}"#)),
            ("scene lights",scene(#", "lights":[]"#)),
            ("subject x",scene(subject:position(#", "x":5"#))),
            ("camera escaped x",scene(camera:position(#", "\u0078":-3"#,z:"3"))),
            ("light candela",scene(source:light(#", "candela":200"#))),
            ("light name",scene(source:light(#", "name":"Fill""#))),
            ("light kelvin",scene(source:light(#", "kelvin":2700"#))),
            ("light id",scene(source:light(#", "id":"00000000-0000-4000-8000-000000000002""#))),
            ("light position",scene(source:light(#", "position":{"x":2,"y":2,"z":2}"#))),
            ("optics width",scene(source:light(modifier:optics(#", "widthMeters":2.6"#)))),
            ("optics kind",scene(source:light(modifier:optics(#", "kind":"point"# + "\"")))),
            ("aim x",scene(source:light(modifier:optics(aim:position(#", "x":25"#))))),
            ("lens focal",scene(lens:#"{"focalLengthMillimeters":73.125,"focalLengthMillimeters":85}"#)),
            ("preview exposure",scene(preview:#"{"whiteBalanceKelvin":5500,"exposureStops":0.75,"exposureStops":1}"#)),
            ("preview balance",scene(preview:#"{"whiteBalanceKelvin":5500,"exposureStops":0.75,"whiteBalanceKelvin":4000}"#))]
        let duplicateMetadata = [#"{"x":1,"x":2}"#, #"[{"x":1,"\u0078":2}]"#,
            #"{"":1,"":2}"#, #"{"é":1,"\u00e9":2}"#, #"{"💡":1,"\ud83d\udca1":2}"#,
            #"{"a\\b":1,"a\u005Cb":2}"#, #"{"\"":1,"\u0022":2}"#, #"{"\b":1,"\u0008":2}"#]
        let allDuplicates = duplicateScenes + duplicateMetadata.enumerated().map { ("metadata \($0.offset)",scene(#", "reviewOnly":"# + $0.element)) }
        let uniqueMetadata = [
            #"[{"name":"first"},{"name":"second"},{"name":"third"}]"#,
            #"{"name":"parent","child":{"name":"child","nested":[{"name":"leaf"},"name"]}}"#,
            #"["name","name",["name",[],{}],{"value":"quote: \"name\": [},] \\ slash"}]"#,
            #"{"é":1,"e\u0301":2,"Å":3,"A\u030a":4,"💡":5,"💡\ufe0f":6}"#,
            #"[{"":1},{"":2},[{"":3}]]"#,
            #"{"\u0000":1,"\u0001":2,"\b":3,"\t":4,"\r":5,"\n":6}"#]
        let permutations = [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
        let whitespace = ["", " ", "\t", "\r", "\n", " \r\n\t"]
        var uniqueAccepted = 0, uniqueRejected = 0, duplicates = 0, oldDuplicatesAccepted = 0
        var problems: [String] = []
        for (name, input) in allDuplicates {
            if (try? BaselineDocument.decode(Data(document(input).utf8))) == nil { problems.append("Invalid baseline duplicate fixture: \(name)") }
            for (index,order) in permutations.enumerated() {
                let text = document(input,order:order,whitespace:whitespace[index])
                for encoding in encodings {
                    let data = encoding.data(text)
                    duplicates += 1
                    if (try? BaselineDocument.decode(data)) != nil { oldDuplicatesAccepted += 1 }
                    if (try? LightingProjectDocument.decode(data)) != nil { problems.append("duplicate accepted: \(name), \(index), \(encoding.name)") }
                }
            }
        }
        for metadata in uniqueMetadata {
            for order in permutations {
                for ws in whitespace {
                    let text = document(scene(#", "reviewOnly":"# + metadata),order:order,whitespace:ws)
                    for encoding in encodings {
                        let data = encoding.data(text)
                        if let old = try? BaselineDocument.decode(data) {
                            uniqueAccepted += 1
                            do {
                                let candidate = try LightingProjectDocument.decode(data)
                                let oldBytes = try old.encode()
                                let candidateBytes = try candidate.encode()
                                if candidate.name != old.name || candidate.scene != old.scene || candidateBytes != oldBytes {
                                    problems.append("unique mismatch: \(encoding.name)")
                                }
                            } catch { problems.append("unique rejection: \(encoding.name): \(error)") }
                        } else {
                            uniqueRejected += 1
                            if (try? LightingProjectDocument.decode(data)) != nil { problems.append("baseline-rejected unique accepted") }
                        }
                    }
                }
            }
        }
        var deepAccepted = 0, deepRejected = 0, deepDuplicates = 0
        for depth in [1,2,31,64,127,250,500,508,510,511,512] {
            for objectLayers in [false,true] {
                func nest(_ leaf: String) -> String {
                    if objectLayers { return String(repeating:#"{"name":"#,count:depth) + leaf + String(repeating:"}",count:depth) }
                    return String(repeating:"[",count:depth) + leaf + String(repeating:"]",count:depth)
                }
                let data = Data(document(scene(#", "reviewOnly":"# + nest(#"{"name":"leaf"}"#))).utf8)
                if let old = try? BaselineDocument.decode(data) {
                    deepAccepted += 1
                    if let candidate = try? LightingProjectDocument.decode(data) {
                        if candidate.scene != old.scene || candidate.name != old.name { problems.append("deep value changed \(depth)") }
                    } else { problems.append("deep unique rejected \(depth), objects \(objectLayers)") }
                } else {
                    deepRejected += 1
                    if (try? LightingProjectDocument.decode(data)) != nil { problems.append("depth bound expanded \(depth)") }
                }
                let ambiguous = Data(document(scene(#", "reviewOnly":"# + nest(#"{"name":"leaf","na\u006de":"other"}"#))).utf8)
                if (try? BaselineDocument.decode(ambiguous)) != nil { deepDuplicates += 1 }
                if (try? LightingProjectDocument.decode(ambiguous)) != nil { problems.append("deep duplicate accepted \(depth)") }
            }
        }
        let winner = try BaselineDocument.decode(Data(document(scene(subject:position(#", "x":5"#),source:light(#", "candela":200,"name":"Fill""#))).utf8))
        try printJSON(["duplicateVariants":duplicates,"baselineDuplicateVariantsAccepted":oldDuplicatesAccepted,
            "uniqueAccepted":uniqueAccepted,"uniqueRejectedByBaseline":uniqueRejected,
            "deepUniqueAccepted":deepAccepted,"deepUniqueRejected":deepRejected,"deepDuplicatesPreviouslyAccepted":deepDuplicates,
            "baselineWinner":["wireCandela":[900,200],"decodedCandela":winner.scene.lights[0].candela,
                              "wireName":["Key","Fill"],"decodedName":winner.scene.lights[0].name,
                              "wireSubjectX":[0,5],"decodedSubjectX":winner.scene.subject.x],
            "problems":problems])
        if !problems.isEmpty { exit(1) }
    }
    static func stress() throws {
        let requested = CommandLine.arguments[2]
        let prefix = #", "reviewOnly":{"#
        let empty = document(scene(prefix + "}"))
        let maximum = LightingProjectDocument.maximumBytes
        let count = requested == "limit" ? (maximum - empty.utf8.count + 1) / 12 : Int(requested)!
        var members = ""; members.reserveCapacity(count * 12)
        for index in 0..<count {
            if index > 0 { members += "," }
            let digits = String(index)
            members += "\"k" + String(repeating:"0",count:6-digits.count) + digits + "\":0"
        }
        var data = Data(document(scene(prefix + members + "}")).utf8)
        if requested == "limit" { data.append(Data(repeating:32,count:maximum-data.count)) }
        let repetitions = requested == "limit" ? 1 : 3
        var oldMs: [Double] = [], candidateMs: [Double] = []
        var equality = true
        for _ in 0..<repetitions {
            var start = DispatchTime.now().uptimeNanoseconds
            let old = try BaselineDocument.decode(data)
            oldMs.append(Double(DispatchTime.now().uptimeNanoseconds-start)/1e6)
            start = DispatchTime.now().uptimeNanoseconds
            let candidate = try LightingProjectDocument.decode(data)
            candidateMs.append(Double(DispatchTime.now().uptimeNanoseconds-start)/1e6)
            let oldBytes = try old.encode()
            let candidateBytes = try candidate.encode()
            equality = equality && candidate.name == old.name && candidate.scene == old.scene && candidateBytes == oldBytes
        }
        var oversizedRejected = false
        if requested == "limit" {
            var oversized = data; oversized.append(32)
            do { _ = try LightingProjectDocument.decode(oversized) }
            catch let error as LightingProjectDocument.DocumentError { oversizedRejected = error == .tooLarge }
        }
        try printJSON(["keys":count,"wireBytes":data.count,"repetitions":repetitions,"baselineMilliseconds":oldMs,
            "candidateMilliseconds":candidateMs,"valuesAndCanonicalBytesEqual":equality,"plusOneByteRejected":oversizedRejected])
        if !equality || (requested == "limit" && !oversizedRejected) { exit(1) }
    }
}
```

### Resource wrapper

```python
from pathlib import Path
import json, resource, subprocess, sys, time
v=Path(__file__).parent
case=sys.argv[1]
start=time.perf_counter()
with (v/('stress-'+case+'.json')).open('w') as output:
    result=subprocess.run([str(v/'probe'),'stress',case],stdout=output,stderr=subprocess.PIPE,text=True,timeout=35)
info={'maximumResidentKiB':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,'elapsedSeconds':time.perf_counter()-start,'exitStatus':result.returncode,'stderr':result.stderr}
(v/('stress-'+case+'-resource.json')).write_text(json.dumps(info,indent=2)+'\n')
print(json.dumps({'case':case,**info}))
if result.returncode:sys.exit(result.returncode)
```
