import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var localization = LocalizationManager.shared
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = AppearancePreference.system.rawValue

    var body: some View {
        @Bindable var localization = localization

        List {
            Section { NavigationLink("AI providers") { ProviderListView() } }
            Section("Appearance") {
                Picker("Theme", selection: $appearanceRaw) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.displayKey).tag(preference.rawValue)
                    }
                }
            }
            Section("Language") {
                Picker("Language", selection: $localization.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayKey).tag(language)
                    }
                }
            }
            Section("Taxonomy") {
                NavigationLink("Categories") { CategoriesView() }
                NavigationLink("Tags") { TagsView() }
                NavigationLink("Payment methods") { PaymentMethodsView() }
            }
            Section("Sync & Permissions") {
                Label("iCloud sync", systemImage: "icloud").foregroundStyle(Theme.textPrimary)
                Label("Microphone & speech", systemImage: "mic.fill").foregroundStyle(Theme.textPrimary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Settings")
    }
}
