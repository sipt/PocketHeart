import SwiftUI
import SwiftData

@main
struct PocketHeartApp: App {
    let env: AppEnvironment

    init() {
        let container = AppContainer.make()
        self.env = AppEnvironment(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnv, env)
                .modelContainer(env.container)
                .preferredColorScheme(.dark)
        }
    }
}
