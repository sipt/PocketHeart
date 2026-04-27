import SwiftUI

struct TransactionRowView: View {
    let model: TransactionRowModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                CategoryIcon(key: model.iconKey, size: 36)

                VStack(alignment: .leading, spacing: 5) {
                    Text(categoryHeading)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        MetaPill(text: model.paymentName, muted: true)
                        if let dateText = occurredDateLabel {
                            MetaPill(text: dateText, muted: true)
                        }
                        ForEach(model.tagNames, id: \.self) { TagPill(text: $0) }
                    }
                }

                Spacer(minLength: 8)

                Text(formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(model.type == .income ? Theme.success : Theme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var categoryHeading: String {
        if let parent = model.parentCategoryName, parent != model.categoryName {
            return "\(parent) · \(model.categoryName)"
        }
        return model.categoryName
    }

    private var occurredDateLabel: String? {
        let cal = Calendar.current
        guard !cal.isDate(model.occurredAt, inSameDayAs: model.createdAt) else { return nil }
        return model.occurredAt.formatted(.dateTime.month().day())
    }

    private var formattedAmount: String {
        let symbol = model.currency == "CNY" ? "¥" : model.currency + " "
        let sign = model.type == .income ? "+" : ""
        return "\(sign)\(symbol)\(model.amount)"
    }
}
