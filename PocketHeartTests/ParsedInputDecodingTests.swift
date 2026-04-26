import Testing
import Foundation
@testable import PocketHeart

struct ParsedInputDecodingTests {
    @Test func decodesTwoExpenses() throws {
        let json = #"""
        {"transactions":[
          {"amount":38.5,"currency":"CNY","type":"expense","title":"Lunch","occurredAt":"2026-04-25T12:30:00+08:00","categoryName":"Food","tagNames":["work"],"paymentMethodName":"WeChat Pay"},
          {"amount":28,"currency":"CNY","type":"expense","title":"Latte","occurredAt":"2026-04-25T16:00:00+08:00","categoryName":"Coffee","tagNames":[],"paymentMethodName":"CMB Credit"}
        ],"failed":[]}
        """#
        let result = try ParsedInputDecoder.decode(json)
        #expect(result.transactions.count == 2)
        #expect(result.transactions[0].amount == Decimal(string: "38.5"))
        #expect(result.transactions[1].title == "Latte")
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
