import Foundation
import SwiftData

struct StatsSummary {
    struct Slice { let categoryID: UUID; let categoryName: String; let amount: Decimal; let percent: Double }
    var todaySpent: Decimal
    var monthSpent: Decimal
    var monthIncome: Decimal
    var categoryShare: [Slice]
    var dailyTrend: [Decimal]
}

@MainActor
final class StatsService {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func summary(now: Date = .now, calendar: Calendar = .current) throws -> StatsSummary {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let dayStart = calendar.startOfDay(for: now)
        let cutoff = monthStart

        let monthTxns = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.occurredAt >= cutoff }))

        var todaySpent: Decimal = 0
        var monthSpent: Decimal = 0
        var monthIncome: Decimal = 0
        var byCat: [UUID: Decimal] = [:]
        var trend: [Decimal] = Array(repeating: 0, count: 30)

        for t in monthTxns {
            if t.type == .income { monthIncome += t.amount; continue }
            monthSpent += t.amount
            byCat[t.categoryID, default: 0] += t.amount
            if t.occurredAt >= dayStart { todaySpent += t.amount }
            if let day = calendar.dateComponents([.day], from: t.occurredAt, to: now).day, (0..<30).contains(day) {
                trend[29 - day] += t.amount
            }
        }

        let cats = try context.fetch(FetchDescriptor<LedgerCategory>())
        let nameByID = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
        let totalDouble = NSDecimalNumber(decimal: monthSpent).doubleValue
        let slices = byCat.map { id, amt in
            let pct = totalDouble > 0 ? NSDecimalNumber(decimal: amt).doubleValue / totalDouble : 0
            return StatsSummary.Slice(categoryID: id, categoryName: nameByID[id] ?? "Other", amount: amt, percent: pct)
        }.sorted { $0.amount > $1.amount }

        return StatsSummary(todaySpent: todaySpent, monthSpent: monthSpent, monthIncome: monthIncome, categoryShare: slices, dailyTrend: trend)
    }
}
