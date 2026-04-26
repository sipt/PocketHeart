import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let isRecording: Bool
    let liveTranscript: String
    let onSend: () -> Void
    let onMicTap: () -> Void
    let onMicCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { /* keyboard mode toggle */ }) {
                Image(systemName: "keyboard").foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.07), in: Circle())
            }

            ZStack {
                if isRecording {
                    Text(liveTranscript.isEmpty ? L("Listening…") : liveTranscript)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                } else {
                    TextField("Tell me what you spent…", text: $text, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .tint(Theme.primary)
                        .lineLimit(1...4)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRecording {
                Button(action: onSend) {
                    Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white).frame(width: 38, height: 38)
                        .background(Theme.primary, in: Circle())
                }
            } else {
                Button(action: { isRecording ? onMicCancel() : onMicTap() }) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white).frame(width: 38, height: 38)
                        .background(isRecording ? Theme.danger : Theme.primary, in: Circle())
                        .shadow(color: Theme.primary.opacity(0.4), radius: 10, y: 4)
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.25).onEnded { _ in onMicTap() })
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
