import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case zhHans = "zh-Hans"
    case en

    var id: String { rawValue }

    var explicitLocale: Locale? {
        switch self {
        case .system: return nil
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .en:     return Locale(identifier: "en")
        }
    }

    func resolvedLocale(preferredLocalizations: [String]) -> Locale {
        if let explicitLocale { return explicitLocale }
        return Locale(identifier: preferredLocalizations.first ?? "en")
    }

    var displayKey: LocalizedStringResource {
        switch self {
        case .system: return "language.followSystem"
        case .zhHans: return "language.zhHans"
        case .en:     return "language.en"
        }
    }
}

@MainActor
@Observable
final class LocalizationManager {
    static let storageKey = "appLanguage"
    static let shared = LocalizationManager()

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: raw) {
            self.language = lang
        } else {
            self.language = .system
        }
    }

    var resolvedLocale: Locale {
        language.resolvedLocale(preferredLocalizations: Bundle.main.preferredLocalizations)
    }
}

@MainActor
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, locale: LocalizationManager.shared.resolvedLocale)
}
