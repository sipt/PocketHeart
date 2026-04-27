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
                failed.append(.init(raw: p.notes ?? p.categoryPath, reason: "missing or non-positive amount"))
                continue
            }
            let applicable: ApplicableType = p.type == .income ? .income : .expense
            let categoryID = try resolveCategoryPath(p.categoryPath, applicable: applicable)
            let tagIDs = try p.tagNames.map { try findOrCreateTag(name: $0) }
            let payID = try findOrCreatePayment(name: p.paymentMethodName)

            let txn = Transaction(
                amount: amount,
                currency: p.currency ?? "CNY",
                type: p.type,
                occurredAt: p.occurredAt ?? now,
                categoryID: categoryID,
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

    /// Resolves a "Parent > Leaf" path (or a single name) to a leaf category id.
    /// Reuses existing categories at each level and creates missing nodes as AI-created.
    private func resolveCategoryPath(_ path: String, applicable: ApplicableType) throws -> UUID {
        let parts = path.split(separator: ">").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !parts.isEmpty else {
            return try findOrCreateRootCategory(name: "Other", applicable: applicable)
        }
        var parentID: UUID? = nil
        var lastID: UUID = UUID()
        for (i, name) in parts.enumerated() {
            let isLeaf = (i == parts.count - 1)
            lastID = try findOrCreateCategory(name: name, parentID: parentID, applicable: isLeaf ? applicable : .both)
            parentID = lastID
        }
        return lastID
    }

    private func findOrCreateRootCategory(name: String, applicable: ApplicableType) throws -> UUID {
        try findOrCreateCategory(name: name, parentID: nil, applicable: applicable)
    }

    private func findOrCreateCategory(name: String, parentID: UUID?, applicable: ApplicableType) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let normalized = Self.normalize(trimmed)
        let parent = parentID
        let candidates = try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate {
            $0.parentID == parent && $0.isArchived == false
        }))
        if let existing = candidates.first(where: { Self.normalize($0.name) == normalized }) {
            return existing.id
        }
        let new = LedgerCategory(name: trimmed, parentID: parent, applicable: applicable, isAICreated: true)
        context.insert(new)
        return new.id
    }

    /// Lowercased + whitespace-stripped + width-folded for fuzzy dedup across casing/全半角.
    private static func normalize(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .widthInsensitive], locale: nil)
            .components(separatedBy: .whitespacesAndNewlines).joined()
    }

    private func findOrCreateTag(name: String) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let normalized = Self.normalize(trimmed)
        let candidates = try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { $0.isArchived == false }))
        if let existing = candidates.first(where: { Self.normalize($0.name) == normalized }) {
            return existing.id
        }
        let new = LedgerTag(name: trimmed, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreatePayment(name: String) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let normalized = Self.normalize(trimmed)
        let candidates = try context.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.isArchived == false }))
        if let existing = candidates.first(where: { Self.normalize($0.name) == normalized }) {
            return existing.id
        }
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
