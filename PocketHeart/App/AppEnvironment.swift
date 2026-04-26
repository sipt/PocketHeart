import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let container: ModelContainer
    let repository: LedgerRepository
    let stats: StatsService
    let speech: SpeechServiceProtocol
    let parser: AIParsingServiceProtocol
    let keychain: Keychain

    init(container: ModelContainer,
         speech: SpeechServiceProtocol? = nil,
         parser: AIParsingServiceProtocol? = nil,
         keychain: Keychain = .providers) {
        self.container = container
        self.repository = LedgerRepository(context: container.mainContext)
        self.stats = StatsService(context: container.mainContext)
        self.speech = speech ?? SpeechService()
        self.parser = parser ?? AIParsingService(adapter: AdapterFactory.adapter(for: .openAICompatible))
        self.keychain = keychain
    }

    func defaultProvider() throws -> AIProvider? {
        let providers = try container.mainContext.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.isDefault == true }))
        return providers.first
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment? = nil
}

extension EnvironmentValues {
    var appEnv: AppEnvironment? {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
