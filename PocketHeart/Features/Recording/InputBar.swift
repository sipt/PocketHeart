import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let isRecording: Bool
    let liveTranscript: String
    let onSend: () -> Void
    let onMicPressDown: () -> Void
    let onMicCommit: () -> Void
    let onMicCancel: () -> Void

    @State private var isPressing = false
    @State private var willCancel = false
    @State private var pressStartedAt: Date?

    private let cancelThreshold: CGFloat = -60
    private let minDuration: TimeInterval = 0.30

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            contentCapsule
            trailingButton
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isRecording)
        .animation(.easeInOut(duration: 0.15), value: willCancel)
    }

    @ViewBuilder
    private var contentCapsule: some View {
        Group {
            if isRecording {
                recordingContent
            } else {
                idleContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(willCancel ? Theme.danger.opacity(0.7) : Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        )
    }

    private var idleContent: some View {
        TextField("Tell me what you spent…", text: $text, axis: .vertical)
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .tint(Theme.primary)
            .lineLimit(1...4)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
    }

    private var recordingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView {
                Text(liveTranscript.isEmpty ? L("Listening…") : liveTranscript)
                    .font(.system(size: 15))
                    .foregroundStyle(liveTranscript.isEmpty ? Color.white.opacity(0.5) : Color.white.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
            }
            .frame(maxHeight: 70)

            HStack(spacing: 12) {
                WaveformView(isActive: !willCancel, tint: willCancel ? Theme.danger : Color.white)
                    .padding(.leading, 18)
                Spacer(minLength: 8)
                Text(willCancel ? L("Release to cancel") : L("Release to send · Slide up to cancel"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(willCancel ? Theme.danger : Color.white.opacity(0.55))
                    .padding(.trailing, 18)
            }
            .padding(.bottom, 12)
        }
        .frame(minHeight: 120)
    }

    @ViewBuilder
    private var trailingButton: some View {
        if hasText && !isRecording {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.primary, in: Circle())
            }
            .transition(.scale.combined(with: .opacity))
        } else {
            micButton
        }
    }

    private var micButton: some View {
        ZStack {
            Circle()
                .fill(willCancel ? Theme.danger : Theme.primary)
                .frame(width: 44, height: 44)
                .shadow(color: (willCancel ? Theme.danger : Theme.primary).opacity(isPressing ? 0.6 : 0.3),
                        radius: isPressing ? 14 : 8, y: 4)
                .scaleEffect(isPressing ? 1.18 : 1.0)

            Image(systemName: isPressing ? "waveform" : "mic.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
        .contentShape(Circle())
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressing)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isPressing {
                        isPressing = true
                        pressStartedAt = Date()
                        willCancel = false
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.prepare()
                        gen.impactOccurred()
                        onMicPressDown()
                    }
                    let nextWillCancel = value.translation.height < cancelThreshold
                    if nextWillCancel != willCancel {
                        willCancel = nextWillCancel
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                }
                .onEnded { value in
                    let pressed = pressStartedAt
                    let cancel = willCancel || value.translation.height < cancelThreshold
                    isPressing = false
                    willCancel = false
                    pressStartedAt = nil

                    if cancel {
                        onMicCancel()
                        return
                    }
                    let elapsed = pressed.map { Date().timeIntervalSince($0) } ?? 0
                    if elapsed < minDuration {
                        onMicCancel()
                        return
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onMicCommit()
                }
        )
    }
}
