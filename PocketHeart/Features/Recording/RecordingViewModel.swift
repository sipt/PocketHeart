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
    var isLoadingOlder: Bool = false
    var hasMoreHistory: Bool = false
    var oldestLoadedAt: Date?
    var scrollRequest: RecordingScrollRequest?

    let env: AppEnvironment
    let repository: LedgerRepository
    let stats: StatsService
    private let pageSize = 25
    private var loadedEntries: [InputEntry] = []
    private var failedOverridesByEntryID: [UUID: [ParsedFailure]] = [:]

    init(env: AppEnvironment, repository: LedgerRepository, stats: StatsService) {
        self.env = env
        self.repository = repository
        self.stats = stats
    }

    func load() {
        do {
            let entries = try repository.latestInputEntries(limit: pageSize)
            failedOverridesByEntryID = [:]
            loadedEntries = Array(entries.reversed())
            rebuildMessages()
            updatePaginationState(from: entries)
            summary = try stats.summary()
            requestScrollToBottom(animated: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadOlder() {
        guard !isLoadingOlder, hasMoreHistory, let oldestLoadedAt else { return }
        guard let anchorID = firstLoadedEntryUserBubbleID else { return }

        isLoadingOlder = true
        defer { isLoadingOlder = false }

        do {
            let older = try repository.inputEntries(before: oldestLoadedAt, limit: pageSize)
            guard !older.isEmpty else {
                hasMoreHistory = false
                return
            }

            loadedEntries.insert(contentsOf: Array(older.reversed()), at: 0)
            rebuildMessages()
            self.oldestLoadedAt = loadedEntries.first?.createdAt
            hasMoreHistory = older.count == pageSize
            scrollRequest = RecordingScrollRequest(target: .message(anchorID), animated: false)
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

        messages.append(.init(id: "pending-\(UUID().uuidString)", kind: .userBubble(text: rawText, source: source, time: .now)))
        requestScrollToBottom(animated: true)
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let context = try makeParsingContext(defaultCurrency: "CNY")
            let parsed = try await env.parser.parse(input: rawText, apiKey: key, baseURL: provider.baseURL, model: provider.modelName, context: context)
            let result = try repository.save(input: rawText, source: source, providerID: provider.id, parsed: parsed)
            if let entry = try repository.recentInputEntries(limit: 1).first, entry.id == result.inputEntryID {
                failedOverridesByEntryID[entry.id] = result.failedItems
                appendLoadedEntry(entry)
                requestScrollToBottom(animated: true)
            }
            summary = try stats.summary()
        } catch let e as AIParsingError {
            errorMessage = describe(e)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var firstLoadedEntryUserBubbleID: String? {
        loadedEntries.first.map { userBubbleID(for: $0.id) }
    }

    private func updatePaginationState(from fetchedEntries: [InputEntry]) {
        oldestLoadedAt = loadedEntries.first?.createdAt
        hasMoreHistory = fetchedEntries.count == pageSize
    }

    private func appendLoadedEntry(_ entry: InputEntry) {
        loadedEntries.removeAll { $0.id == entry.id }
        loadedEntries.append(entry)
        loadedEntries.sort {
            if $0.createdAt == $1.createdAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.createdAt < $1.createdAt
        }
        oldestLoadedAt = loadedEntries.first?.createdAt
        rebuildMessages()
    }

    private func rebuildMessages() {
        var next: [StreamMessage] = []
        var currentDay: Date?
        let calendar = Calendar.current

        for entry in loadedEntries {
            let day = calendar.startOfDay(for: entry.createdAt)
            if currentDay != day {
                currentDay = day
                next.append(.init(id: dayDividerID(for: day), kind: .dayDivider(label: dayLabel(for: entry.createdAt, calendar: calendar))))
            }
            next.append(.init(id: userBubbleID(for: entry.id), kind: .userBubble(text: entry.rawText, source: entry.source, time: entry.createdAt)))
            if let card = try? buildGroupCard(for: entry, overrideFailed: failedOverridesByEntryID[entry.id]) {
                next.append(.init(id: groupID(for: entry.id), kind: .group(card)))
            }
        }

        messages = next
    }

    private func requestScrollToBottom(animated: Bool) {
        scrollRequest = RecordingScrollRequest(target: .bottom, animated: animated)
    }

    private func userBubbleID(for entryID: UUID) -> String {
        "entry-\(entryID.uuidString)-user"
    }

    private func groupID(for entryID: UUID) -> String {
        "entry-\(entryID.uuidString)-group"
    }

    private func dayDividerID(for day: Date) -> String {
        "day-\(Int(day.timeIntervalSince1970))"
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return L("Today") }
        return date.formatted(.dateTime.year().month(.abbreviated).day().locale(LocalizationManager.shared.resolvedLocale))
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
