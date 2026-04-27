import SwiftUI
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

private enum InputMode: Equatable {
    case voice
    case text
}

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

    @State private var mode: InputMode = .voice
    @State private var isPressing = false
    @State private var willCancel = false
    @State private var pressStartedAt: Date?
    @State private var haptics = VoiceInputHaptics()
    @FocusState private var textFocused: Bool
    @Namespace private var morph

    private let cancelThreshold: CGFloat = -60
    private let minDuration: TimeInterval = 0.30

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            if isRecording {
                recordingPopup
                    .padding(.horizontal, 12)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity).combined(with: .offset(y: 12)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom))
                    ))
            }

            HStack(alignment: .bottom, spacing: 10) {
                if mode == .voice {
                    keyboardToggleButton
                        .matchedGeometryEffect(id: "leading", in: morph)
                        .padding(.bottom, 6)
                        .opacity(isRecording ? 0.4 : 1)
                        .disabled(isRecording)
                    voicePressBar
                        .matchedGeometryEffect(id: "trailing", in: morph)
                } else {
                    textCapsule
                        .matchedGeometryEffect(id: "leading", in: morph)
                    trailingTextModeButton
                        .matchedGeometryEffect(id: "trailing", in: morph)
                        .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 8)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: isRecording)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: mode)
    }

    // MARK: - Capsule backgrounds

    private func capsuleBackground(highlight: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(highlight ? Theme.danger.opacity(0.7) : Theme.controlStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }

    // MARK: - Voice mode (default)

    private var voicePressBar: some View {
        let label: String = {
            if !isPressing { return L("Hold to talk") }
            if willCancel { return L("Release to cancel") }
            return L("Release to send")
        }()
        let icon = isPressing ? "waveform" : "mic.fill"
        let tint: Color = willCancel ? Theme.danger : Theme.primary

        return HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(Theme.onPrimary)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(tint)
        )
        .shadow(color: tint.opacity(isPressing ? 0.45 : 0.25),
                radius: isPressing ? 14 : 10, y: 4)
        .scaleEffect(isPressing ? 0.985 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressing)
        .animation(.easeInOut(duration: 0.15), value: willCancel)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .gesture(pressGesture)
    }

    // MARK: - Recording popup (floats above the press bar)

    private var recordingPopup: some View {
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
                WaveformView(isActive: isRecordingReady && !willCancel, tint: willCancel ? Theme.danger : Theme.textPrimary)
                    .padding(.leading, 18)
                Spacer(minLength: 8)
                promptText
                    .padding(.trailing, 18)
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(capsuleBackground(highlight: willCancel))
    }

    private var recordingDisplayText: String {
        if !isRecordingReady {
            return L("Starting recording…")
        }
        return liveTranscript.isEmpty ? L("Listening…") : liveTranscript
    }

    private var recordingDisplayTextColor: Color {
        if !isRecordingReady || liveTranscript.isEmpty {
            return Theme.textSecondary
        }
        return Theme.textPrimary
    }

    private var promptText: some View {
        let sendPrompt = L("Release to send · Slide up to cancel")
        let cancelPrompt = L("Release to cancel")

        return ZStack(alignment: .trailing) {
            Text(sendPrompt).hidden()
            Text(cancelPrompt).hidden()
            Text(willCancel ? cancelPrompt : sendPrompt)
                .foregroundStyle(willCancel ? Theme.danger : Theme.textSecondary)
                .transaction { $0.animation = nil }
        }
        .font(.system(size: 11, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .accessibilityLabel(willCancel ? cancelPrompt : sendPrompt)
    }

    // MARK: - Text mode

    private var textCapsule: some View {
        TextField("Tell me what you spent…", text: $text, axis: .vertical)
            .font(.system(size: 16))
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.primary)
            .lineLimit(1...4)
            .focused($textFocused)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(capsuleBackground())
    }

    @ViewBuilder
    private var trailingTextModeButton: some View {
        if hasText {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.onPrimary)
                    .frame(width: 44, height: 44)
                    .background(Theme.success, in: Circle())
                    .shadow(color: Theme.success.opacity(0.35), radius: 8, y: 4)
            }
            .transition(.scale.combined(with: .opacity))
        } else {
            Button {
                textFocused = false
                mode = .voice
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.onPrimary)
                    .frame(width: 44, height: 44)
                    .background(Theme.primary, in: Circle())
                    .shadow(color: Theme.primary.opacity(0.3), radius: 8, y: 4)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Keyboard toggle (voice mode, leading, monochrome)

    private var keyboardToggleButton: some View {
        Button {
            mode = .text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                textFocused = true
            }
        } label: {
            Image(systemName: "keyboard")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.controlStroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        }
    }

    // MARK: - Press gesture (shared by voice capsule & recording capsule)

    private var pressGesture: some Gesture {
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
