import SwiftUI

struct GroupCardView: View {
    let model: GroupCardModel
    let onTapTransaction: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .overlay(alignment: .bottom) { hairline.padding(.leading, 14) }

            VStack(spacing: 0) {
                ForEach(Array(model.transactions.enumerated()), id: \.element.id) { idx, txn in
                    TransactionRowView(model: txn) { onTapTransaction(txn.id) }
                    if idx < model.transactions.count - 1 {
                        hairline.padding(.leading, 14)
                    }
                }
            }

            if !model.failed.isEmpty {
                failedSection
            }
        }
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
                    .accessibilityHidden(true)

                Text(countSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            Text(formattedNet)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(netColor)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var countSummary: String {
        var parts: [String] = []
        if model.expenseCount > 0 {
            parts.append(L("\(model.expenseCount) 笔支出"))
        }
        if model.incomeCount > 0 {
            parts.append(L("\(model.incomeCount) 笔收入"))
        }
        if parts.isEmpty {
            return L("暂无记录")
        }
        return parts.joined(separator: " · ")
    }

    private var formattedNet: String {
        let symbol = model.currency == "CNY" ? "¥" : model.currency + " "
        let sign = model.net >= 0 ? "+" : "-"
        let magnitude = model.net >= 0 ? model.net : -model.net
        return "\(sign)\(symbol)\(magnitude)"
    }

    private var netColor: Color {
        if model.net > 0 { return Theme.success }
        if model.net < 0 { return Theme.textPrimary }
        return Theme.textSecondary
    }

    // MARK: - Failed

    private var failedSection: some View {
        VStack(spacing: 0) {
            ForEach(model.failed.indices, id: \.self) { i in
                let f = model.failed[i]
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Theme.warning)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.reason)
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                        Text(f.raw)
                            .font(.caption2)
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                if i < model.failed.count - 1 {
                    hairline.padding(.leading, 14)
                }
            }
        }
        .background(Theme.warning.opacity(0.06))
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.warning.opacity(0.18)).frame(height: 0.5)
        }
    }

    // MARK: - Helpers

    private var hairline: some View {
        Rectangle().fill(Theme.separator).frame(height: 0.5)
    }
}
