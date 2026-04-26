import Foundation

struct GeminiAdapter: ProviderAdapter {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func send(_ request: AdapterRequest) async throws -> String {
        guard !request.apiKey.isEmpty else { throw AdapterError.missingAPIKey }
        let base = request.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var comps = URLComponents(string: "\(base)/v1beta/models/\(request.modelName):generateContent") else {
            throw AdapterError.invalidURL
        }
        comps.queryItems = [URLQueryItem(name: "key", value: request.apiKey)]
        guard let url = comps.url else { throw AdapterError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": request.systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": request.userPrompt]]]],
            "generationConfig": ["temperature": 0.1, "responseMimeType": "application/json"],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AdapterError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        struct Resp: Decodable {
            struct Candidate: Decodable { struct Content: Decodable { struct Part: Decodable { let text: String? }; let parts: [Part] }; let content: Content }
            let candidates: [Candidate]
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.compactMap(\.text).first, !text.isEmpty else {
            throw AdapterError.emptyResponse
        }
        return text
    }
}
