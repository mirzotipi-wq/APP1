import SwiftUI
import UIKit

/// Opaque text colors keep small controls readable on grouped surfaces in
/// either appearance, including where a native material sits behind them.
enum StudioPalette {
    static let action = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 120 / 255, green: 183 / 255, blue: 1, alpha: 1)
            : UIColor(red: 0, green: 86 / 255, blue: 179 / 255, alpha: 1)
    })

    static let secondaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 184 / 255, green: 187 / 255, blue: 195 / 255, alpha: 1)
            : UIColor(red: 81 / 255, green: 84 / 255, blue: 92 / 255, alpha: 1)
    })

    static let planBackground = Color(red: 0.075, green: 0.085, blue: 0.10)
}
