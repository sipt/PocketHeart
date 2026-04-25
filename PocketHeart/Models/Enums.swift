import Foundation

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case expense, income
}

enum InputSource: String, Codable, Sendable {
    case text, voice
}

enum ParseStatus: String, Codable, CaseIterable, Sendable {
    case pending, success, partialFailure, failure
}

enum ApplicableType: String, Codable, Sendable {
    case expense, income, both
}

enum PaymentKind: String, Codable, CaseIterable, Sendable {
    case wechat, alipay, bank, cash, applePay, creditCard, other
}

enum ProviderTemplate: String, Codable, CaseIterable, Sendable {
    case openAI, deepSeek, anthropic, gemini, ollama, custom
}

enum InterfaceFormat: String, Codable, CaseIterable, Sendable {
    case openAICompatible, anthropicMessages, geminiGenerateContent
}
