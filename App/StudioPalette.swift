import SwiftUI
import UIKit

/// UIKit is the source of truth so native tests resolve the same adaptive
/// colors used by SwiftUI on grouped surfaces and the fixed dark Plan.
@MainActor
enum StudioPalette {
    static let actionUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 120 / 255, green: 183 / 255, blue: 1, alpha: 1)
            : UIColor(red: 0, green: 86 / 255, blue: 179 / 255, alpha: 1)
    }
    static let action = Color(uiColor: actionUIColor)

    static let secondaryTextUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 184 / 255, green: 187 / 255, blue: 195 / 255, alpha: 1)
            : UIColor(red: 81 / 255, green: 84 / 255, blue: 92 / 255, alpha: 1)
    }
    static let secondaryText = Color(uiColor: secondaryTextUIColor)

    /// Explicit text on the action fill; system prominent-button foregrounds
    /// otherwise choose white even when the dark-appearance fill is pale blue.
    static let prominentActionTextUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .white
    }
    static let prominentActionText = Color(uiColor: prominentActionTextUIColor)

    /// Error text and custom destructive icons share a text-safe opaque red.
    /// Native alert actions retain their system destructive role and styling.
    static let destructiveUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 159 / 255, blue: 153 / 255, alpha: 1)
            : UIColor(red: 180 / 255, green: 35 / 255, blue: 24 / 255, alpha: 1)
    }
    static let destructive = Color(uiColor: destructiveUIColor)

    /// Dark amber keeps the selected checkmark and equipment icon visible on
    /// light grouped rows, including their translucent amber backgrounds.
    static let selectionUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.65, blue: 0.30, alpha: 1)
            : UIColor(red: 0.55, green: 0.32, blue: 0.08, alpha: 1)
    }
    static let selection = Color(uiColor: selectionUIColor)

    /// The Plan stays dark in both appearances, so its light marks stay bright.
    static let planLightUIColor = UIColor(red: 0.96, green: 0.65, blue: 0.30, alpha: 1)
    static let planLight = Color(uiColor: planLightUIColor)
    static let planBackgroundUIColor = UIColor(red: 0.075, green: 0.085, blue: 0.10, alpha: 1)
    static let planBackground = Color(uiColor: planBackgroundUIColor)
}
