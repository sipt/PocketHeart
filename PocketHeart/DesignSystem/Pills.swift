import SwiftUI

struct MetaPill: View {
    let text: String
    var muted: Bool = false
    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .medium))
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Theme.pillFill.opacity(muted ? 0.75 : 1), in: Capsule())
            .foregroundStyle(muted ? Theme.textMuted : Theme.textSecondary)
    }
}

struct TagPill: View {
    let text: String
    var body: some View {
        Text("#" + text)
            .font(.system(size: 10.5, weight: .medium))
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Theme.primary.opacity(0.16), in: Capsule())
            .foregroundStyle(Theme.primaryLight)
    }
}

struct TypePill: View {
    let type: TransactionType
    var active: Bool
    var body: some View {
        let color: Color = type == .expense ? Theme.danger : Theme.success
        Text(type == .expense ? "– Expense" : "+ Income")
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 11).padding(.vertical, 5)
            .background(active ? color.opacity(0.16) : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(active ? color.opacity(0.3) : Theme.surfaceBorder, lineWidth: 1))
            .foregroundStyle(active ? color : Theme.textSecondary)
    }
}
