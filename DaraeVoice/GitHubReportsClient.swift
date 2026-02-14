import Foundation

struct GitHubReportsClient {
    // Public repo raw URLs
    // e.g. https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path>
    let baseRawURL: URL

    enum Endpoint {
        case us2krLatest
        case marketBriefLatest

        var path: String {
            switch self {
            case .us2krLatest: return "/reports/us2kr/latest.md"
            case .marketBriefLatest: return "/reports/market-brief/latest.md"
            }
        }
    }

    func fetch(_ endpoint: Endpoint) async throws -> String {
        // baseRawURL should be like: https://raw.githubusercontent.com/soonhakahn/darae-reports/main
        let url = baseRawURL.appendingPathComponent(endpoint.path)
        var req = URLRequest(url: url)
        req.timeoutInterval = 10

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "GitHubReportsClient", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"
            ])
        }
        return String(decoding: data, as: UTF8.self)
    }
}
