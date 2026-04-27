import Foundation

struct StreamMessage: Identifiable, Equatable {
    let id: String
    enum Kind: Equatable {
        case dayDivider(label: String)
        case userBubble(text: String, source: InputSource, time: Date)
        case group(GroupCardModel)
    }
    var kind: Kind

    init(id: String = UUID().uuidString, kind: Kind) {
        self.id = id
        self.kind = kind
    }
}

struct RecordingScrollRequest: Equatable {
    enum Target: Equatable {
        case bottom
        case message(String)
    }

    let id = UUID()
    let target: Target
    let animated: Bool
}

struct GroupCardModel: Equatable {
    var inputEntryID: UUID
    var source: InputSource
    var when: Date
    var expenseCount: Int
    var incomeCount: Int
    var net: Decimal
    var currency: String
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
    var occurredAt: Date
    var createdAt: Date
    var parentCategoryName: String?
    var categoryName: String
    var iconKey: String
    var tagNames: [String]
    var paymentName: String
    var notes: String?
}
