import Foundation

enum AdapterFactory {
    static func adapter(for interface: InterfaceFormat, session: URLSession = .shared) -> any ProviderAdapter {
        switch interface {
        case .openAICompatible: return OpenAICompatibleAdapter(session: session)
        case .anthropicMessages: return AnthropicAdapter(session: session)
        case .geminiGenerateContent: return GeminiAdapter(session: session)
        }
    }
}
