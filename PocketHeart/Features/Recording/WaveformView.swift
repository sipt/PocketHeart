import SwiftUI

struct WaveformView: View {
    var isActive: Bool
    var tint: Color = .white
    var barCount: Int = 18

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule()
                        .fill(tint.opacity(0.85))
                        .frame(width: 3, height: barHeight(index: i, time: t))
                }
            }
            .frame(maxHeight: 28)
            .animation(.linear(duration: 1.0 / 30.0), value: t)
        }
    }

    private func barHeight(index: Int, time: TimeInterval) -> CGFloat {
        guard isActive else { return 4 }
        let phase = Double(index) * 0.55
        let s1 = sin(time * 6.2 + phase)
        let s2 = sin(time * 3.1 + phase * 1.7)
        let v = (s1 * 0.6 + s2 * 0.4 + 1) / 2
        return 4 + CGFloat(v) * 22
    }
}
