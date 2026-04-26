import Testing
@testable import PocketHeart

struct EnumsTests {
    @Test func transactionTypeRoundTripsRaw() {
        #expect(TransactionType(rawValue: "expense") == .expense)
        #expect(TransactionType(rawValue: "income") == .income)
    }

    @Test func parseStatusCases() {
        #expect(ParseStatus.allCases.count == 4)
    }
}

import Foundation
import SwiftData

struct TransactionModelTests {
    @Test func transactionStoresPositiveDecimalAmount() throws {
        let txn = Transaction(
            amount: Decimal(string: "38.50")!,
            currency: "CNY",
            type: .expense,
            title: "Lunch",
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            categoryID: UUID(),
            paymentMethodID: UUID(),
            sourceInputID: UUID()
        )
        #expect(txn.amount == Decimal(string: "38.50"))
        #expect(txn.type == .expense)
        #expect(txn.id != UUID_NULL)
    }
}

private let UUID_NULL = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

struct SeedingTests {
    @Test @MainActor func seedingCreatesBuiltInTaxonomyOnce() throws {
        let container = AppContainer.make(inMemory: true)
        let ctx = container.mainContext
        let cats = try ctx.fetch(FetchDescriptor<LedgerCategory>())
        let pays = try ctx.fetch(FetchDescriptor<PaymentMethod>())
        #expect(cats.count == SeedData.categories.count)
        #expect(pays.count == SeedData.paymentMethods.count)
    }
}
