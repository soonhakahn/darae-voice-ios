# Darae Voice MVP — Intent Spec (초안)

## 공통
- 입력: STT 결과 텍스트(ko/en 혼용 가능)
- 출력: (a) 화면 표시 텍스트 (b) TTS로 읽을 문장

## Intent 1) READ_MARKET_BRIEF
- 트리거 예시:
  - "시장 브리핑 읽어줘"
  - "오늘 시장 요약 읽어줘"
  - "market brief"
- 동작:
  - GET /reports/market-brief/latest (토큰 포함)
  - 길면 1) 상단 요약 2) 이어읽기(사용자 확인)로 분할

## Intent 2) READ_US2KR
- 트리거 예시:
  - "US to KR 읽어줘"
  - "프리마켓 읽어줘"
  - "미국 마감 요약"
- 동작:
  - GET /reports/us2kr/latest

## Intent 3) ADD_REMINDER
- 트리거 예시:
  - "리마인더 추가해줘 내일 아침 7시에 운동"
  - "Remind me tomorrow 7am to exercise"
- 파싱:
  - 시간(상대/절대) + 내용
- 동작:
  - 로컬 알림(UserNotifications) 생성

## Intent 4) ADD_TODO
- 트리거 예시:
  - "할 일 추가해줘 이메일 보내기"
  - "Add a todo: ..."
- 동작:
  - 앱 로컬 저장(UserDefaults/SQLite)

## Intent 5) HELP
- 트리거:
  - "도움말"
  - "what can you do"
- 동작:
  - 가능한 명령어 예시를 TTS로 안내

## Fallback
- 위 어떤 것도 아니면:
  - "제가 할 수 있는 건 시장 브리핑 읽기, 프리마켓 읽기, 리마인더/할 일 추가예요. '도움말'이라고 말해보실래요?"
