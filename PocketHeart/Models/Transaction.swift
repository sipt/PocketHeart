import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var currency: String
    var typeRaw: String
    var title: String
    var merchant: String?
    var occurredAt: Date
    var categoryID: UUID
    var subcategoryID: UUID?
    var tagIDs: [UUID]
    var paymentMethodID: UUID
    var notes: String?
    var sourceInputID: UUID
    var isAICreated: Bool
    var createdAt: Date
    var updatedAt: Date

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        amount: Decimal,
        currency: String,
        type: TransactionType,
        title: String,
        merchant: String? = nil,
        occurredAt: Date,
        categoryID: UUID,
        subcategoryID: UUID? = nil,
        tagIDs: [UUID] = [],
        paymentMethodID: UUID,
        notes: String? = nil,
        sourceInputID: UUID,
        isAICreated: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.typeRaw = type.rawValue
        self.title = title
        self.merchant = merchant
        self.occurredAt = occurredAt
        self.categoryID = categoryID
        self.subcategoryID = subcategoryID
        self.tagIDs = tagIDs
        self.paymentMethodID = paymentMethodID
        self.notes = notes
        self.sourceInputID = sourceInputID
        self.isAICreated = isAICreated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
