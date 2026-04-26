import SwiftUI

struct TransactionRowView: View {
    let model: TransactionRowModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 11) {
                CategoryIcon(key: model.iconKey, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(model.title).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                        if let m = model.merchant { Text("· " + m).font(.system(size: 11)).foregroundStyle(Theme.textMuted).lineLimit(1) }
                    }
                    HStack(spacing: 4) {
                        MetaPill(text: model.subcategoryName ?? model.categoryName)
                        MetaPill(text: model.paymentName, muted: true)
                        ForEach(model.tagNames, id: \.self) { TagPill(text: $0) }
                    }
                    Text(model.occurredAt, style: .time)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formatted())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(model.type == .income ? Theme.success : .white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    private func formatted() -> String {
        let symbol = model.currency == "CNY" ? "¥" : model.currency
        let sign = model.type == .income ? "+" : ""
        return "\(sign)\(symbol)\(model.amount)"
    }
}
