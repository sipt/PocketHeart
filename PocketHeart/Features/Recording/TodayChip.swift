import SwiftUI

struct TodayChip: View {
    let summary: StatsSummary?
    let onStats: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("SPENT TODAY").font(.system(size: 10.5, weight: .medium)).tracking(0.3).foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(spent).font(.system(size: 22, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    if let income = incomeText {
                        Text(income).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.success)
                    }
                }
            }
            Spacer()
            Button(action: onStats) {
                HStack(spacing: 5) {
                    Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 11, weight: .semibold))
                    Text("Stats").font(.system(size: 12.5, weight: .medium))
                }
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(Theme.primary.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.primaryLight)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(LinearGradient(colors: [Theme.primary.opacity(0.18), Theme.primary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.primary.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var spent: String {
        let value = summary?.todaySpent ?? 0
        return "¥\(value)"
    }
    private var incomeText: String? {
        guard let income = summary?.monthIncome, income > 0 else { return nil }
        return "+¥\(income) in"
    }
}
