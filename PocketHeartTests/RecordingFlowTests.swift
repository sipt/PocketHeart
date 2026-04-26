import Testing
import Foundation
import SwiftData
@testable import PocketHeart

struct FakeParser: AIParsingServiceProtocol {
    let result: Result<ParsedInputResult, any Error>
    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult {
        try result.get()
    }
}

actor CapturingParser: AIParsingServiceProtocol {
    let result: Result<ParsedInputResult, any Error>
    private(set) var capturedContext: ParsingContext?

    init(result: Result<ParsedInputResult, any Error>) {
        self.result = result
    }

    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult {
        capturedContext = context
        return try result.get()
    }
}

final class FakeSpeech: SpeechServiceProtocol {
    nonisolated(unsafe) var lastLocaleIdentifier: String?

    func requestAuthorization() async -> Bool { true }
    func startRecording(locale: Locale, onPartial: @Sendable @escaping (String) -> Void) async throws {
        lastLocaleIdentifier = locale.identifier
    }
    func stop() async throws -> String { "" }
    func cancel() {}
}

@MainActor
@Suite(.serialized)
struct RecordingViewModelTests {
    nonisolated(unsafe) private static var _containers: [ModelContainer] = []

    private func makeVM(parser: AIParsingServiceProtocol) -> (RecordingViewModel, ModelContext) {
        let container = AppContainer.make(inMemory: true)
        Self._containers.append(container)
        let ctx = container.mainContext
        let provider = AIProvider(displayName: "Fake", baseURL: "https://x/v1", modelName: "m", isDefault: true)
        ctx.insert(provider)
        try? ctx.save()
        try? Keychain.providers.set("KEY", account: provider.id.uuidString)
        let repo = LedgerRepository(context: ctx)
        let stats = StatsService(context: ctx)
        let env = AppEnvironment(container: container, speech: FakeSpeech(), parser: parser)
        let vm = RecordingViewModel(env: env, repository: repo, stats: stats)
        return (vm, ctx)
    }

    @Test func textSubmissionAddsUserBubbleAndGroupCard() async throws {
        let parsed = ParsedTransaction(
            amount: Decimal(38), currency: "CNY", type: .expense, title: "Lunch",
            merchant: nil, occurredAt: Date(), categoryName: "Food",
            subcategoryName: nil, tagNames: ["work"], paymentMethodName: "WeChat Pay", notes: nil
        )
        let (vm, _) = makeVM(parser: FakeParser(result: .success(.init(transactions: [parsed], failed: []))))
        await vm.submitText("lunch 38")
        let kinds = vm.messages.map { $0.kind }
        let hasUser = kinds.contains { if case .userBubble = $0 { return true } else { return false } }
        let hasGroup = kinds.contains { if case .group = $0 { return true } else { return false } }
        #expect(hasUser && hasGroup)
    }

    @Test func parserFailureSurfacesError() async {
        let (vm, _) = makeVM(parser: FakeParser(result: .failure(AIParsingError.invalidJSON("nope"))))
        await vm.submitText("bad")
        #expect(vm.errorMessage != nil)
    }

    @Test func blocksSubmissionWhenNoDefaultProvider() async {
        let container = AppContainer.make(inMemory: true)
        Self._containers.append(container)
        let env = AppEnvironment(container: container, speech: FakeSpeech(), parser: FakeParser(result: .success(.init(transactions: [], failed: []))))
        let vm = RecordingViewModel(env: env, repository: LedgerRepository(context: container.mainContext), stats: StatsService(context: container.mainContext))
        await vm.submitText("anything")
        #expect(vm.errorMessage?.contains("provider") == true)
    }

    @Test func appLanguageResolvesSystemAndExplicitLocales() {
        #expect(AppLanguage.system.resolvedLocale(preferredLocalizations: ["zh-Hans"]).identifier == "zh-Hans")
        #expect(AppLanguage.en.resolvedLocale(preferredLocalizations: ["zh-Hans"]).identifier == "en")
    }

    @Test func recordingUsesSelectedAppLanguageLocale() async {
        let previous = LocalizationManager.shared.language
        defer { LocalizationManager.shared.language = previous }

        let speech = FakeSpeech()
        LocalizationManager.shared.language = .zhHans
        let container = AppContainer.make(inMemory: true)
        Self._containers.append(container)
        let env = AppEnvironment(container: container, speech: speech, parser: FakeParser(result: .success(.init(transactions: [], failed: []))))
        let vm = RecordingViewModel(env: env, repository: LedgerRepository(context: container.mainContext), stats: StatsService(context: container.mainContext))

        await vm.startRecording()

        #expect(speech.lastLocaleIdentifier == "zh-Hans")
    }

    @Test func parsingContextUsesSelectedAppLanguageLocale() async throws {
        let previous = LocalizationManager.shared.language
        defer { LocalizationManager.shared.language = previous }

        let parsed = ParsedTransaction(
            amount: Decimal(12), currency: "CNY", type: .expense, title: "Coffee",
            merchant: nil, occurredAt: Date(), categoryName: "Food",
            subcategoryName: nil, tagNames: [], paymentMethodName: "Cash", notes: nil
        )
        let parser = CapturingParser(result: .success(.init(transactions: [parsed], failed: [])))
        LocalizationManager.shared.language = .zhHans
        let (vm, _) = makeVM(parser: parser)

        await vm.submitText("coffee 12")

        let localeID = await parser.capturedContext?.locale.identifier
        #expect(localeID == "zh-Hans")
    }
}
