import SwiftUI

struct ContentView: View {
    @StateObject private var speech = SpeechRecognizer()
    private let tts = TTS()

    // TODO: set these tomorrow after we confirm Mac IP.
    @State private var serverBaseURL: String = "http://<MAC_IP>:18795"
    @State private var serverToken: String = "<TOKEN>"

    @State private var lastResponse: String = ""
    @State private var isAuthed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Darae Voice (MVP)")
                .font(.title2).bold()

            GroupBox("Server") {
                VStack(alignment: .leading) {
                    TextField("Base URL (e.g. http://192.168.0.10:18795)", text: $serverBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Token", text: $serverToken)
                }
            }

            GroupBox("You said") {
                Text(speech.transcript.isEmpty ? "(empty)" : speech.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
            }

            HStack {
                Button {
                    Task {
                        isAuthed = await speech.requestAuth()
                        if !isAuthed {
                            lastResponse = "Speech permission denied."
                            tts.speak(lastResponse)
                        }
                    }
                } label: {
                    Text("Request Permission")
                }

                Button {
                    do { try speech.start() }
                    catch {
                        lastResponse = "Failed to start listening: \(error.localizedDescription)"
                        tts.speak(lastResponse)
                    }
                } label: {
                    Text("Listen")
                }

                Button {
                    speech.stop()
                    handleIntent()
                } label: {
                    Text("Stop")
                }
            }

            GroupBox("Response") {
                ScrollView {
                    Text(lastResponse.isEmpty ? "(none)" : lastResponse)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
            }

            Spacer()
        }
        .padding()
    }

    private func handleIntent() {
        let input = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let routed = IntentRouter.route(input)

        Task {
            switch routed.intent {
            case .help:
                lastResponse = "I can read the market brief, read the US-to-KR premarket report, and add reminders or todos. Say: 시장 브리핑 읽어줘 / 프리마켓 읽어줘 / 리마인더 추가해줘."
                tts.speak(lastResponse)

            case .readUS2KR:
                await readReport(.us2krLatest, title: "US→KR 프리마켓 리포트")

            case .readMarketBrief:
                await readReport(.marketBriefLatest, title: "시장 브리핑")

            case .addReminder:
                lastResponse = "(MVP) 리마인더 추가는 내일 구현할게요."
                tts.speak(lastResponse)

            case .addTodo:
                lastResponse = "(MVP) 할 일 추가는 내일 구현할게요."
                tts.speak(lastResponse)

            case .unknown:
                lastResponse = "죄송해요. 지금은 시장 브리핑/프리마켓 읽기만 지원해요. '도움말'이라고 말해보실래요?"
                tts.speak(lastResponse)
            }
        }
    }

    private func readReport(_ endpoint: ReportClient.Endpoint, title: String) async {
        guard let base = URL(string: serverBaseURL) else {
            lastResponse = "Invalid Base URL"
            tts.speak(lastResponse)
            return
        }
        let client = ReportClient(config: .init(baseURL: base, token: serverToken))

        do {
            let text = try await client.fetch(endpoint)
            lastResponse = "[\(title)]\n\n" + text
            // Speak only the first chunk for MVP.
            let speakText = String(lastResponse.prefix(1200))
            tts.speak(speakText)
        } catch {
            lastResponse = "Failed to fetch \(title): \(error.localizedDescription)"
            tts.speak(lastResponse)
        }
    }
}
