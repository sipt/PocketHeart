import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var localization = LocalizationManager.shared

    var body: some View {
        @Bindable var localization = localization

        List {
            Section { NavigationLink("AI providers") { ProviderListView() } }
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
                Label("iCloud sync", systemImage: "icloud").foregroundStyle(.white)
                Label("Microphone & speech", systemImage: "mic.fill").foregroundStyle(.white)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Settings")
    }
}
