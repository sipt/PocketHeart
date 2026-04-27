import Testing
import Foundation
import SwiftData
@testable import PocketHeart

@MainActor
@Suite(.serialized)
struct StatsServiceTests {
    nonisolated(unsafe) private static var _containers: [ModelContainer] = []

    private func makeContainer() -> ModelContainer {
        let c = AppContainer.make(inMemory: true)
        Self._containers.append(c)
        return c
    }

    @Test func todayAndMonthTotalsExcludeIncome() throws {
        let container = makeContainer()
        let ctx = container.mainContext
        let stats = StatsService(context: ctx)
        let cat = try ctx.fetch(FetchDescriptor<LedgerCategory>()).first!.id
        let pay = try ctx.fetch(FetchDescriptor<PaymentMethod>()).first!.id
        let now = Date()
        ctx.insert(Transaction(amount: 10, currency: "CNY", type: .expense, occurredAt: now, categoryID: cat, paymentMethodID: pay, sourceInputID: UUID()))
        ctx.insert(Transaction(amount: 100, currency: "CNY", type: .income, occurredAt: now, categoryID: cat, paymentMethodID: pay, sourceInputID: UUID()))
        try ctx.save()
        let s = try stats.summary(now: now, calendar: Calendar(identifier: .gregorian))
        #expect(s.todaySpent == 10)
        #expect(s.monthIncome == 100)
        #expect(s.monthSpent == 10)
    }

    @Test func categoryShareSumsToMonthSpent() throws {
        let container = makeContainer()
        let ctx = container.mainContext
        let stats = StatsService(context: ctx)
        let categories = try ctx.fetch(FetchDescriptor<LedgerCategory>())
        let pay = try ctx.fetch(FetchDescriptor<PaymentMethod>()).first!.id
        let now = Date()
        for (i, cat) in categories.prefix(3).enumerated() {
            ctx.insert(Transaction(amount: Decimal(10 * (i+1)), currency: "CNY", type: .expense, occurredAt: now, categoryID: cat.id, paymentMethodID: pay, sourceInputID: UUID()))
        }
        try ctx.save()
        let s = try stats.summary(now: now, calendar: .init(identifier: .gregorian))
        let sum = s.categoryShare.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(sum == s.monthSpent)
    }
}
