import AVFoundation

final class TTS {
    private let synth = AVSpeechSynthesizer()

    func stop(immediately: Bool = true) {
        if synth.isSpeaking {
            synth.stopSpeaking(at: immediately ? .immediate : .word)
        }
    }

    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Avoid overlapping speech.
        stop(immediately: true)

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = 0.48

        // Heuristic: choose voice by script detection.
        if trimmed.range(of: "[가-힣]", options: .regularExpression) != nil {
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        synth.speak(utterance)
    }
}
