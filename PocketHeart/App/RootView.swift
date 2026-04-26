import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            RecordingView()
        }
        .tint(Theme.primary)
    }
}

