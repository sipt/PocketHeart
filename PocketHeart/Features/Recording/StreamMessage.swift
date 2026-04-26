import Foundation

struct StreamMessage: Identifiable, Equatable {
    let id = UUID()
    enum Kind: Equatable {
        case dayDivider(label: String)
        case userBubble(text: String, source: InputSource, time: Date)
        case group(GroupCardModel)
    }
    var kind: Kind
}

struct GroupCardModel: Equatable {
    var inputEntryID: UUID
    var source: InputSource
    var when: Date
    var summary: String
    var transactions: [TransactionRowModel]
    var failed: [ParsedFailure]
}

extension ParsedFailure: Equatable {
    public static func == (lhs: ParsedFailure, rhs: ParsedFailure) -> Bool {
        lhs.raw == rhs.raw && lhs.reason == rhs.reason
    }
}

struct TransactionRowModel: Equatable, Identifiable {
    let id: UUID
    var amount: Decimal
    var currency: String
    var type: TransactionType
    var title: String
    var merchant: String?
    var occurredAt: Date
    var categoryName: String
    var iconKey: String
    var subcategoryName: String?
    var tagNames: [String]
    var paymentName: String
}
