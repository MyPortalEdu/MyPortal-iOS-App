import Foundation

nonisolated struct AuthTokens: Codable, Equatable, Sendable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
}

nonisolated enum TokenStore {
    private static let key = "auth.tokens"

    static func save(_ tokens: AuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        try Keychain.set(String(decoding: data, as: UTF8.self), for: key)
    }

    static func load() -> AuthTokens? {
        guard let raw = Keychain.get(key), let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }

    static func clear() {
        Keychain.delete(key)
    }
}
