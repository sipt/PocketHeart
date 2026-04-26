import Foundation

struct OpenAICompatibleAdapter: ProviderAdapter {
    let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func send(_ request: AdapterRequest) async throws -> String {
        guard !request.apiKey.isEmpty else { throw AdapterError.missingAPIKey }
        guard let url = URL(string: request.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions") else {
            throw AdapterError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(request.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": request.modelName,
            "messages": [
                ["role": "system", "content": request.systemPrompt],
                ["role": "user", "content": request.userPrompt],
            ],
            "temperature": 0.1,
            "response_format": ["type": "json_object"],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AdapterError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        struct Resp: Decodable {
            struct Choice: Decodable { struct Msg: Decodable { let content: String }; let message: Msg }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw AdapterError.emptyResponse
        }
        return content
    }
}
