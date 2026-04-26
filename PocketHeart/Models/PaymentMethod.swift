import Foundation
import SwiftData

@Model
final class PaymentMethod {
    var id: UUID
    var name: String
    var kindRaw: String
    var isBuiltIn: Bool
    var isAICreated: Bool
    var isArchived: Bool

    var kind: PaymentKind {
        get { PaymentKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: PaymentKind = .other,
        isBuiltIn: Bool = false,
        isAICreated: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.isBuiltIn = isBuiltIn
        self.isAICreated = isAICreated
        self.isArchived = isArchived
    }
}
