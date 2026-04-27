import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    static let storageKey = "appearancePreference"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var displayKey: LocalizedStringResource {
        switch self {
        case .system: return "appearance.followSystem"
        case .light: return "appearance.light"
        case .dark: return "appearance.dark"
        }
    }
}
