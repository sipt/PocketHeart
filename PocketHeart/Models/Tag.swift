import Foundation
import SwiftData

@Model
final class LedgerTag {
    var id: UUID
    var name: String
    var isBuiltIn: Bool
    var isAICreated: Bool
    var usageCount: Int
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        isBuiltIn: Bool = false,
        isAICreated: Bool = false,
        usageCount: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.isAICreated = isAICreated
        self.usageCount = usageCount
        self.isArchived = isArchived
    }
}
