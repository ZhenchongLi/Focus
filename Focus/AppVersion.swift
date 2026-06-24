import Foundation

enum AppVersion {
    static func shortVersion(infoDictionary: [String: Any]?) -> String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static func shortVersion(bundle: Bundle = .main) -> String {
        return shortVersion(infoDictionary: bundle.infoDictionary)
    }
}
