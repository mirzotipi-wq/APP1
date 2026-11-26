import SwiftUI
import Foundation

/// Diagnostic transport for the actual Text layout. This is not an AX text node.
/// Release builds and every launch without BOTH explicit test switches are unchanged.
enum StudioTextLayoutDiagnostics {
    static let environmentKey = "KEYFILL_UI_TEXT_LAYOUT_PROBES"
    static let valuePrefix = "DEBUG_UI_TEXT_LAYOUT_V1:"

    static var isEnabled: Bool {
        isEnabled(arguments: ProcessInfo.processInfo.arguments,
                  environment: ProcessInfo.processInfo.environment)
    }

    static func isEnabled(arguments: [String], environment: [String: String]) -> Bool {
        #if DEBUG
        return arguments.contains("-ui-testing") && environment[environmentKey] == "1"
        #else
        return false
        #endif
    }

    struct Record: Codable {
        let kind: String
        let probe: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double

        var frame: CGRect {
            CGRect(x: x, y: y, width: width, height: height)
        }
    }

    static func valid(_ frame: CGRect) -> Bool {
        !frame.isEmpty && !frame.isNull && !frame.isInfinite &&
        frame.minX.isFinite && frame.minY.isFinite &&
        frame.maxX.isFinite && frame.maxY.isFinite
    }

    static func value(probe: String, frame: CGRect?) -> String {
        guard let frame, valid(frame) else { return valuePrefix + "pending" }
        let record = Record(kind: "recorded-swiftui-text-layout", probe: probe,
                            x: Double(frame.minX), y: Double(frame.minY),
                            width: Double(frame.width), height: Double(frame.height))
        guard let data = try? JSONEncoder().encode(record),
              let json = String(data: data, encoding: .utf8) else {
            return valuePrefix + "pending"
        }
        return valuePrefix + json
    }

    static func frame(from value: String, probe: String) -> CGRect? {
        guard value.utf8.count <= 1_024, value.hasPrefix(valuePrefix),
              let data = String(value.dropFirst(valuePrefix.count)).data(using: .utf8),
              let record = try? JSONDecoder().decode(Record.self, from: data),
              record.kind == "recorded-swiftui-text-layout", record.probe == probe,
              valid(record.frame) else { return nil }
        return record.frame
    }
}

struct StudioTextLayoutPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

extension View {
    /// Place after the actual font/fixedSize and BEFORE frame expansion or padding.
    /// The background observes that Text; it does not create a second label.
    @ViewBuilder
    func studioTextLayoutProbe(_ probe: String, enabled: Bool? = nil) -> some View {
        #if DEBUG
        if enabled ?? StudioTextLayoutDiagnostics.isEnabled {
            background {
                GeometryReader { geometry in
                    Color.clear.preference(key: StudioTextLayoutPreferenceKey.self,
                                           value: [probe: geometry.frame(in: .global)])
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// The owning Button carries an explicitly tagged test diagnostic value.
    /// No label, action, trait, child grouping or normal-launch value is changed.
    /// The enabled parameter is an internal hosted-test seam; release builds ignore it.
    @ViewBuilder
    func studioTextLayoutValue(_ probe: String, enabled: Bool? = nil) -> some View {
        #if DEBUG
        if enabled ?? StudioTextLayoutDiagnostics.isEnabled {
            modifier(StudioTextLayoutValueModifier(probe: probe))
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#if DEBUG
private struct StudioTextLayoutValueModifier: ViewModifier {
    let probe: String
    @State private var frame: CGRect?

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(StudioTextLayoutPreferenceKey.self) { frames in
                let next = frames[probe].flatMap { StudioTextLayoutDiagnostics.valid($0) ? $0 : nil }
                if frame != next { frame = next }
            }
            .accessibilityValue(Text(StudioTextLayoutDiagnostics.value(probe: probe, frame: frame)))
    }
}
#endif
