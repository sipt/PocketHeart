import Foundation
import SwiftData

@MainActor
@Observable
final class ProviderEditViewModel {
    var displayName: String = ""
    var template: ProviderTemplate = .openAI
    var baseURL: String = ""
    var modelName: String = ""
    var interface: InterfaceFormat = .openAICompatible
    var apiKey: String = ""
    var isDefault: Bool = false
    var error: String?

    let editingID: UUID?
    let context: ModelContext
    let keychain: Keychain

    init(editingID: UUID?, context: ModelContext, keychain: Keychain = .providers) {
        self.editingID = editingID
        self.context = context
        self.keychain = keychain
    }

    func load() {
        guard let id = editingID else {
            applyTemplate(.openAI)
            return
        }
        guard let p = try? context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id == id })).first else {
            applyTemplate(.openAI)
            return
        }
        displayName = p.displayName
        template = p.template
        baseURL = p.baseURL
        modelName = p.modelName
        interface = p.interface
        isDefault = p.isDefault
        apiKey = (try? keychain.get(account: id.uuidString)) ?? ""
    }

    func applyTemplate(_ t: ProviderTemplate) {
        template = t
        switch t {
        case .openAI:
            displayName = displayName.isEmpty ? "OpenAI" : displayName
            baseURL = "https://api.openai.com/v1"; modelName = "gpt-4o-mini"; interface = .openAICompatible
        case .deepSeek:
            displayName = displayName.isEmpty ? "DeepSeek" : displayName
            baseURL = "https://api.deepseek.com/v1"; modelName = "deepseek-chat"; interface = .openAICompatible
        case .anthropic:
            displayName = displayName.isEmpty ? "Anthropic" : displayName
            baseURL = "https://api.anthropic.com"; modelName = "claude-haiku-4-5"; interface = .anthropicMessages
        case .gemini:
            displayName = displayName.isEmpty ? "Gemini" : displayName
            baseURL = "https://generativelanguage.googleapis.com"; modelName = "gemini-1.5-flash"; interface = .geminiGenerateContent
        case .ollama:
            displayName = displayName.isEmpty ? "Local · Ollama" : displayName
            baseURL = "http://localhost:11434/v1"; modelName = "qwen2:7b"; interface = .openAICompatible
        case .custom:
            interface = .openAICompatible
        }
    }

    func save() throws {
        guard !displayName.isEmpty, !baseURL.isEmpty, !modelName.isEmpty else {
            throw NSError(domain: "Provider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name, base URL, and model are required."])
        }
        guard URL(string: baseURL) != nil else {
            throw NSError(domain: "Provider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Base URL is invalid."])
        }
        let provider: AIProvider
        if let id = editingID, let existing = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id == id })).first {
            existing.displayName = displayName
            existing.template = template
            existing.baseURL = baseURL
            existing.modelName = modelName
            existing.interface = interface
            existing.updatedAt = .now
            provider = existing
        } else {
            provider = AIProvider(displayName: displayName, template: template, baseURL: baseURL, modelName: modelName, interface: interface)
            context.insert(provider)
        }
        if isDefault {
            let providerID = provider.id
            let others = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id != providerID }))
            for other in others { other.isDefault = false }
            provider.isDefault = true
        } else if !(try anyDefaultExists()) {
            provider.isDefault = true
        } else {
            provider.isDefault = isDefault
        }
        if !apiKey.isEmpty {
            try keychain.set(apiKey, account: provider.id.uuidString)
        }
        try context.save()
    }

    private func anyDefaultExists() throws -> Bool {
        let existing = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.isDefault == true }))
        return !existing.isEmpty
    }

    func delete() throws {
        guard let id = editingID, let p = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id == id })).first else { return }
        try? keychain.delete(account: id.uuidString)
        context.delete(p)
        try context.save()
    }
}
