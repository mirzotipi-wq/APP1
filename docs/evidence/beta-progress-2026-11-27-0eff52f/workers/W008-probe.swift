import Foundation
import LightingCore

struct Case: Decodable {
    let value: String
    let expected: Bool
    let mode: Int
    let encoding: String
    let kind: String
}
func wire(_ value: String) -> String {
    #"{"schemaVersion":1,"name":"Independent review","scene":{"schemaVersion":5,"subject":{"x":0,"y":1.5,"z":0},"camera":{"x":0,"y":1.5,"z":3},"lights":[],"reviewData":"# + value + "}}"
}
func metadata(_ row: Case) -> String {
    switch row.mode {
    case 1: return "[" + row.value + "]"
    case 2: return "{\"a\":" + row.value + "}"
    case 3: return "[true, {\"b\": [null, " + row.value + ", false]}]"
    case 4: return " \r\n\t " + row.value + " \t\n\r "
    default: return row.value
    }
}
func bytes(_ text: String, _ name: String) -> Data {
    let encoding: String.Encoding
    switch name {
    case "utf16be": encoding = .utf16BigEndian
    case "utf16le": encoding = .utf16LittleEndian
    case "utf32be": encoding = .utf32BigEndian
    case "utf32le": encoding = .utf32LittleEndian
    default: encoding = .utf8
    }
    return text.data(using: encoding)!
}
let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
let begin = Date()
var mismatches: [[String: Any]] = []
var accepted = 0
for (i,row) in cases.enumerated() {
    var actual = false
    do { _ = try LightingProjectDocument.decode(bytes(wire(metadata(row)), row.encoding)); actual = true } catch {}
    if actual { accepted += 1 }
    if actual != row.expected {
        mismatches.append(["index":i,"value":row.value,"expected":row.expected,"actual":actual,"mode":row.mode,"encoding":row.encoding])
    }
}
var summary: [String: Any] = ["cases":cases.count,"accepted":accepted,"mismatchCount":mismatches.count,"mismatches":mismatches,"seconds":Date().timeIntervalSince(begin)]
// Boundaries use the actual public byte ceiling. Record host time only: not a device benchmark.
var boundary: [[String: Any]] = []
let emptyWireCount = wire("").utf8.count
for count in [1_024,65_536,1_048_576,LightingProjectDocument.maximumBytes-emptyWireCount] {
    let n = String(repeating:"9",count:count)
    let data = Data(wire(n).utf8)
    let start = Date()
    var ok = false
    do { _ = try LightingProjectDocument.decode(data); ok=true } catch {}
    boundary.append(["case":"long_integer","documentBytes":data.count,"accepted":ok,"seconds":Date().timeIntervalSince(start)])
}
for n in [1_024,16_384,65_536] {
    let data = Data(wire("["+Array(repeating:"-1.25e+03",count:n).joined(separator:",")+"]").utf8)
    let start=Date(); var ok=false
    do { _=try LightingProjectDocument.decode(data);ok=true } catch {}
    boundary.append(["case":"dense_numbers","numbers":n,"documentBytes":data.count,"accepted":ok,"seconds":Date().timeIntervalSince(start)])
}
let over = Data(wire(String(repeating:"9",count:LightingProjectDocument.maximumBytes-emptyWireCount+1)).utf8)
var tooLarge=false
 do { _=try LightingProjectDocument.decode(over) } catch LightingProjectDocument.DocumentError.tooLarge { tooLarge=true } catch {}
boundary.append(["case":"over_limit","documentBytes":over.count,"tooLarge":tooLarge])
summary["boundaries"]=boundary
let result=try JSONSerialization.data(withJSONObject:summary, options:[.prettyPrinted,.sortedKeys])
try result.write(to: URL(fileURLWithPath:CommandLine.arguments[2]))
print(String(decoding:result,as:UTF8.self))
