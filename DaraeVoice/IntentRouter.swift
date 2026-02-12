import Foundation

enum DaraeIntent: String {
    case readMarketBrief
    case readUS2KR
    case addReminder
    case addTodo
    case help
    case unknown
}

typealias IntentResult = (intent: DaraeIntent, slots: [String: String])

struct IntentRouter {
    static func route(_ text: String) -> IntentResult {
        let t = text.lowercased()

        // Help
        if t.contains("help") || t.contains("도움") || t.contains("할 수") {
            return (.help, [:])
        }

        // Read market brief
        if t.contains("시장") && (t.contains("브리핑") || t.contains("요약") || t.contains("읽")) {
            return (.readMarketBrief, [:])
        }
        if t.contains("market") && (t.contains("brief") || t.contains("summary")) {
            return (.readMarketBrief, [:])
        }

        // Read US2KR
        if t.contains("프리마켓") || t.contains("us2kr") || (t.contains("미국") && t.contains("마감")) {
            return (.readUS2KR, [:])
        }
        if t.contains("us") && t.contains("kr") {
            return (.readUS2KR, [:])
        }

        // Add reminder (stub)
        if t.contains("리마인") || t.contains("remind") {
            return (.addReminder, ["raw": text])
        }

        // Add todo (stub)
        if t.contains("할 일") || t.contains("todo") {
            return (.addTodo, ["raw": text])
        }

        return (.unknown, ["raw": text])
    }
}
