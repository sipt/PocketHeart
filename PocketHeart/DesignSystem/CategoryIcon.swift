import SwiftUI

struct CategoryIcon: View {
    let key: String
    var size: CGFloat = 36

    private var color: Color {
        switch key {
        case "food":    return Color(hue: 30/360, saturation: 0.55, brightness: 0.95)
        case "transit": return Color(hue: 240/360, saturation: 0.55, brightness: 0.85)
        case "coffee":  return Color(hue: 50/360, saturation: 0.45, brightness: 0.7)
        case "grocery": return Color(hue: 145/360, saturation: 0.55, brightness: 0.85)
        case "salary":  return Color(hue: 280/360, saturation: 0.55, brightness: 0.85)
        default:        return Color.gray
        }
    }

    private var systemName: String {
        switch key {
        case "food":    return "fork.knife"
        case "transit": return "tram.fill"
        case "coffee":  return "cup.and.saucer.fill"
        case "grocery": return "cart.fill"
        case "salary":  return "dollarsign.circle.fill"
        default:        return "circle.dashed"
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28)
            .fill(color.opacity(0.22))
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: size, height: size)
    }
}
