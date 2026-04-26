import Foundation

struct AdapterRequest: Sendable {
    let baseURL: String
    let modelName: String
    let apiKey: String
    let systemPrompt: String
    let userPrompt: String
}

protocol ProviderAdapter: Sendable {
    func send(_ request: AdapterRequest) async throws -> String
}

enum AdapterError: Error, Equatable {
    case invalidURL
    case missingAPIKey
    case http(Int, String)
    case emptyResponse
}
