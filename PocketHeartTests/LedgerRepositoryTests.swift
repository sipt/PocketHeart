import Testing
import Foundation
import SwiftData
@testable import PocketHeart

@MainActor
@Suite(.serialized)
struct LedgerRepositoryTests {
    // Deviation: retain containers so ModelContext weak-ref stays alive
    nonisolated(unsafe) private static var _containers: [ModelContainer] = []

    private func makeRepo() -> (LedgerRepository, ModelContext) {
        let container = AppContainer.make(inMemory: true)
        Self._containers.append(container)
        let ctx = container.mainContext
        return (LedgerRepository(context: ctx), ctx)
    }

    @Test func savesValidParsedTransactionAndReusesExistingTaxonomy() throws {
        let (repo, ctx) = makeRepo()
        let parsed = ParsedTransaction(
            amount: Decimal(string: "38"), currency: "CNY", type: .expense,
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            categoryPath: "Food > Lunch", tagNames: ["work"],
            paymentMethodName: "WeChat Pay", notes: nil
        )
        let result = try repo.save(input: "lunch", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        #expect(result.savedTransactionIDs.count == 1)
        let foodCount = try ctx.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.name == "Food" })).count
        #expect(foodCount == 1)
    }

    @Test func createsAITaxonomyWhenMissing() throws {
        let (repo, ctx) = makeRepo()
        let parsed = ParsedTransaction(
            amount: Decimal(12), currency: "CNY", type: .expense,
            occurredAt: .now, categoryPath: "Drinks", tagNames: ["new"],
            paymentMethodName: "Alipay Mini", notes: nil
        )
        _ = try repo.save(input: "boba", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        let drinks = try ctx.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.name == "Drinks" }))
        let pay = try ctx.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.name == "Alipay Mini" }))
        #expect(drinks.first?.isAICreated == true)
        #expect(pay.first?.isAICreated == true)
    }

    @Test func failsTransactionWithoutAmountAsPartialFailure() throws {
        let (repo, _) = makeRepo()
        let parsed = ParsedTransaction(
            amount: nil, currency: "CNY", type: .expense, occurredAt: nil,
            categoryPath: "Food", tagNames: [], paymentMethodName: "Cash", notes: nil
        )
        let result = try repo.save(input: "?", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        #expect(result.savedTransactionIDs.isEmpty)
        #expect(result.failedItems.first?.reason.contains("amount") == true)
    }

    @Test func missingTimeFallsBackToNow() throws {
        let (repo, ctx) = makeRepo()
        let before = Date()
        let parsed = ParsedTransaction(
            amount: Decimal(5), currency: "CNY", type: .expense, occurredAt: nil,
            categoryPath: "Food", tagNames: [], paymentMethodName: "Cash", notes: nil
        )
        _ = try repo.save(input: "x", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        let txn = try ctx.fetch(FetchDescriptor<Transaction>()).first!
        #expect(txn.occurredAt >= before)
    }

    @Test func editTransactionUpdatesUpdatedAt() async throws {
        let (repo, ctx) = makeRepo()
        let parsed = ParsedTransaction(
            amount: Decimal(10), currency: "CNY", type: .expense, occurredAt: .now,
            categoryPath: "Food", tagNames: [], paymentMethodName: "Cash", notes: "old"
        )
        _ = try repo.save(input: "x", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        var txn = try ctx.fetch(FetchDescriptor<Transaction>()).first!
        let originalUpdated = txn.updatedAt
        try? await Task.sleep(nanoseconds: 5_000_000)
        try repo.update(txn) { $0.notes = "new" }
        txn = try ctx.fetch(FetchDescriptor<Transaction>()).first!
        #expect(txn.notes == "new")
        #expect(txn.updatedAt > originalUpdated)
    }

    @Test func inputEntryPaginationReturnsLatestAndOlderPages() throws {
        let (repo, ctx) = makeRepo()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        for index in 0..<5 {
            ctx.insert(InputEntry(
                rawText: "entry \(index)",
                source: .text,
                createdAt: base.addingTimeInterval(TimeInterval(index))
            ))
        }
        try ctx.save()

        let latest = try repo.latestInputEntries(limit: 2)
        #expect(latest.map(\.rawText) == ["entry 4", "entry 3"])

        let older = try repo.inputEntries(before: latest.last!.createdAt, limit: 2)
        #expect(older.map(\.rawText) == ["entry 2", "entry 1"])

        let oldest = try repo.inputEntries(before: older.last!.createdAt, limit: 2)
        #expect(oldest.map(\.rawText) == ["entry 0"])

        let empty = try repo.inputEntries(before: oldest.last!.createdAt, limit: 2)
        #expect(empty.isEmpty)
    }
}
