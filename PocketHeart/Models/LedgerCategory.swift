import Foundation
import SwiftData

@Model
final class LedgerCategory {
    var id: UUID
    var name: String
    var parentID: UUID?
    var applicableRaw: String
    var iconKey: String
    var isBuiltIn: Bool
    var isAICreated: Bool
    var isArchived: Bool

    var applicable: ApplicableType {
        get { ApplicableType(rawValue: applicableRaw) ?? .both }
        set { applicableRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        parentID: UUID? = nil,
        applicable: ApplicableType = .both,
        iconKey: String = "other",
        isBuiltIn: Bool = false,
        isAICreated: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.parentID = parentID
        self.applicableRaw = applicable.rawValue
        self.iconKey = iconKey
        self.isBuiltIn = isBuiltIn
        self.isAICreated = isAICreated
        self.isArchived = isArchived
    }
}
