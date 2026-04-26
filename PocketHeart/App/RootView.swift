import SwiftUI

struct RootView: View {
    @State private var localization = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            RecordingView()
        }
        .environment(\.locale, localization.resolvedLocale)
        .tint(Theme.primary)
    }
}
