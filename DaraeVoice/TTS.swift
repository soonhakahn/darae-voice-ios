import AVFoundation

final class TTS {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.48

        // Heuristic: choose voice by script detection.
        if text.range(of: "[가-힣]", options: .regularExpression) != nil {
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        synth.speak(utterance)
    }
}
