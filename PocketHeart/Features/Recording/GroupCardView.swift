import SwiftUI

struct GroupCardView: View {
    let model: GroupCardModel
    let onTapTransaction: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 6).fill(Theme.primary).frame(width: 18, height: 18)
                        .overlay { Image(systemName: "sparkle").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white) }
                    Text(model.summary).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
                Text("\(model.source.rawValue) · \(model.when.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.separator).frame(height: 0.5) }

            VStack(spacing: 0) {
                ForEach(Array(model.transactions.enumerated()), id: \.element.id) { idx, txn in
                    TransactionRowView(model: txn) { onTapTransaction(txn.id) }
                    if idx < model.transactions.count - 1 {
                        Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 14)
                    }
                }
            }

            if !model.failed.isEmpty {
                ForEach(model.failed.indices, id: \.self) { i in
                    let f = model.failed[i]
                    HStack(spacing: 9) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.warning).font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(f.reason).font(.system(size: 12)).foregroundStyle(Theme.warning)
                            Text(f.raw).font(.system(size: 11)).foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Theme.warning.opacity(0.06))
                    .overlay(alignment: .top) { Rectangle().fill(Theme.warning.opacity(0.18)).frame(height: 0.5) }
                }
            }
        }
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.cornerLarge))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerLarge).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .padding(.bottom, 12)
    }
}
