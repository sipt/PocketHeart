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
struct SettingsView: View { var body: some View { Text("Settings").foregroundStyle(.white) } }
