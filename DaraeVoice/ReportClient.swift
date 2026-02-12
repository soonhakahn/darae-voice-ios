import Foundation

struct ReportClient {
    struct Config {
        var baseURL: URL
        var token: String
    }

    let config: Config

    enum Endpoint {
        case health
        case us2krLatest
        case marketBriefLatest

        var path: String {
            switch self {
            case .health: return "/health"
            case .us2krLatest: return "/reports/us2kr/latest"
            case .marketBriefLatest: return "/reports/market-brief/latest"
            }
        }
    }

    func fetch(_ endpoint: Endpoint) async throws -> String {
        let url = config.baseURL.appendingPathComponent(endpoint.path)
        var req = URLRequest(url: url)
        req.setValue(config.token, forHTTPHeaderField: "X-Api-Token")
        req.timeoutInterval = 8

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ReportClient", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"
            ])
        }
        return String(decoding: data, as: UTF8.self)
    }
}
