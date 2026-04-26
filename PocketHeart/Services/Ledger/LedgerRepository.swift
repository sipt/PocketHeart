import Foundation
import SwiftData

struct SaveResult {
    var inputEntryID: UUID
    var savedTransactionIDs: [UUID]
    var failedItems: [ParsedFailure]
}

@MainActor
final class LedgerRepository {
    let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func save(
        input rawText: String,
        source: InputSource,
        providerID: UUID?,
        parsed: ParsedInputResult,
        now: Date = .now
    ) throws -> SaveResult {
        let entry = InputEntry(rawText: rawText, source: source, createdAt: now, status: .pending, providerID: providerID)
        context.insert(entry)

        var savedIDs: [UUID] = []
        var failed: [ParsedFailure] = parsed.failed

        for p in parsed.transactions {
            guard let amount = p.amount, amount > 0 else {
                failed.append(.init(raw: p.title, reason: "missing or non-positive amount"))
                continue
            }
            let categoryID = try findOrCreateCategory(name: p.categoryName, applicable: p.type == .income ? .income : .expense)
            let subID: UUID? = try p.subcategoryName.flatMap { try findOrCreateSubcategory(name: $0, parentID: categoryID) }
            let tagIDs = try p.tagNames.map { try findOrCreateTag(name: $0) }
            let payID = try findOrCreatePayment(name: p.paymentMethodName)

            let txn = Transaction(
                amount: amount,
                currency: p.currency ?? "CNY",
                type: p.type,
                title: p.title,
                merchant: p.merchant,
                occurredAt: p.occurredAt ?? now,
                categoryID: categoryID,
                subcategoryID: subID,
                tagIDs: tagIDs,
                paymentMethodID: payID,
                notes: p.notes,
                sourceInputID: entry.id,
                isAICreated: true,
                createdAt: now,
                updatedAt: now
            )
            context.insert(txn)
            savedIDs.append(txn.id)
            for tagID in tagIDs { try bumpTagUsage(tagID) }
        }

        entry.transactionIDs = savedIDs
        entry.status = failed.isEmpty
            ? (savedIDs.isEmpty ? .failure : .success)
            : (savedIDs.isEmpty ? .failure : .partialFailure)
        try context.save()
        return SaveResult(inputEntryID: entry.id, savedTransactionIDs: savedIDs, failedItems: failed)
    }

    func update(_ txn: Transaction, mutate: (Transaction) -> Void) throws {
        mutate(txn)
        txn.updatedAt = .now
        try context.save()
    }

    func delete(_ txn: Transaction) throws {
        context.delete(txn)
        try context.save()
    }

    func latestInputEntries(limit: Int = 25) throws -> [InputEntry] {
        var fd = FetchDescriptor<InputEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        fd.fetchLimit = limit
        return try context.fetch(fd)
    }

    func inputEntries(before date: Date, limit: Int = 25) throws -> [InputEntry] {
        var fd = FetchDescriptor<InputEntry>(
            predicate: #Predicate { $0.createdAt < date },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fd.fetchLimit = limit
        return try context.fetch(fd)
    }

    func recentInputEntries(limit: Int = 50) throws -> [InputEntry] {
        try latestInputEntries(limit: limit)
    }

    func transactions(for entry: InputEntry) throws -> [Transaction] {
        let ids = entry.transactionIDs
        guard !ids.isEmpty else { return [] }
        let fd = FetchDescriptor<Transaction>(predicate: #Predicate { ids.contains($0.id) })
        return try context.fetch(fd)
    }

    func category(id: UUID) throws -> LedgerCategory? {
        try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.id == id })).first
    }
    func paymentMethod(id: UUID) throws -> PaymentMethod? {
        try context.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.id == id })).first
    }
    func tags(ids: [UUID]) throws -> [LedgerTag] {
        guard !ids.isEmpty else { return [] }
        return try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { ids.contains($0.id) }))
    }

    // MARK: - Reuse-or-create

    private func findOrCreateCategory(name: String, applicable: ApplicableType) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate {
            $0.name == trimmed && $0.parentID == nil && $0.isArchived == false
        })).first { return existing.id }
        let new = LedgerCategory(name: trimmed, applicable: applicable, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreateSubcategory(name: String, parentID: UUID) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let parent = parentID
        if let existing = try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate {
            $0.name == trimmed && $0.parentID == parent && $0.isArchived == false
        })).first { return existing.id }
        let new = LedgerCategory(name: trimmed, parentID: parent, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreateTag(name: String) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate {
            $0.name == trimmed && $0.isArchived == false
        })).first { return existing.id }
        let new = LedgerTag(name: trimmed, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreatePayment(name: String) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate {
            $0.name == trimmed && $0.isArchived == false
        })).first { return existing.id }
        let new = PaymentMethod(name: trimmed, kind: .other, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func bumpTagUsage(_ id: UUID) throws {
        let tagID = id
        if let tag = try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { $0.id == tagID })).first {
            tag.usageCount += 1
        }
    }
}
