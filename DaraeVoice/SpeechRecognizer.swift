import Foundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {
    enum State {
        case idle
        case listening
        case processing
        case error(String)
    }

    @Published var state: State = .idle
    @Published var transcript: String = ""

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private let recognizerKO = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let recognizerEN = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuth() async -> Bool {
        let speech = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in cont.resume(returning: status) }
        }
        return speech == .authorized
    }

    func start() throws {
        transcript = ""
        state = .listening

        task?.cancel(); task = nil
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { throw NSError(domain: "Speech", code: -1) }
        request.shouldReportPartialResults = true

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizerKO?.recognitionTask(with: request) { [weak self] result, err in
            guard let self else { return }
            if let r = result {
                Task { @MainActor in self.transcript = r.bestTranscription.formattedString }
            }
            if let err {
                Task { @MainActor in self.state = .error(err.localizedDescription) }
            }
        }
    }

    func stop() {
        state = .processing
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
    }

    // Optional: simple re-recognize in EN if KO looks garbled.
    func maybeRefineToEnglishIfNeeded() async {
        let t = transcript
        // Heuristic: if no Hangul and has many ASCII words, keep as-is.
        if t.range(of: "[가-힣]", options: .regularExpression) == nil {
            return
        }
        // Otherwise do nothing for MVP. (Hook point)
    }
}
