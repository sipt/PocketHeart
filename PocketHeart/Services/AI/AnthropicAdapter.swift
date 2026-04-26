import Foundation

struct AnthropicAdapter: ProviderAdapter {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func send(_ request: AdapterRequest) async throws -> String {
        guard !request.apiKey.isEmpty else { throw AdapterError.missingAPIKey }
        guard let url = URL(string: request.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/messages") else {
            throw AdapterError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(request.apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": request.modelName,
            "max_tokens": 1024,
            "system": request.systemPrompt,
            "messages": [["role": "user", "content": request.userPrompt]],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AdapterError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        struct Resp: Decodable { struct Block: Decodable { let text: String? }; let content: [Block] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let text = decoded.content.compactMap(\.text).first, !text.isEmpty else { throw AdapterError.emptyResponse }
        return text
    }
}
