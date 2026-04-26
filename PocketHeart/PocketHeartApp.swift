import SwiftUI
import SwiftData

@main
struct PocketHeartApp: App {
    let container = AppContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
