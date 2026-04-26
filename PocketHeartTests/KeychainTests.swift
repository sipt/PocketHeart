import Foundation
import Testing
@testable import PocketHeart

struct KeychainTests {
    let service = "com.pocketheart.test.\(UUID().uuidString)"

    @Test func roundTripsString() throws {
        let kc = Keychain(service: service)
        try kc.set("sk-secret", account: "p1")
        #expect(try kc.get(account: "p1") == "sk-secret")
        try kc.delete(account: "p1")
        #expect(try kc.get(account: "p1") == nil)
    }

    @Test func updatesExistingValue() throws {
        let kc = Keychain(service: service)
        try kc.set("v1", account: "acct")
        try kc.set("v2", account: "acct")
        #expect(try kc.get(account: "acct") == "v2")
        try kc.delete(account: "acct")
    }
}
