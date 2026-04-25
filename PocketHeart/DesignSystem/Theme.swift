import SwiftUI

enum Theme {
    static let bg = Color.black
    static let surface = Color(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255)
    static let surfaceElevated = Color(red: 0x15/255, green: 0x15/255, blue: 0x1C/255)
    static let primary = Color(red: 0x7B/255, green: 0x61/255, blue: 0xFF/255)
    static let primaryLight = Color(red: 0xB5/255, green: 0xA4/255, blue: 0xFF/255)
    static let danger = Color(red: 0xFF/255, green: 0x45/255, blue: 0x3A/255)
    static let success = Color(red: 0x30/255, green: 0xD1/255, blue: 0x58/255)
    static let warning = Color(red: 0xF2/255, green: 0xC9/255, blue: 0x4C/255)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textMuted = Color.white.opacity(0.4)
    static let separator = Color.white.opacity(0.08)

    static let cornerCard: CGFloat = 14
    static let cornerLarge: CGFloat = 16

    static let monoFont = Font.system(.caption, design: .monospaced)
}
