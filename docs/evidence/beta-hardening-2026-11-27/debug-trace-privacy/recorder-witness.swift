import Foundation
@MainActor
final class StudioTextInputTrace {
    static let environmentKey = "KEYFILL_UI_TEXT_INPUT_TRACE"
    static let maximumProcessRecords = 512
    static let maximumControlRecords = 256
    let isEnabled: Bool

    enum Event: String, Encodable {
        case identityChange, configureInitialValue, configureExternalReset, keyboardConfigurationChanged, enabledChanged
        case invalidate, windowChanged, delegateEdit, delegateEditIgnored, delegateEditAccepted
        case focusBegan, focusBeganIgnored, focusBindingTrue, focusEnded, focusEndedIgnored
        case focusEndWriteIgnored, focusBindingFalse, submit, submitIgnored, submitLifecycleChanged
        case editingChanged, publishIgnored, publishBegin, publishExternalReset, publishUnchanged
        case bindingWrite, bindingReadback, publishLifecycleChanged, replaceNativeText
        case focusLifecycleChanged, focusRequestUnconfigured, focusRequest, focusMissingWindow, focusResult
        case controlLimit, processLimit
    }

    struct State: Encodable {
        let configured, enabled, firstResponder, inWindow, markedText: Bool
        let applyingConfiguration, replacingText, synchronizingFocus: Bool
        let nativeUTF16, modelUTF16, bindingUTF16, replacementUTF16: Int?
        let bindingMatchesNative, requestedFocus: Bool?
        let rangeLocation, rangeLength: Int?
    }

    private struct Record: Encodable {
        let version = 1
        let sequence, control: Int
        let lifecycle: UUID
        let epochSeconds: TimeInterval
        let field: String
        let event: Event
        let state: State?
    }

    private var nextControl = 0
    private var processCount = 0
    private var controlCounts: [Int: Int] = [:]
    private let sink: (String) -> Void

    init(isEnabled: Bool, sink: @escaping (String) -> Void = { print($0) }) {
        self.isEnabled = isEnabled
        self.sink = sink
    }

    func makeControlID() -> Int {
        nextControl += 1
        return nextControl
    }

    func canRecord(control: Int) -> Bool {
        isEnabled && processCount < Self.maximumProcessRecords &&
            controlCounts[control, default: 0] < Self.maximumControlRecords
    }

    func record(control: Int, lifecycle: UUID, identifier: String?, event: Event, state: () -> State) {
        guard canRecord(control: control) else { return }
        let count = controlCounts[control, default: 0]
        // Limits include their one terminal marker. After either marker, no
        // additional record for that budget is encoded or emitted.
        let emitted: Event
        if processCount == Self.maximumProcessRecords - 1 { emitted = .processLimit }
        else if count == Self.maximumControlRecords - 1 { emitted = .controlLimit }
        else { emitted = event }
        processCount += 1
        controlCounts[control] = count + 1
        let record = Record(sequence: processCount, control: control, lifecycle: lifecycle,
                            epochSeconds: Date().timeIntervalSince1970,
                            field: Self.fieldName(identifier), event: emitted,
                            state: emitted == .processLimit || emitted == .controlLimit ? nil : state())
        guard let data = try? JSONEncoder().encode(record), let line = String(data: data, encoding: .utf8) else { return }
        sink("KEYFILL_INPUT_TRACE_V1 " + line)
    }

    private static func fieldName(_ identifier: String?) -> String {
        // A private canary in an unexpected identifier must not become output.
        switch identifier {
        case "precisionValue", "projectNameInput", "roomWidth", "roomDepth", "roomHeight",
             "roomSubjectX", "roomSubjectZ", "targetLuxInput": return identifier!
        default: return "other"
        }
    }
}

@main struct RecorderWitness {
    @MainActor static func main() throws {
        var lines: [String] = [], disabledLines: [String] = []
        var collected = 0, disabledCollected = 0
        let trace = StudioTextInputTrace(isEnabled: true, sink: { lines.append($0) })
        let disabled = StudioTextInputTrace(isEnabled: false, sink: { disabledLines.append($0) })
        let state = StudioTextInputTrace.State(configured: true, enabled: true, firstResponder: false, inWindow: false, markedText: false, applyingConfiguration: false, replacingText: false, synchronizingFocus: false, nativeUTF16: 3, modelUTF16: 3, bindingUTF16: nil, replacementUTF16: nil, bindingMatchesNative: nil, requestedFocus: nil, rangeLocation: nil, rangeLength: nil)
        let lifecycle = UUID()
        let first = trace.makeControlID(), second = trace.makeControlID(), third = trace.makeControlID()
        for control in [first, second, third] {
            for _ in 0..<600 {
                trace.record(control: control, lifecycle: lifecycle, identifier: "PRIVATE_IDENTIFIER\ninjected=true", event: .editingChanged) { collected += 1; return state }
                disabled.record(control: control, lifecycle: lifecycle, identifier: "precisionValue", event: .editingChanged) { disabledCollected += 1; return state }
            }
        }
        precondition(disabledLines.isEmpty && disabledCollected == 0)
        precondition(collected == 510)
        let prefix = "KEYFILL_INPUT_TRACE_V1 "
        let records: [[String: Any]] = try lines.map { line in
            precondition(line.hasPrefix(prefix) && !line.contains("PRIVATE_IDENTIFIER") && !line.contains("\n"))
            guard let record = try JSONSerialization.jsonObject(with: Data(line.dropFirst(prefix.count).utf8)) as? [String: Any] else { fatalError("Nonobject record") }
            let allowed = Set(["version", "sequence", "control", "lifecycle", "epochSeconds", "field", "event", "state"])
            precondition(Set(record.keys).isSubset(of: allowed))
            precondition(record["uptime"] == nil)
            precondition((record["epochSeconds"] as? Double)?.isFinite == true)
            precondition(record["field"] as? String == "other")
            return record
        }
        precondition(records.count == 512)
        precondition(records.compactMap { $0["sequence"] as? Int } == Array(1...512))
        precondition(records.filter { $0["control"] as? Int == first }.count == 256)
        precondition(records.filter { $0["control"] as? Int == second }.count == 256)
        precondition(records.filter { $0["control"] as? Int == third }.count == 0)
        precondition(records.filter { $0["event"] as? String == "controlLimit" }.count == 1)
        precondition(records.filter { $0["event"] as? String == "processLimit" }.count == 1)
        precondition(records.last?["event"] as? String == "processLimit")
        precondition(records.last?["state"] == nil)
        print("PASS: 512 real recorder JSON records omit uptime and retain finite epochSeconds, sequential order, allowlist, cap markers, lazy state collection and disabled no-op behavior.")
        print("Scope: extracted actual recorder; Apple OSLog singleton omitted; no UIKit/native/simulator/binary privacy acceptance claimed.")
    }
}
