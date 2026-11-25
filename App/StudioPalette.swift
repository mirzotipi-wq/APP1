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
