import SwiftUI

struct RootView: View {
    @State private var localization = LocalizationManager.shared
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = AppearancePreference.system.rawValue

    private var appearance: AppearancePreference {
        AppearancePreference(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            RecordingView()
        }
        .environment(\.locale, localization.resolvedLocale)
        .preferredColorScheme(appearance.colorScheme)
        .tint(Theme.primary)
    }
}
