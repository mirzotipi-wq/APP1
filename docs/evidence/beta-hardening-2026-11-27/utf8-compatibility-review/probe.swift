import Foundation

// Independent byte-level oracle, not production code.
func isStrictUTF8(_ a: [UInt8]) -> Bool {
    var i = 0
    while i < a.count {
        let x = a[i]
        if x <= 0x7f { i += 1; continue }
        let n: Int
        let lower: UInt8
        let upper: UInt8
        switch x {
        case 0xc2...0xdf: n = 2; lower = 0x80; upper = 0xbf
        case 0xe0: n = 3; lower = 0xa0; upper = 0xbf
        case 0xe1...0xec, 0xee...0xef: n = 3; lower = 0x80; upper = 0xbf
        case 0xed: n = 3; lower = 0x80; upper = 0x9f
        case 0xf0: n = 4; lower = 0x90; upper = 0xbf
        case 0xf1...0xf3: n = 4; lower = 0x80; upper = 0xbf
        case 0xf4: n = 4; lower = 0x80; upper = 0x8f
        default: return false
        }
        guard i + n <= a.count, a[i + 1] >= lower, a[i + 1] <= upper else { return false }
        for j in 2..<n where a[i + j] < 0x80 || a[i + j] > 0xbf { return false }
        i += n
    }
    return true
}

var checked = 0
var valid = 0
func check(_ a: [UInt8]) {
    let expected = isStrictUTF8(a)
    let prior = String(validating: a, as: UTF8.self) != nil
    let direct = String(bytes: a, encoding: .utf8) != nil
    let padded: [UInt8] = [0xff, 0xff, 0xff] + a + [0xff, 0xff]
    let slice = padded[3..<(3 + a.count)]
    let changedCall = String(bytes: slice, encoding: .utf8) != nil
    precondition(expected == prior && expected == direct && expected == changedCall,
                 "UTF8 validation disagreement: \(a.map { String($0, radix: 16) })")
    checked += 1
    if expected { valid += 1 }
}

check([])
for a in UInt8.min...UInt8.max {
    check([a])
    for b in UInt8.min...UInt8.max { check([a, b]) }
}
let boundary: [UInt8] = [0, 0x7f, 0x80, 0x8f, 0x90, 0x9f, 0xa0, 0xbf, 0xc0, 0xff]
for a in UInt8.min...UInt8.max {
    for b in boundary {
        for c in boundary {
            check([a, b, c])
            for d in boundary { check([a, b, c, d]) }
        }
    }
}
let fixtures: [[UInt8]] = [
    [0xef, 0xbb, 0xbf], [0, 0xef, 0xbb, 0xbf, 0],
    [0xef, 0xbf, 0xbd], [0xf4, 0x8f, 0xbf, 0xbf],
    [0x61, 0xc3, 0xa9, 0, 0xf0, 0x9f, 0x92, 0xa1, 0x7f],
    [0, 0xff], [0xef, 0xbb, 0xbf, 0xff],
    [0x61, 0xe2, 0x82], [0x61, 0xc0, 0xaf],
    [0x61, 0xed, 0xa0, 0x80], [0xf4, 0x90, 0x80, 0x80]
]
for a in fixtures { check(a) }
var random: UInt64 = 0x8333100
for n in 0..<100_000 {
    var a: [UInt8] = []
    for _ in 0..<(n % 33) {
        random = random &* 6364136223846793005 &+ 1442695040888963407
        a.append(UInt8(truncatingIfNeeded: random >> 32))
    }
    check(a)
}
print("PASS: \(checked) deterministic byte sequences; \(valid) valid; Foundation direct/nonzero slice, prior Swift initializer and independent strict oracle agree on acceptance.")
print("Includes all one/two-byte sequences, boundary triples/quads, BOM, embedded NUL, invalid suffix after NUL/BOM, truncation, overlong encodings, surrogate and out-of-range encodings.")
print("Validation-only comparison; production discards decoded string. Linux Foundation is not Apple runtime validation.")
