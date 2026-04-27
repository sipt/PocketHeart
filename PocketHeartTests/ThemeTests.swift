import SwiftUI
import Testing
import UIKit
@testable import PocketHeart

struct ThemeTests {
    @Test func semanticColorsAdaptToLightAndDarkAppearance() {
        let lightBackground = resolved(Theme.bg, as: .light)
        let darkBackground = resolved(Theme.bg, as: .dark)
        let lightText = resolved(Theme.textPrimary, as: .light)
        let darkText = resolved(Theme.textPrimary, as: .dark)
        let lightSeparator = resolved(Theme.separator, as: .light)
        let darkSeparator = resolved(Theme.separator, as: .dark)

        #expect(luminance(lightBackground) > 0.85)
        #expect(luminance(darkBackground) < 0.10)
        #expect(luminance(lightText) < 0.20)
        #expect(luminance(darkText) > 0.85)
        #expect(alpha(lightSeparator) > alpha(darkSeparator))
    }

    private func resolved(_ color: Color, as style: UIUserInterfaceStyle) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    private func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }

    private func alpha(_ color: UIColor) -> CGFloat {
        var alpha: CGFloat = 0
        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        return alpha
    }
}
