import Testing
import Foundation
@testable import PocketHeart

@MainActor
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responder: ((URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data) = Self.responder?(request) ?? (500, Data())
        let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct OpenAICompatibleAdapterTests {
    @Test @MainActor func sendsChatCompletionsAndExtractsContent() async throws {
        StubURLProtocol.responder = { req in
            #expect(req.url?.absoluteString == "https://api.example.com/v1/chat/completions")
            #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer KEY")
            let payload = #"{"choices":[{"message":{"content":"hello"}}]}"#
            return (200, payload.data(using: .utf8)!)
        }
        let session = URLSession(configuration: {
            let c = URLSessionConfiguration.ephemeral
            c.protocolClasses = [StubURLProtocol.self]
            return c
        }())
        let adapter = OpenAICompatibleAdapter(session: session)
        let out = try await adapter.send(.init(
            baseURL: "https://api.example.com/v1",
            modelName: "deepseek-chat",
            apiKey: "KEY",
            systemPrompt: "sys",
            userPrompt: "usr"
        ))
        #expect(out == "hello")
    }

    @Test @MainActor func surfacesNon2xxAsHTTPError() async throws {
        StubURLProtocol.responder = { _ in (401, Data("nope".utf8)) }
        let session = URLSession(configuration: {
            let c = URLSessionConfiguration.ephemeral
            c.protocolClasses = [StubURLProtocol.self]
            return c
        }())
        let adapter = OpenAICompatibleAdapter(session: session)
        await #expect(throws: AdapterError.self) {
            _ = try await adapter.send(.init(baseURL: "https://x/v1", modelName: "m", apiKey: "k", systemPrompt: "s", userPrompt: "u"))
        }
    }
}
