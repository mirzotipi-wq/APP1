import Foundation
struct ProjectNameDraft {
    private let initialDisplay: String
    let requiresNewName: Bool
    private(set) var text: String
    private(set) var rejectedOversizedInput = false

    init(initial: String) {
        let bounded = StudioDisplayName.display(initial)
        initialDisplay = bounded
        requiresNewName = bounded != initial
        text = bounded
    }

    var canSubmit: Bool { (try? submittedName()) != nil }

    /// Returns true only for a distinct, bounded edit. A restoration callback
    /// with unchanged text must not clear a preceding rejected-input state.
    @discardableResult
    mutating func update(_ next: String) throws -> Bool {
        guard next.unicodeScalars.prefix(StudioDisplayName.maximumScalars + 1).count <= StudioDisplayName.maximumScalars else {
            rejectedOversizedInput = true
            throw StudioDisplayName.NameError.tooLong
        }
        guard next != text else { return false }
        text = next
        rejectedOversizedInput = false
        return true
    }

    mutating func clear() {
        text = ""
        rejectedOversizedInput = false
    }

    func submittedName() throws -> String {
        guard !rejectedOversizedInput else { throw StudioDisplayName.NameError.tooLong }
        let normalized = try StudioDisplayName.newInput(text)
        guard !requiresNewName || normalized != initialDisplay else { throw DraftError.replacementRequired }
        return normalized
    }

    private enum DraftError: LocalizedError {
        case replacementRequired

        var errorDescription: String? {
            "Enter a new name, or cancel to keep the complete saved name."
        }
    }
}



import Foundation
var assertions = 0
func verify(_ result: @autoclosure () throws -> Bool) rethrows { assertions += 1; let value = try result(); precondition(value) }
func rejection(_ body: () throws -> Void) { assertions += 1; do { try body(); preconditionFailure("Unexpected acceptance") } catch {} }
func bounds(_ s: String) {
    verify(s.count <= StudioDisplayName.maximumCharacters)
    verify(s.unicodeScalars.count <= StudioDisplayName.maximumScalars)
    verify(s.utf8.count <= StudioDisplayName.maximumUTF8Bytes)
}
let millionMarks = "e" + String(repeating: "\u{0301}", count: 1_000_000)
var draft = ProjectNameDraft(initial: "Portrait")
rejection { try draft.update(millionMarks) }
verify(draft.text == "Portrait")
verify(!draft.canSubmit)
verify(draft.rejectedOversizedInput)
try verify(try draft.update("Portrait") == false)
rejection { _ = try draft.submittedName() }
draft.clear()
verify(!draft.canSubmit)
try draft.update("  Studio portrait  ")
try verify(try draft.submittedName() == "Studio portrait")
for value in ["", " \t\n\u{00A0}", "\u{200D}\u{034F}", "\u{2800}"] {
    var candidate = ProjectNameDraft(initial: "")
    try candidate.update(value)
    verify(!candidate.canSubmit)
    rejection { _ = try candidate.submittedName() }
}
for middle in ["\n", "\r", "\t", "\u{0000}", "\u{2028}", "\u{2029}", "\u{202E}", "\u{2066}"] {
    var candidate = ProjectNameDraft(initial: "")
    try candidate.update("Key" + middle + " light")
    verify(!candidate.canSubmit)
    rejection { _ = try candidate.submittedName() }
}
for initial in [millionMarks, String(repeating: "A", count: 100), "Prefix\nLegacy"] {
    var legacy = ProjectNameDraft(initial: initial)
    verify(legacy.requiresNewName)
    bounds(legacy.text)
    verify(!legacy.canSubmit)
    let shown = legacy.text
    try legacy.update(" \t" + shown + " \n")
    verify(!legacy.canSubmit)
    legacy.clear()
    try legacy.update(shown)
    verify(!legacy.canSubmit)
    try legacy.update("Replacement")
    try verify(try legacy.submittedName() == "Replacement")
}
let family = "👩‍👩‍👧‍👦"
for value in [String(repeating: "💡", count: 80), String(repeating: family, count: 45), "نور\u{200C}پردازی", "Cafe\u{0301}"] {
    var candidate = ProjectNameDraft(initial: "")
    try candidate.update(value)
    verify(candidate.canSubmit)
    try verify(try candidate.submittedName() == value)
    bounds(StudioDisplayName.display(value))
}
var canonical = ProjectNameDraft(initial: "Café")
rejection { try canonical.update(millionMarks) }
try verify(try canonical.update("Cafe\u{0301}") == false)
verify(!canonical.canSubmit)
try canonical.update("Café 2")
verify(canonical.canSubmit)
let search = String(millionMarks.unicodeScalars.prefix(StudioDisplayName.maximumScalars))
verify(search.unicodeScalars.count == 320)
verify(search.utf8.count <= 1280)
for suffix in ["", family, "Plain"] { bounds(StudioDisplayName.display(millionMarks + suffix)) }
print("PASS \(assertions) assertions; actual ProjectNameDraft and StudioDisplayName; no UIKit execution")
