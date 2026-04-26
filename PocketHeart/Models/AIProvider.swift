import Foundation
import SwiftData

@Model
final class AIProvider {
    var id: UUID
    var displayName: String
    var templateRaw: String
    var baseURL: String
    var modelName: String
    var interfaceRaw: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    var template: ProviderTemplate {
        get { ProviderTemplate(rawValue: templateRaw) ?? .custom }
        set { templateRaw = newValue.rawValue }
    }
    var interface: InterfaceFormat {
        get { InterfaceFormat(rawValue: interfaceRaw) ?? .openAICompatible }
        set { interfaceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        template: ProviderTemplate = .custom,
        baseURL: String,
        modelName: String,
        interface: InterfaceFormat = .openAICompatible,
        isDefault: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.templateRaw = template.rawValue
        self.baseURL = baseURL
        self.modelName = modelName
        self.interfaceRaw = interface.rawValue
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
