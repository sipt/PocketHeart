import Foundation

struct ParsedInputResult: Decodable, Sendable {
    let transactions: [ParsedTransaction]
    let failed: [ParsedFailure]
}

struct ParsedTransaction: Decodable, Sendable {
    let amount: Decimal?
    let currency: String?
    let type: TransactionType
    let occurredAt: Date?
    let categoryPath: String
    let tagNames: [String]
    let paymentMethodName: String
    let notes: String?
}

struct ParsedFailure: Decodable, Sendable {
    let raw: String
    let reason: String
}

struct ParsingContext: Sendable {
    struct CategoryRef: Sendable { let id: UUID; let name: String; let parentName: String? }
    let now: Date
    let timeZone: TimeZone
    let locale: Locale
    let defaultCurrency: String
    let categories: [CategoryRef]
    let tags: [String]
    let paymentMethods: [String]
}
