import Foundation

/// Resolves the optional scanner/catalog proxy from the `PLANTNET_PROXY_URL` build setting.
///
/// Refusing anything that is not absolute HTTPS is deliberate: a plaintext or malformed origin
/// would send plant photos somewhere unverified, so the app falls back to local behaviour
/// instead of trusting it.
enum ProxyConfiguration {
    static let infoDictionaryKey = "PLANTNET_PROXY_URL"

    static func baseURL(from bundle: Bundle = .main) -> URL? {
        guard let rawValue = bundle.object(forInfoDictionaryKey: infoDictionaryKey) as? String else { return nil }
        return secureURL(from: rawValue)
    }

    static func secureURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              let host = url.host(),
              !host.isEmpty else {
            return nil
        }
        return url
    }
}
