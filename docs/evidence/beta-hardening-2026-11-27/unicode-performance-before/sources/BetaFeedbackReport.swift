import Foundation

/// A deterministic, plain-text draft. The caller supplies only coarse environment
/// details and optional notes; this type cannot read projects, photographs, files,
/// logs, accounts, identifiers, or the network. It does not persist or send reports.
public struct BetaFeedbackReport: Equatable, Sendable {
    public enum DeviceFamily: String, CaseIterable, Sendable {
        case iPhone
        case iPad
        case other = "Other"
    }

    public enum NoteField: String, CaseIterable, Sendable {
        case problem = "Problem or observation"
        case reproductionSteps = "Steps to reproduce"
        case expectedResult = "Expected result"
    }

    /// Work is bounded in Unicode scalars before grapheme segmentation. A single
    /// pasted grapheme can otherwise contain an arbitrarily large number of marks.
    public static let maximumNoteInputScalars = 8_192
    public static let maximumNoteUTF8Bytes = 2_048
    public static let maximumVersionUTF8Bytes = 64
    public static let maximumReportUTF8Bytes = 8_192

    /// Session-only raw text for one form field. Validate a replacement before
    /// storing it; report cleanup must never silently alter an editable draft.
    public struct NoteDraft: Equatable, Sendable {
        public private(set) var text = ""
        public private(set) var hasLengthError = false

        public init() { }

        public mutating func replaceText(with replacement: String) {
            // Inspect at most the scalar budget plus one lookahead. Character
            // counting or String equality first could traverse a giant grapheme.
            var scanned = 0
            for _ in replacement.unicodeScalars {
                guard scanned < BetaFeedbackReport.maximumNoteInputScalars else {
                    hasLengthError = true
                    return
                }
                scanned += 1
            }
            // A native field may echo the retained text after a rejected paste.
            // That callback is not consent to review the earlier draft. Compare
            // bytes so canonically equivalent edits retain their exact raw form.
            guard !replacement.utf8.elementsEqual(text.utf8) else { return }
            text = replacement
            hasLengthError = false
        }

        /// An explicit user action may acknowledge the retained text, including
        /// an empty field. It neither restores nor stores the rejected input.
        public mutating func keepPreviousText() {
            hasLengthError = false
        }
    }

    public static let contentsNotice = "This report contains app version/build, OS version, device family, and any notes you enter. The app adds no photographs, project or scene contents, account details, network or hardware identifiers, or logs. Check your notes for personal information before sharing."
    public static let simulationNotice = "Lighting previews and reference suggestions are simulations and planning aids. They are not calibrated equipment or camera exposure, and do not establish an exact reconstruction. Confirm results with your equipment, a light meter and test photographs."

    public let appVersion: String
    public let buildVersion: String
    public let operatingSystemVersion: String
    public let deviceFamily: DeviceFamily
    public let problem: String
    public let reproductionSteps: String
    public let expectedResult: String
    public let shortenedFields: [NoteField]
    public let cleanedFields: [NoteField]

    public init(appVersion: String?, buildVersion: String?, operatingSystemVersion: String?,
                deviceFamily: DeviceFamily, problem: String = "",
                reproductionSteps: String = "", expectedResult: String = "") {
        self.appVersion = Self.versionToken(appVersion)
        self.buildVersion = Self.versionToken(buildVersion)
        self.operatingSystemVersion = Self.versionToken(operatingSystemVersion)
        self.deviceFamily = deviceFamily

        let problemNote = Self.cleanNote(problem)
        let stepsNote = Self.cleanNote(reproductionSteps)
        let expectedNote = Self.cleanNote(expectedResult)
        self.problem = problemNote.text
        self.reproductionSteps = stepsNote.text
        self.expectedResult = expectedNote.text
        let notes: [(NoteField, CleanNote)] = [
            (.problem, problemNote), (.reproductionSteps, stepsNote), (.expectedResult, expectedNote)
        ]
        shortenedFields = notes.compactMap { $0.1.shortened ? $0.0 : nil }
        cleanedFields = notes.compactMap { $0.1.cleaned ? $0.0 : nil }
    }

