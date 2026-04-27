import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var currency: String
    var typeRaw: String
    var occurredAt: Date
    var categoryID: UUID
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
        occurredAt: Date,
        categoryID: UUID,
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
        self.occurredAt = occurredAt
        self.categoryID = categoryID
        self.tagIDs = tagIDs
        self.paymentMethodID = paymentMethodID
        self.notes = notes
        self.sourceInputID = sourceInputID
        self.isAICreated = isAICreated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
