import Foundation
import AVFoundation
import Speech

protocol SpeechServiceProtocol: AnyObject, Sendable {
    func requestAuthorization() async -> Bool
    func startRecording(locale: Locale, onPartial: @Sendable @escaping (String) -> Void) async throws
    func stop() async throws -> String
    func cancel()
}

enum SpeechServiceError: Error {
    case permissionDenied
    case recognizerUnavailable
    case audioEngineFailure(String)
}

@MainActor
final class SpeechService: SpeechServiceProtocol {
    private var recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var lastTranscript: String = ""

    func requestAuthorization() async -> Bool {
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let micOK = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        return speechOK && micOK
    }

    func startRecording(locale: Locale, onPartial: @Sendable @escaping (String) -> Void) async throws {
        recognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer, recognizer.isAvailable else { throw SpeechServiceError.recognizerUnavailable }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do { try audioEngine.start() }
        catch { throw SpeechServiceError.audioEngineFailure(error.localizedDescription) }
        lastTranscript = ""
        task = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result else { return }
            self.lastTranscript = result.bestTranscription.formattedString
            onPartial(self.lastTranscript)
        }
    }

    func stop() async throws -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        let final = lastTranscript
        request = nil
        task = nil
        recognizer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return final
    }

    func cancel() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        request = nil
        recognizer = nil
    }
}
