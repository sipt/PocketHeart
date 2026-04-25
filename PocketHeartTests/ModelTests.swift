import Testing
@testable import PocketHeart

struct EnumsTests {
    @Test func transactionTypeRoundTripsRaw() {
        #expect(TransactionType(rawValue: "expense") == .expense)
        #expect(TransactionType(rawValue: "income") == .income)
    }

    @Test func parseStatusCases() {
        #expect(ParseStatus.allCases.count == 4)
    }
}
