import SwiftUI

struct DayDivider: View {
    let label: String
    var body: some View {
        HStack(spacing: 10) {
            Capsule().fill(Theme.separator).frame(height: 0.5)
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .tracking(0.4)
            Capsule().fill(Theme.separator).frame(height: 0.5)
        }
        .padding(.vertical, 8)
    }
}
