import SwiftUI
import Testing
@testable import PocketHeart

struct AppearancePreferenceTests {
    @Test func mapsPreferencesToOptionalColorSchemes() {
        #expect(AppearancePreference.system.colorScheme == nil)
        #expect(AppearancePreference.light.colorScheme == .light)
        #expect(AppearancePreference.dark.colorScheme == .dark)
    }

    @Test func defaultsUnknownStoredValuesToSystem() {
        #expect(AppearancePreference(rawValue: "unexpected") == nil)
        #expect(AppearancePreference(rawValue: "system") == .system)
    }
}
