import Foundation
import LightingCore

enum StudioPreferences {
    static let unitsKey = "keyfill.measurementUnits"
    static let appearanceKey = "keyfill.appearance"
    /// Only an explicit dismissal hides first-use guidance across launches.
    static let welcomeDismissedKey = "keyfill.welcomeDismissed"

    /// UI automation never changes the user's actual preferences.
    static let defaults: UserDefaults = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            let identifier = ProcessInfo.processInfo.environment["KEYFILL_UI_TEST_ID"]
                .flatMap(UUID.init(uuidString:)) ?? UUID()
            guard let isolated = UserDefaults(suiteName: "KeyAndFill-UITests-" + identifier.uuidString) else {
                preconditionFailure("Isolated UI-test preferences could not be created.")
            }
            return isolated
        }
        #endif
        return .standard
    }()

    static func units(from rawValue: String) -> PlanUnits {
        PlanUnits(rawValue: rawValue) ?? .metric
    }
}
