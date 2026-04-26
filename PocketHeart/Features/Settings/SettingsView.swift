import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        List {
            Section { NavigationLink("AI providers") { ProviderListView() } }
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
