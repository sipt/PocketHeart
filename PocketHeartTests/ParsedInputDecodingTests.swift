import Testing
import Foundation
@testable import PocketHeart

struct ParsedInputDecodingTests {
    @Test func decodesTwoExpenses() throws {
        let json = #"""
        {"transactions":[
          {"amount":38.5,"currency":"CNY","type":"expense","occurredAt":"2026-04-25T12:30:00+08:00","categoryPath":"Food","tagNames":["work"],"paymentMethodName":"WeChat Pay","notes":"Lunch"},
          {"amount":28,"currency":"CNY","type":"expense","occurredAt":"2026-04-25T16:00:00+08:00","categoryPath":"Coffee","tagNames":[],"paymentMethodName":"CMB Credit","notes":"Latte"}
        ],"failed":[]}
        """#
        let result = try ParsedInputDecoder.decode(json)
        #expect(result.transactions.count == 2)
        #expect(result.transactions[0].amount == Decimal(string: "38.5"))
        #expect(result.transactions[1].notes == "Latte")
    }

    @Test func decodesPartialFailure() throws {
        let json = #"""
        {"transactions":[],"failed":[{"raw":"工资","reason":"missing amount"}]}
        """#
        let r = try ParsedInputDecoder.decode(json)
        #expect(r.transactions.isEmpty)
        #expect(r.failed.first?.reason == "missing amount")
    }

    @Test func tolerantOfFencedCodeBlock() throws {
        let json = """
        ```json
        {"transactions":[],"failed":[]}
        ```
        """
        let r = try ParsedInputDecoder.decode(json)
        #expect(r.transactions.isEmpty)
    }

    @Test func throwsOnInvalidJSON() {
        #expect(throws: (any Error).self) {
            _ = try ParsedInputDecoder.decode("not json")
        }
    }
}

struct FakeAdapter: ProviderAdapter {
    let response: Result<String, any Error>
    func send(_ request: AdapterRequest) async throws -> String {
        try response.get()
    }
}

struct AIParsingServiceTests {
    let context = ParsingContext(
        now: Date(timeIntervalSince1970: 1_700_000_000),
        timeZone: TimeZone(identifier: "Asia/Shanghai")!,
        locale: Locale(identifier: "zh_CN"),
        defaultCurrency: "CNY",
        categories: [], tags: [], paymentMethods: []
    )

    @Test func parsesValidResponse() async throws {
        let json = #"{"transactions":[{"amount":12,"currency":"CNY","type":"expense","occurredAt":"2026-04-25T10:00:00+08:00","categoryPath":"Food","tagNames":[],"paymentMethodName":"Cash","notes":"a"}],"failed":[]}"#
        let svc = AIParsingService(adapter: FakeAdapter(response: .success(json)))
        let result = try await svc.parse(input: "x", apiKey: "k", baseURL: "https://x/v1", model: "m", context: context)
        #expect(result.transactions.count == 1)
    }

    @Test func wrapsAdapterErrors() async {
        let svc = AIParsingService(adapter: FakeAdapter(response: .failure(AdapterError.http(500, "boom"))))
        await #expect(throws: AIParsingError.self) {
            _ = try await svc.parse(input: "x", apiKey: "k", baseURL: "u", model: "m", context: context)
        }
    }
}
