import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class RecordingViewModel {
    var messages: [StreamMessage] = []
    var inputText: String = ""
    var isSubmitting: Bool = false
    var isRecording: Bool = false
    var liveTranscript: String = ""
    var errorMessage: String?
    var summary: StatsSummary?

    let env: AppEnvironment
    let repository: LedgerRepository
    let stats: StatsService

    init(env: AppEnvironment, repository: LedgerRepository, stats: StatsService) {
        self.env = env
        self.repository = repository
        self.stats = stats
    }

    func load() {
        do {
            let entries = Array(try repository.recentInputEntries(limit: 50).reversed())
            messages = []
            messages.append(.init(kind: .dayDivider(label: "Today")))
            for e in entries {
                messages.append(.init(kind: .userBubble(text: e.rawText, source: e.source, time: e.createdAt)))
                if let card = try? buildGroupCard(for: e) {
                    messages.append(.init(kind: .group(card)))
                }
            }
            summary = try stats.summary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await runSubmission(rawText: trimmed, source: .text)
        inputText = ""
    }

    func startRecording() async {
        guard await env.speech.requestAuthorization() else {
            errorMessage = L("Microphone or speech permission denied. Use the text input or open Settings.")
            return
        }
        do {
            isRecording = true
            liveTranscript = ""
            try await env.speech.startRecording(locale: LocalizationManager.shared.resolvedLocale) { [weak self] partial in
                Task { @MainActor in self?.liveTranscript = partial }
            }
        } catch {
            isRecording = false
            errorMessage = String(format: L("Couldn't start recording: %@"), error.localizedDescription)
        }
    }

    func stopRecordingAndSubmit() async {
        guard isRecording else { return }
        isRecording = false
        do {
            let transcript = try await env.speech.stop()
            liveTranscript = ""
            guard !transcript.isEmpty else {
                errorMessage = L("No speech detected. Tap to retry.")
                return
            }
            await runSubmission(rawText: transcript, source: .voice)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelRecording() {
        env.speech.cancel()
        isRecording = false
        liveTranscript = ""
    }

    private func runSubmission(rawText: String, source: InputSource) async {
        let maybeProvider: AIProvider?
        do { maybeProvider = try env.defaultProvider() }
        catch { errorMessage = L("No active AI provider — open Settings to add one."); return }
        guard let provider = maybeProvider else {
            errorMessage = L("No active AI provider — open Settings to add one.")
            return
        }
        let key: String
        do { key = try env.keychain.get(account: provider.id.uuidString) ?? "" }
        catch { errorMessage = String(format: L("Couldn't read API key: %@"), error.localizedDescription); return }
        guard !key.isEmpty else {
            errorMessage = String(format: L("Missing API key for %@ — open provider settings."), provider.displayName)
            return
        }

        messages.append(.init(kind: .userBubble(text: rawText, source: source, time: .now)))
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let context = try makeParsingContext(defaultCurrency: "CNY")
            let parsed = try await env.parser.parse(input: rawText, apiKey: key, baseURL: provider.baseURL, model: provider.modelName, context: context)
            let result = try repository.save(input: rawText, source: source, providerID: provider.id, parsed: parsed)
            if let entry = try repository.recentInputEntries(limit: 1).first, entry.id == result.inputEntryID {
                let card = try buildGroupCard(for: entry, overrideFailed: result.failedItems)
                messages.append(.init(kind: .group(card)))
            }
            summary = try stats.summary()
        } catch let e as AIParsingError {
            errorMessage = describe(e)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func describe(_ e: AIParsingError) -> String {
        switch e {
        case .missingAPIKey: return L("Provider is missing an API key.")
        case .missingProvider: return L("No AI provider is configured.")
        case .invalidJSON: return L("AI response wasn't valid JSON.")
        case .providerFailure(let s): return String(format: L("Provider error: %@"), s)
        }
    }

    private func makeParsingContext(defaultCurrency: String) throws -> ParsingContext {
        let ctx = env.container.mainContext
        let archived = false
        let cats = try ctx.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.isArchived == archived }))
        let nameByID = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
        let refs = cats.map { ParsingContext.CategoryRef(id: $0.id, name: $0.name, parentName: $0.parentID.flatMap { nameByID[$0] }) }
        let tags = try ctx.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { $0.isArchived == archived })).map(\.name)
        let pays = try ctx.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.isArchived == archived })).map(\.name)
        return ParsingContext(now: .now, timeZone: .current, locale: LocalizationManager.shared.resolvedLocale, defaultCurrency: defaultCurrency, categories: refs, tags: tags, paymentMethods: pays)
    }

    private func buildGroupCard(for entry: InputEntry, overrideFailed: [ParsedFailure]? = nil) throws -> GroupCardModel {
        let txns = try repository.transactions(for: entry)
        let rows: [TransactionRowModel] = try txns.map { t in
            let cat = try repository.category(id: t.categoryID)
            let sub = try t.subcategoryID.flatMap { try repository.category(id: $0) }
            let pay = try repository.paymentMethod(id: t.paymentMethodID)
            let tags = try repository.tags(ids: t.tagIDs).map(\.name)
            return TransactionRowModel(
                id: t.id, amount: t.amount, currency: t.currency, type: t.type,
                title: t.title, merchant: t.merchant, occurredAt: t.occurredAt,
                categoryName: cat?.name ?? "Other", iconKey: cat?.iconKey ?? "other",
                subcategoryName: sub?.name, tagNames: tags, paymentName: pay?.name ?? "—"
            )
        }
        let totalSpent = rows.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let totalIncome = rows.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        let summary = makeSummary(
            spent: totalSpent,
            income: totalIncome,
            expenseCount: rows.filter { $0.type == .expense }.count,
            incomeCount: rows.filter { $0.type == .income }.count,
            currency: rows.first?.currency ?? "CNY"
        )
        return GroupCardModel(
            inputEntryID: entry.id, source: entry.source, when: entry.createdAt,
            summary: summary, transactions: rows, failed: overrideFailed ?? []
        )
    }

    private func makeSummary(spent: Decimal, income: Decimal, expenseCount: Int, incomeCount: Int, currency: String) -> String {
        var parts: [String] = []
        if expenseCount > 0 { parts.append("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")") }
        if incomeCount > 0 { parts.append("\(incomeCount) income") }
        let net = income - spent
        let sign = net >= 0 ? "+" : ""
        let amountStr = "\(currency) \(sign)\(net)"
        return parts.joined(separator: " · ") + " · " + amountStr
    }
}