    /// The native preview and ShareLink use this same value. No date, session ID,
    /// device model, scene summary, attachments, or inferred user data is added.
    public var plainText: String {
        """
        Key & Fill — beta feedback

        App version: \(appVersion)
        Build: \(buildVersion)
        OS version: \(operatingSystemVersion)
        Device family: \(deviceFamily.rawValue)

        Problem or observation
        \(noteText(problem, field: .problem))

        Steps to reproduce
        \(noteText(reproductionSteps, field: .reproductionSteps))

        Expected result
        \(noteText(expectedResult, field: .expectedResult))

        Report contents
        \(Self.contentsNotice)

        Simulation and calibration
        \(Self.simulationNotice)
        """
    }

    private func noteText(_ value: String, field: NoteField) -> String {
        let isShortened = shortenedFields.contains(field)
        let text = value.isEmpty ? (isShortened ? "No text included." : "Not provided.") : value
        return isShortened ? text + "\n[Text shortened for this report.]" : text
    }

    /// Version metadata is a bounded token, never free-form report content.
    /// Reject an invalid/oversized token instead of silently changing its identity.
    private static func versionToken(_ input: String?) -> String {
        guard let input, !input.isEmpty else { return "Unavailable" }
        var output = ""
        var count = 0
        var hasDigit = false
        for scalar in input.unicodeScalars {
            guard count < maximumVersionUTF8Bytes else { return "Unavailable" }
            let value = scalar.value
            let digit = (48...57).contains(value)
            let letter = (65...90).contains(value) || (97...122).contains(value)
            guard digit || letter || value == 46 || value == 45 || value == 43 else {
                return "Unavailable"
            }
            hasDigit = hasDigit || digit
            output.unicodeScalars.append(scalar)
            count += 1
        }
        return hasDigit ? output : "Unavailable"
    }

    private struct CleanNote {
        let text: String
        let shortened: Bool
        let cleaned: Bool
    }

    private static func cleanNote(_ input: String) -> CleanNote {
        var iterator = input.unicodeScalars.makeIterator()
        var normalized = ""
        var scanned = 0
        var hitScanLimit = false
        var cleaned = false
        var previousWasCarriageReturn = false
        while let scalar = iterator.next() {
            guard scanned < maximumNoteInputScalars else {
                hitScanLimit = true
                break
            }
            scanned += 1
            let value = scalar.value
            if value == 13 {
                normalized.append("\n")
                previousWasCarriageReturn = true
                cleaned = true
                continue
            }
            if value == 10 {
                if !previousWasCarriageReturn { normalized.append("\n") }
                previousWasCarriageReturn = false
                continue
            }
            previousWasCarriageReturn = false
            if value == 0x85 || value == 0x2028 || value == 0x2029 {
                normalized.append("\n")
                cleaned = true
            } else if value == 9 {
                normalized.append(" ")
                cleaned = true
            } else if isHiddenControl(value) {
                cleaned = true
            } else {
                normalized.unicodeScalars.append(scalar)
            }
        }

        // The scalar boundary may bisect a combining/emoji sequence. Discard its
        // final grapheme conservatively; segmentation now sees at most 8,192 scalars.
        if hitScanLimit && !normalized.isEmpty { normalized.removeLast() }
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned || trimmed != normalized
        var output = ""
        var bytes = 0
        var shortened = hitScanLimit
        for character in trimmed {
            let value = String(character)
            let size = value.utf8.count
            guard size <= maximumNoteUTF8Bytes - bytes else {
                shortened = true
                break
            }
            output.append(contentsOf: value)
            bytes += size
        }
        let text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return CleanNote(text: text, shortened: shortened, cleaned: cleaned || text != output)
    }

    private static func isHiddenControl(_ value: UInt32) -> Bool {
        value < 32 || (0x7F...0x9F).contains(value)
            || value == 0x061C || value == 0x200B || value == 0x200E || value == 0x200F
            || (0x202A...0x202E).contains(value) || (0x2060...0x206F).contains(value)
            || value == 0xFEFF
        // Preserve ZWNJ/ZWJ and variation selectors used by scripts and emoji.
    }
}
