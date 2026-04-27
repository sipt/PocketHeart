import SwiftUI

struct UserBubbleView: View {
    let text: String
    let source: InputSource
    let time: Date

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 3) {
                VStack(alignment: .leading, spacing: 6) {
                    if source == .voice {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill").font(.system(size: 10))
                            Text("VOICE").font(.system(size: 10.5, weight: .medium)).tracking(0.3)
                        }
                        .foregroundStyle(Color.white.opacity(0.75))
                    }
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(LinearGradient(colors: [Color(red:0.55,green:0.45,blue:1.0), Theme.primary], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 18))
                Text(time, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.bottom, 2)
    }
}

struct LiveRecordingBubble: View {
    let elapsed: TimeInterval
    @State private var pulse = false
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Circle().fill(Theme.danger).frame(width: 8, height: 8).opacity(pulse ? 1 : 0.4)
                Text(formatted(elapsed)).font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.primaryLight)
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Theme.primary.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.primary.opacity(0.45), lineWidth: 1))
            .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { pulse = true } }
        }
    }
    private func formatted(_ s: TimeInterval) -> String {
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
