import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            RecordingView()
        }
        .tint(Theme.primary)
    }
}

// Stubs — replaced by later tasks
struct StatsView: View { var body: some View { Text("Stats").foregroundStyle(.white) } }
struct SettingsView: View { var body: some View { Text("Settings").foregroundStyle(.white) } }
