import Foundation

/// AppConfig provides optional build-time defaults without hardcoding secrets in git.
///
/// How to use (in Xcode Target > Info):
/// - Add key: DaraeDefaultToken (String)  -> your token
/// - Add key: DaraeDefaultBaseURL (String) -> e.g. http://172.30.1.66:18795
///
/// These can be set locally and do not need to be committed to GitHub.
struct AppConfig {
    static var defaultToken: String {
        (Bundle.main.object(forInfoDictionaryKey: "DaraeDefaultToken") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static var defaultBaseURL: String {
        (Bundle.main.object(forInfoDictionaryKey: "DaraeDefaultBaseURL") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
