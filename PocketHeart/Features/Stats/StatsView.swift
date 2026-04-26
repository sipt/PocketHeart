import SwiftUI

struct StatsView: View {
    @Environment(\.appEnv) private var env
    @State private var vm: StatsViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = vm?.summary {
                    hero(s: s)
                    Text("BY CATEGORY").font(.system(size: 11, weight: .medium)).tracking(0.4).foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 14).padding(.top, 8)
                    VStack(spacing: 0) {
                        ForEach(Array(s.categoryShare.enumerated()), id: \.offset) { idx, slice in
                            HStack(spacing: 11) {
                                CategoryIcon(key: iconKey(for: slice.categoryName), size: 32)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(slice.categoryName).font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                                        Spacer()
                                        Text("¥\(slice.amount)").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.white.opacity(0.08))
                                            Capsule().fill(Theme.primary).frame(width: geo.size.width * slice.percent)
                                        }
                                    }
                                    .frame(height: 4)
                                    Text(String(format: "%.0f%%", slice.percent * 100))
                                        .font(.system(size: 10.5)).foregroundStyle(Theme.textMuted)
                                }
                            }
                            .padding(14)
                            if idx < s.categoryShare.count - 1 {
                                Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 14)
                            }
                        }
                    }
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerCard))
                    .padding(.horizontal, 16)
                } else {
                    ProgressView().tint(.white).padding(.top, 80)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if vm == nil, let env { vm = StatsViewModel(stats: env.stats); vm?.load() }
        }
    }

    private func hero(s: StatsSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(monthLabel.uppercased()).font(.system(size: 11, weight: .medium)).tracking(0.4).foregroundStyle(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥").font(.system(size: 16)).foregroundStyle(Theme.textSecondary)
                        Text("\(s.monthSpent)").font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("INCOME").font(.system(size: 11, weight: .medium)).tracking(0.4).foregroundStyle(Theme.textSecondary)
                    Text("+¥\(s.monthIncome)").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.success)
                    Text("net ¥\(s.monthIncome - s.monthSpent)").font(.system(size: 11)).foregroundStyle(Theme.textMuted)
                }
            }
            HStack(alignment: .bottom, spacing: 4) {
                let max = s.dailyTrend.max() ?? 1
                let maxDouble = NSDecimalNumber(decimal: max == 0 ? 1 : max).doubleValue
                ForEach(s.dailyTrend.indices, id: \.self) { i in
                    let v = NSDecimalNumber(decimal: s.dailyTrend[i]).doubleValue
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == s.dailyTrend.count - 1 ? Theme.primary : Theme.primary.opacity(0.32))
                        .frame(maxWidth: .infinity)
                        .frame(height: Swift.max(2, CGFloat(v / maxDouble) * 64))
                }
            }
            .frame(height: 64)
            .padding(.top, 18)
        }
        .padding(16)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.cornerLarge))
        .padding(.horizontal, 16)
    }

    private var monthLabel: String { Date.now.formatted(.dateTime.month(.wide)) + " spent" }

    private func iconKey(for name: String) -> String {
        switch name.lowercased() {
        case "food": return "food"
        case "transit": return "transit"
        case "coffee": return "coffee"
        case "grocery": return "grocery"
        case "salary": return "salary"
        default: return "other"
        }
    }
}
