import SwiftUI
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

struct InputBar: View {
    @Binding var text: String
    let isRecording: Bool
    let isRecordingReady: Bool
    let recordingStartSignal: Int
    let liveTranscript: String
    let onSend: () -> Void
    let onMicPressDown: () -> Void
    let onMicCommit: () -> Void
    let onMicCancel: () -> Void

    @State private var isPressing = false
    @State private var willCancel = false
    @State private var pressStartedAt: Date?
    @State private var haptics = VoiceInputHaptics()

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
                Text(recordingDisplayText)
                    .font(.system(size: 15))
                    .foregroundStyle(recordingDisplayTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
            }
            .frame(maxHeight: 70)

            HStack(spacing: 12) {
                WaveformView(isActive: isRecordingReady && !willCancel, tint: willCancel ? Theme.danger : Color.white)
                    .padding(.leading, 18)
                Spacer(minLength: 8)
                promptText
                    .padding(.trailing, 18)
            }
            .padding(.bottom, 12)
        }
        .frame(minHeight: 120)
    }

    private var recordingDisplayText: String {
        if !isRecordingReady {
            return L("Starting recording…")
        }
        return liveTranscript.isEmpty ? L("Listening…") : liveTranscript
    }

    private var recordingDisplayTextColor: Color {
        if !isRecordingReady || liveTranscript.isEmpty {
            return Color.white.opacity(0.5)
        }
        return Color.white.opacity(0.92)
    }

    private var promptText: some View {
        let sendPrompt = L("Release to send · Slide up to cancel")
        let cancelPrompt = L("Release to cancel")

        return ZStack(alignment: .trailing) {
            Text(sendPrompt).hidden()
            Text(cancelPrompt).hidden()
            Text(willCancel ? cancelPrompt : sendPrompt)
                .foregroundStyle(willCancel ? Theme.danger : Color.white.opacity(0.55))
                .transaction { $0.animation = nil }
        }
        .font(.system(size: 11, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .accessibilityLabel(willCancel ? cancelPrompt : sendPrompt)
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
                        haptics.recordingStarted()
                        onMicPressDown()
                    }
                    let nextWillCancel = value.translation.height < cancelThreshold
                    if nextWillCancel != willCancel {
                        willCancel = nextWillCancel
                        haptics.cancelStateChanged()
                    }
                }
                .onEnded { value in
                    let pressed = pressStartedAt
                    let cancel = willCancel || value.translation.height < cancelThreshold
                    isPressing = false
                    pressStartedAt = nil

                    if cancel {
                        onMicCancel()
                        willCancel = false
                        return
                    }
                    guard isRecordingReady else {
                        onMicCancel()
                        willCancel = false
                        return
                    }
                    willCancel = false
                    let elapsed = pressed.map { Date().timeIntervalSince($0) } ?? 0
                    if elapsed < minDuration {
                        onMicCancel()
                        return
                    }
                    haptics.recordingCommitted()
                    onMicCommit()
                }
        )
    }
}

private final class VoiceInputHaptics {
    private var engine: CHHapticEngine?
    private let startFallback = UIImpactFeedbackGenerator(style: .medium)
    private let cancel = UIImpactFeedbackGenerator(style: .rigid)
    private let commit = UINotificationFeedbackGenerator()
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    init() {
        bootEngine()
        startFallback.prepare()
        cancel.prepare()
        commit.prepare()
    }

    private func bootEngine() {
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = false
            engine.resetHandler = { [weak self] in
                guard let self else { return }
                try? self.engine?.start()
            }
            engine.stoppedHandler = { [weak self] _ in
                guard let self else { return }
                try? self.engine?.start()
            }
            try engine.start()
            self.engine = engine
        } catch {
            self.engine = nil
        }
    }

    func recordingStarted() {
        if playTransient(intensity: 0.9, sharpness: 0.5) { return }
        startFallback.impactOccurred(intensity: 0.9)
        startFallback.prepare()
    }

    func cancelStateChanged() {
        if playTransient(intensity: 0.75, sharpness: 0.7) { return }
        cancel.impactOccurred(intensity: 0.75)
        cancel.prepare()
    }

    func recordingCommitted() {
        if playSuccessPattern() { return }
        commit.notificationOccurred(.success)
        commit.prepare()
    }

    private func playSuccessPattern() -> Bool {
        guard supportsHaptics, let engine else { return false }
        do {
            try engine.start()
            let first = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            )
            let second = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.1
            )
            let pattern = try CHHapticPattern(events: [first, second], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    private func playTransient(intensity: Float, sharpness: Float) -> Bool {
        guard supportsHaptics, let engine else { return false }
        do {
            try engine.start()
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            return true
        } catch {
            return false
        }
    }
}
