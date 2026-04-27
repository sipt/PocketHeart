import SwiftUI
import UIKit

enum Theme {
    static let bg = adaptive(light: .systemGroupedBackground, dark: .black)
    static let surface = adaptive(
        light: .secondarySystemGroupedBackground,
        dark: UIColor(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255, alpha: 1)
    )
    static let surfaceElevated = adaptive(
        light: .systemBackground,
        dark: UIColor(red: 0x15/255, green: 0x15/255, blue: 0x1C/255, alpha: 1)
    )
    static let primary = Color(red: 0x7B/255, green: 0x61/255, blue: 0xFF/255)
    static let primaryLight = adaptive(
        light: UIColor(red: 0x5C/255, green: 0x45/255, blue: 0xD9/255, alpha: 1),
        dark: UIColor(red: 0xB5/255, green: 0xA4/255, blue: 0xFF/255, alpha: 1)
    )
    static let danger = Color(red: 0xFF/255, green: 0x45/255, blue: 0x3A/255)
    static let success = Color(red: 0x30/255, green: 0xD1/255, blue: 0x58/255)
    static let warning = Color(red: 0xF2/255, green: 0xC9/255, blue: 0x4C/255)

    static let textPrimary = adaptive(light: .label, dark: .white)
    static let textSecondary = adaptive(light: .secondaryLabel, dark: UIColor.white.withAlphaComponent(0.5))
    static let textMuted = adaptive(light: .tertiaryLabel, dark: UIColor.white.withAlphaComponent(0.4))
    static let separator = adaptive(light: UIColor.black.withAlphaComponent(0.12), dark: UIColor.white.withAlphaComponent(0.08))
    static let surfaceBorder = adaptive(light: UIColor.black.withAlphaComponent(0.10), dark: UIColor.white.withAlphaComponent(0.16))
    static let controlStroke = adaptive(light: UIColor.black.withAlphaComponent(0.12), dark: UIColor.white.withAlphaComponent(0.10))
    static let pillFill = adaptive(light: UIColor.black.withAlphaComponent(0.05), dark: UIColor.white.withAlphaComponent(0.08))
    static let onPrimary = Color.white

    static let cornerCard: CGFloat = 14
    static let cornerLarge: CGFloat = 16

    static let monoFont = Font.system(.caption, design: .monospaced)

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
