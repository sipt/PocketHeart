import Testing
import Foundation
@testable import PocketHeart

struct ParsingPromptTests {
    @Test func includesCurrentDateAndCurrency() {
        let ctx = ParsingContext(
            now: Date(timeIntervalSince1970: 1_700_000_000),
            timeZone: TimeZone(identifier: "Asia/Shanghai")!,
            locale: Locale(identifier: "zh_CN"),
            defaultCurrency: "CNY",
            categories: [],
            tags: [],
            paymentMethods: []
        )
        let prompt = ParsingPrompt.user(input: "lunch 38", context: ctx)
        #expect(prompt.contains("CNY"))
        #expect(prompt.contains("Asia/Shanghai"))
        #expect(prompt.contains("lunch 38"))
    }

    @Test func listsExistingTaxonomy() {
        let ctx = ParsingContext(
            now: .now, timeZone: .current, locale: .current, defaultCurrency: "CNY",
            categories: [.init(id: UUID(), name: "Food", parentName: nil)],
            tags: ["work"],
            paymentMethods: ["WeChat Pay"]
        )
        let prompt = ParsingPrompt.user(input: "x", context: ctx)
        #expect(prompt.contains("Food"))
        #expect(prompt.contains("work"))
        #expect(prompt.contains("WeChat Pay"))
    }
}
