import SwiftUI

private struct HeaderBanner: View {
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.12, green: 0.23, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.18))
                    .padding(10)
            )

            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(.leading, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Darae Voice")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                    Text("On-device STT/TTS · Local reports")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                }
                Spacer()
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct ContentView: View {
    @StateObject private var speech = SpeechRecognizer()
    private let tts = TTS()

    // Persist so the user only enters these once.
    @AppStorage("darae.serverBaseURL") private var serverBaseURL: String = "http://172.30.1.66:18795"
    @AppStorage("darae.serverToken") private var serverToken: String = ""

    @State private var lastResponse: String = ""
    @State private var isAuthed: Bool = false
    @State private var speakSummaryOnly: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HeaderBanner()

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

                HStack(spacing: 10) {
                    Button("시장 브리핑") {
                        Task { await readReport(.marketBriefLatest, title: "시장 브리핑") }
                    }
                    Button("프리마켓") {
                        Task { await readReport(.us2krLatest, title: "US→KR 프리마켓 리포트") }
                    }
                    Button("도움말") {
                        lastResponse = "가능한 명령: 시장 브리핑 읽어줘 / 프리마켓 읽어줘 / 도움말"
                        tts.speak(lastResponse)
                    }
                }

                Toggle("TTS는 요약만 읽기(빠르게)", isOn: $speakSummaryOnly)
                    .font(.subheadline)

                GroupBox("Response") {
                    ScrollView {
                        Text(lastResponse.isEmpty ? "(none)" : lastResponse)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 180)
                }

                Spacer(minLength: 16)
            }
            .padding()
        }
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

            let speakText: String
            if speakSummaryOnly {
                speakText = String(lastResponse.prefix(1400))
            } else {
                speakText = String(lastResponse.prefix(4000))
            }
            tts.speak(speakText)
        } catch {
            // Make common failures human-readable.
            let msg = error.localizedDescription
            if msg.contains("401") {
                lastResponse = "Failed to fetch \(title): HTTP 401 (Token을 확인해 주세요)"
            } else if msg.lowercased().contains("offline") {
                lastResponse = "Failed to fetch \(title): offline (iPhone Safari에서 /health 확인)"
            } else {
                lastResponse = "Failed to fetch \(title): \(msg)"
            }
            tts.speak(lastResponse)
        }
    }
}
