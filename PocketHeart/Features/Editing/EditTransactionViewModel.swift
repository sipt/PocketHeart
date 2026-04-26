import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class EditTransactionViewModel {
    var amountString: String = ""
    var currency: String = "CNY"
    var type: TransactionType = .expense
    var title: String = ""
    var merchant: String = ""
    var occurredAt: Date = .now
    var categoryID: UUID?
    var subcategoryID: UUID?
    var tagIDs: [UUID] = []
    var paymentMethodID: UUID?
    var notes: String = ""

    let txnID: UUID
    let repository: LedgerRepository
    let context: ModelContext
    private(set) var loaded = false
    var error: String?

    init(txnID: UUID, repository: LedgerRepository, context: ModelContext) {
        self.txnID = txnID
        self.repository = repository
        self.context = context
    }

    func load() {
        guard !loaded else { return }
        let id = txnID
        guard let txn = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })).first else {
            error = "Transaction not found"
            return
        }
        amountString = "\(txn.amount)"
        currency = txn.currency
        type = txn.type
        title = txn.title
        merchant = txn.merchant ?? ""
        occurredAt = txn.occurredAt
        categoryID = txn.categoryID
        subcategoryID = txn.subcategoryID
        tagIDs = txn.tagIDs
        paymentMethodID = txn.paymentMethodID
        notes = txn.notes ?? ""
        loaded = true
    }

    func save() throws {
        let id = txnID
        guard let txn = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })).first else { return }
        guard let amount = Decimal(string: amountString), amount > 0 else { throw NSError(domain: "Edit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Amount must be a positive number."]) }
        try repository.update(txn) { t in
            t.amount = amount
            t.currency = self.currency
            t.type = self.type
            t.title = self.title
            t.merchant = self.merchant.isEmpty ? nil : self.merchant
            t.occurredAt = self.occurredAt
            if let c = self.categoryID { t.categoryID = c }
            t.subcategoryID = self.subcategoryID
            t.tagIDs = self.tagIDs
            if let p = self.paymentMethodID { t.paymentMethodID = p }
            t.notes = self.notes.isEmpty ? nil : self.notes
        }
    }

    func delete() throws {
        let id = txnID
        guard let txn = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })).first else { return }
        try repository.delete(txn)
    }
}
