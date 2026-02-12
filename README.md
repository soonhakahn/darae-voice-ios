# Darae Voice (iOS) — 0원(온디바이스) 말하는 비서 MVP

> 목표: iPhone에서 버튼을 눌러 말하면(한/영 혼용), 다래가 이해(규칙 기반)하고 **음성(TTS)** 으로 답합니다.
> 
> - 과금 0원: OpenAI/클라우드 LLM/TTS/STT 사용 안 함
> - STT: iOS Speech
> - TTS: AVSpeechSynthesizer
> - Intent: 규칙 기반(명령어 중심)
> - OpenClaw 연동: 맥에서 로컬 리포트 서버를 띄워 iPhone이 읽어오게 함 (LAN + 토큰)

## 이 레포에 들어있는 것
- `DaraeVoice/` : SwiftUI 코드 파일(프로젝트에 그대로 추가)
- `../../scripts/darae_report_server.py` : 맥 로컬 리포트 서버(읽기 전용)
- `spec_intents.md` : Intent 설계 초안

> iOS 앱은 GitHub HTTP 링크만으로 “클릭 설치”는 불가합니다(iOS 정책). 무료(0원)로는 **Xcode로 1회 설치(Run)** 가 필요합니다.

---

## 1) 맥 로컬 리포트 서버 실행

```bash
export DARAE_REPORT_SERVER_TOKEN='CHANGE_ME_LONG_RANDOM'
export DARAE_REPORT_SERVER_PORT=18795
cd ~/.openclaw/workspace
python3 scripts/darae_report_server.py
```

테스트:

```bash
curl -s http://127.0.0.1:18795/health
curl -s -H "X-Api-Token: $DARAE_REPORT_SERVER_TOKEN" http://127.0.0.1:18795/reports/us2kr/latest | head
```

맥 로컬 IP 확인(와이파이):

```bash
ipconfig getifaddr en0 || ipconfig getifaddr en1
```

---

## 2) iOS 앱 생성/설치 (0원)

### 준비
- Xcode 설치
- iPhone에서 Developer Mode 켜기(안내에 따라)

### 방법(가장 단순)
1) Xcode → File → New → Project → iOS App (SwiftUI)
2) Product Name: `DaraeVoice`
3) 생성된 프로젝트에 이 레포의 `DaraeVoice/*.swift` 파일들을 **드래그 앤 드롭으로 추가**
4) `ContentView.swift`에서
   - `serverBaseURL`을 `http://<맥IP>:18795` 로
   - `serverToken`을 `$DARAE_REPORT_SERVER_TOKEN` 값으로 맞춤
5) Run(▶) 눌러 iPhone에 설치

권한:
- `NSSpeechRecognitionUsageDescription`
- `NSMicrophoneUsageDescription`
(프로젝트 생성 시 자동 추가가 안 되면 Info.plist에 추가 필요)

---

## 3) MVP 음성 명령 예시
- "시장 브리핑 읽어줘"
- "프리마켓 읽어줘"
- "도움말"

---

## 보안 메모
- 서버는 **외부 공개 금지(포트포워딩 금지)**
- 토큰은 길고 랜덤하게
