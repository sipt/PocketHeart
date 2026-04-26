import Foundation

enum AIParsingError: Error {
    case missingProvider
    case missingAPIKey
    case providerFailure(String)
    case invalidJSON(String)
}

protocol AIParsingServiceProtocol: Sendable {
    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult
}

struct AIParsingService: AIParsingServiceProtocol {
    let adapter: any ProviderAdapter

    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult {
        let req = AdapterRequest(
            baseURL: baseURL,
            modelName: model,
            apiKey: apiKey,
            systemPrompt: ParsingPrompt.system,
            userPrompt: ParsingPrompt.user(input: input, context: context)
        )
        let raw: String
        do { raw = try await adapter.send(req) }
        catch let e as AdapterError {
            switch e {
            case .missingAPIKey: throw AIParsingError.missingAPIKey
            default: throw AIParsingError.providerFailure(String(describing: e))
            }
        }
        do { return try ParsedInputDecoder.decode(raw) }
        catch { throw AIParsingError.invalidJSON(raw) }
    }
}
