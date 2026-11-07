import Foundation

/// Reads 42 API credentials injected into Info.plist from the `.env` file (via Config/App.xcconfig).
struct AppConfig {
    let uid: String
    let secret: String

    var isConfigured: Bool { !uid.isEmpty && !secret.isEmpty }

    static let shared = AppConfig(bundle: .main)

    init(uid: String, secret: String) {
        self.uid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        self.secret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(bundle: Bundle) {
        self.init(
            uid: bundle.object(forInfoDictionaryKey: "IntraUID") as? String ?? "",
            secret: bundle.object(forInfoDictionaryKey: "IntraSecret") as? String ?? ""
        )
    }
}
