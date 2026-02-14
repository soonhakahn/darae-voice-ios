import SwiftUI
import UIKit

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

    // Public GitHub raw base (no auth).
    @AppStorage("darae.githubRawBase") private var githubRawBase: String = "https://raw.githubusercontent.com/soonhakahn/darae-reports/main"

    @State private var lastResponse: String = ""
    @State private var isAuthed: Bool = false
    @State private var speakSummaryOnly: Bool = true
    @State private var showSettings: Bool = false

    @State private var showIntradayRequestSheet: Bool = false
    @AppStorage("darae.intradayRequestText") private var intradayRequestText: String = ""

    private var tokenEmpty: Bool {
        serverToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HeaderBanner()

                // One-time autofill: if token/URL is empty, try build-time defaults from Info.plist.
                // This avoids re-typing after reinstall while still not committing secrets to GitHub.
                .task {
                    if serverToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let t = AppConfig.defaultToken
                        if !t.isEmpty { serverToken = t }
                    }
                    if serverBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let u = AppConfig.defaultBaseURL
                        if !u.isEmpty { serverBaseURL = u }
                    }
                }

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
                    title: "시장 브리핑 (GitHub)",
                    subtitle: "어디서나: GitHub 최신본을 가져옵니다.",
                    icon: "tray.and.arrow.down.fill",
                    tint: .blue,
                    disabled: false
                ) {
                    Task { await readGitHubReport(.marketBriefLatest, title: "시장 브리핑") }
                }

                ActionCard(
                    title: "US→KR 프리마켓 (GitHub)",
                    subtitle: "어디서나: GitHub 최신본을 가져옵니다.",
                    icon: "tray.and.arrow.down.fill",
                    tint: .teal,
                    disabled: false
                ) {
                    Task { await readGitHubReport(.us2krLatest, title: "US→KR 프리마켓 리포트") }
                }

                ActionCard(
                    title: "장중 업데이트 요청(텔레그램)",
                    subtitle: "요청 문구를 작성한 뒤 텔레그램 공유 화면으로 보냅니다.",
                    icon: "paperplane.fill",
                    tint: .purple,
                    disabled: false
                ) {
                    showIntradayRequestSheet = true
                }

                // Optional local mode (LAN only)
                ActionCard(
                    title: "시장 브리핑 (로컬)",
                    subtitle: "맥 서버에서 읽어옵니다(LAN 필요).",
                    icon: "newspaper.fill",
                    tint: .indigo,
                    disabled: tokenEmpty
                ) {
                    Task { await readReport(.marketBriefLatest, title: "시장 브리핑") }
                }

                ActionCard(
                    title: "US→KR 프리마켓 (로컬)",
                    subtitle: "맥 서버에서 읽어옵니다(LAN 필요).",
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

                            Button("TTS 테스트") {
                                lastResponse = "TTS 테스트입니다. 소리가 들리면 정상입니다."
                                tts.speak(lastResponse)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                HStack {
                    Toggle("TTS는 요약만 읽기(빠르게)", isOn: $speakSummaryOnly)
                        .font(.subheadline)

                    Spacer()

                    Button("읽기 중단") {
                        tts.stop(immediately: true)
                    }
                    .buttonStyle(.bordered)
                }

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

                        Button("클립보드에서 Token 붙여넣기") {
                            let pasted = UIPasteboard.general.string ?? ""
                            serverToken = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .buttonStyle(.bordered)

                        if tokenEmpty {
                            Text("⚠️ Token이 비어있습니다. 서버 토큰을 입력해야 리포트를 가져올 수 있어요.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        } else {
                            Text("Token 저장됨")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Button("/health 테스트(로컬)") {
                            Task { await testHealth() }
                        }
                        .buttonStyle(.bordered)

                        TextField("GitHub Raw Base (public)", text: $githubRawBase)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.footnote)
                            .textContentType(.URL)
                            .padding(.top, 4)

                        Text("예: https://raw.githubusercontent.com/soonhakahn/darae-reports/main")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
        .sheet(isPresented: $showIntradayRequestSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("장중 업데이트 요청 문구")
                        .font(.headline)

                    ZStack(alignment: .topLeading) {
                        if intradayRequestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("예) 코스피/코스닥, 원달러, 반도체 중심으로 5줄 요약 부탁")
                                .foregroundStyle(.secondary)
                                .padding(.top, 10)
                                .padding(.leading, 6)
                        }

                        TextEditor(text: $intradayRequestText)
                            .font(.body)
                            .frame(minHeight: 140)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )

                    Text("프리셋")
                        .font(.subheadline).bold()

                    // Preset chips
                    HStack(spacing: 8) {
                        Button("기본") {
                            intradayRequestText = "코스피/코스닥, 원달러, 반도체(삼성전자/하이닉스) 중심으로 5줄 요약 부탁."
                        }
                        .buttonStyle(.bordered)

                        Button("반도체") {
                            intradayRequestText = "반도체(삼성전자/하이닉스) 수급/흐름 + SOXX/NVDA 영향 5줄."
                        }
                        .buttonStyle(.bordered)

                        Button("지수") {
                            intradayRequestText = "코스피/코스닥 지수 흐름, 주도 테마, 상위 대형주 체크 5줄."
                        }
                        .buttonStyle(.bordered)

                        Button("비우기") {
                            intradayRequestText = ""
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    HStack {
                        Button("취소") { showIntradayRequestSheet = false }
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Open") {
                            // Open Telegram share with current text (can be empty; user may type in Telegram).
                            let msg = intradayRequestText.trimmingCharacters(in: .whitespacesAndNewlines)
                            showIntradayRequestSheet = false
                            openTelegramShare(text: msg.isEmpty ? "다래 장중 업데이트 요청" : "다래 장중 업데이트 요청: \(msg)")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .navigationTitle("장중 요청")
                .navigationBarTitleDisplayMode(.inline)
            }
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
            lastResponse = "Token이 비어있습니다. 설정에서 Token을 입력해 주세요. (로컬 서버용)"
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

    private func readGitHubReport(_ endpoint: GitHubReportsClient.Endpoint, title: String) async {
        guard let base = URL(string: githubRawBase) else {
            lastResponse = "Invalid GitHub Raw Base URL"
            tts.speak(lastResponse)
            return
        }
        let client = GitHubReportsClient(baseRawURL: base)

        do {
            let text = try await client.fetch(endpoint)
            lastResponse = "[\(title) · GitHub]\n\n" + text

            let speakText: String
            if speakSummaryOnly {
                speakText = String(lastResponse.prefix(1400))
            } else {
                speakText = String(lastResponse.prefix(4000))
            }
            tts.speak(speakText)
        } catch {
            lastResponse = "Failed to fetch \(title) from GitHub: \(error.localizedDescription)"
            tts.speak(lastResponse)
        }
    }

    private func shortServerHost() -> String {
        guard let u = URL(string: serverBaseURL) else { return "(invalid)" }
        return [u.host ?? "?", u.port.map(String.init)].compactMap { $0 }.joined(separator: ":")
    }

    private func openTelegramShare(text: String) {
        // Opens Telegram share UI (works even without knowing the user's chat id).
        // The user can pick "Saved Messages" or their own DM.
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://t.me/share/url?text=\(encoded)"
        guard let url = URL(string: urlString) else {
            lastResponse = "Failed to open Telegram share."
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
