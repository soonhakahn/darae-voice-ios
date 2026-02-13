import SwiftUI

// MARK: - UI Components

private struct HeaderBanner: View {
    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.09, blue: 0.16), Color(red: 0.12, green: 0.23, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Darae Voice")
                            .font(.title2).bold()
                            .foregroundStyle(.white)
                        Text("On-device STT/TTS · Local reports")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.orange)
                }

                Text(Self.todayString())
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko-KR")
        f.dateFormat = "yyyy.MM.dd (E)"
        return f.string(from: Date())
    }
}

private struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .foregroundStyle(color)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.55 : 1.0)
        .disabled(disabled)
    }
}

// MARK: - Content

struct ContentView: View {
    @StateObject private var speech = SpeechRecognizer()
    private let tts = TTS()

    // Persist so the user only enters these once.
    @AppStorage("darae.serverBaseURL") private var serverBaseURL: String = "http://172.30.1.66:18795"
    @AppStorage("darae.serverToken") private var serverToken: String = ""

    @State private var lastResponse: String = ""
    @State private var isAuthed: Bool = false
    @State private var speakSummaryOnly: Bool = true
    @State private var showSettings: Bool = false

    private var tokenEmpty: Bool {
        serverToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HeaderBanner()

                // Status pills
                HStack(spacing: 10) {
                    InfoPill(icon: tokenEmpty ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
                             text: tokenEmpty ? "Token 필요" : "Token OK",
                             color: tokenEmpty ? .red : .green)

                    InfoPill(icon: "network",
                             text: "Server: \(shortServerHost())",
                             color: .blue)

                    Spacer()
                }

                // Primary actions (dashboard cards)
                ActionCard(
                    title: "시장 브리핑",
                    subtitle: "오늘 지표/체크포인트를 읽어드립니다.",
                    icon: "newspaper.fill",
                    tint: .indigo,
                    disabled: tokenEmpty
                ) {
                    Task { await readReport(.marketBriefLatest, title: "시장 브리핑") }
                }

                ActionCard(
                    title: "US→KR 프리마켓",
                    subtitle: "미국/반도체/AI 흐름 기반 프리뷰.",
                    icon: "globe.asia.australia.fill",
                    tint: .orange,
                    disabled: tokenEmpty
                ) {
                    Task { await readReport(.us2krLatest, title: "US→KR 프리마켓 리포트") }
                }

                // Voice controls
                GroupBox("말하기") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(speech.transcript.isEmpty ? "(empty)" : speech.transcript)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)

                        HStack {
                            Button("권한") {
                                Task {
                                    isAuthed = await speech.requestAuth()
                                    if !isAuthed {
                                        lastResponse = "Speech permission denied."
                                        tts.speak(lastResponse)
                                    }
                                }
                            }

                            Button("듣기") {
                                do { try speech.start() }
                                catch {
                                    lastResponse = "Failed to start listening: \(error.localizedDescription)"
                                    tts.speak(lastResponse)
                                }
                            }

                            Button("멈춤") {
                                speech.stop()
                                handleIntent()
                            }

                            Spacer()

                            Button("도움말") {
                                lastResponse = "가능한 명령: 시장 브리핑 읽어줘 / 프리마켓 읽어줘 / 도움말"
                                tts.speak(lastResponse)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Toggle("TTS는 요약만 읽기(빠르게)", isOn: $speakSummaryOnly)
                    .font(.subheadline)

                // Response
                GroupBox("Response") {
                    ScrollView {
                        Text(lastResponse.isEmpty ? "(none)" : lastResponse)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 220)
                }

                // Settings
                DisclosureGroup(isExpanded: $showSettings) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Base URL (e.g. http://192.168.0.10:18795)", text: $serverBaseURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.URL)

                        SecureField("Token (required)", text: $serverToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if tokenEmpty {
                            Text("⚠️ Token이 비어있습니다. 서버 토큰을 입력해야 리포트를 가져올 수 있어요.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        } else {
                            Text("Token 저장됨")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Button("/health 테스트") {
                            Task {
                                await testHealth()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                } label: {
                    Text("설정")
                        .font(.headline)
                }
                .padding(.top, 4)

                Spacer(minLength: 16)
            }
            .padding()
        }
    }

    // MARK: - Logic

    private func handleIntent() {
        let input = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let routed = IntentRouter.route(input)

        Task {
            switch routed.intent {
            case .help:
                lastResponse = "가능한 명령: 시장 브리핑 읽어줘 / 프리마켓 읽어줘 / 도움말"
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
        if tokenEmpty {
            lastResponse = "Token이 비어있습니다. 설정에서 Token을 입력해 주세요."
            tts.speak(lastResponse)
            return
        }

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
            let msg = error.localizedDescription
            if msg.contains("401") {
                lastResponse = "Failed to fetch \(title): HTTP 401 (Token을 확인해 주세요)"
            } else if msg.lowercased().contains("offline") {
                lastResponse = "Failed to fetch \(title): offline (Safari에서 /health 확인)"
            } else {
                lastResponse = "Failed to fetch \(title): \(msg)"
            }
            tts.speak(lastResponse)
        }
    }

    private func testHealth() async {
        guard let base = URL(string: serverBaseURL) else {
            lastResponse = "Invalid Base URL"
            return
        }
        let url = base.appendingPathComponent("/health")
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            lastResponse = "Health: \(String(decoding: data, as: UTF8.self))"
        } catch {
            lastResponse = "Health check failed: \(error.localizedDescription)"
        }
    }

    private func shortServerHost() -> String {
        guard let u = URL(string: serverBaseURL) else { return "(invalid)" }
        return [u.host ?? "?", u.port.map(String.init)].compactMap { $0 }.joined(separator: ":")
    }
}
