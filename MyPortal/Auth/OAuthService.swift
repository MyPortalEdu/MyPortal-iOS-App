import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

enum OAuthError: Error, LocalizedError {
    case missingSchool
    case missingCode
    case userCancelled
    case tokenExchange(String)

    var errorDescription: String? {
        switch self {
        case .missingSchool: return "No school is configured."
        case .missingCode: return "Authorization code was not returned."
        case .userCancelled: return "Sign in was cancelled."
        case .tokenExchange(let msg): return "Token exchange failed: \(msg)"
        }
    }
}

@MainActor
final class OAuthService: NSObject {
    nonisolated static let shared = OAuthService()

    override nonisolated init() {
        super.init()
    }

    private static let clientID = "myportal-client"
    private static let redirectURI = "myportal://oauth/callback"
    private static let scopes = ["openid", "profile", "email", "offline_access", "api"]

    private var presentationAnchor: ASPresentationAnchor?

    /// Runs the full Authorization Code + PKCE flow. Must be called from a view that
    /// can supply a presentation anchor (the current key window).
    func signIn(presentationAnchor: ASPresentationAnchor) async throws -> AuthTokens {
        guard let config = SchoolConfigStore.load() else { throw OAuthError.missingSchool }
        self.presentationAnchor = presentationAnchor

        let verifier = Self.randomURLSafeString(length: 64)
        let challenge = Self.codeChallenge(for: verifier)
        let state = Self.randomURLSafeString(length: 32)

        let authURL = try Self.buildAuthorizeURL(base: config.baseURL, challenge: challenge, state: state)
        let callback = try await startWebAuthSession(url: authURL)

        guard let components = URLComponents(url: callback, resolvingAgainstBaseURL: false),
              let items = components.queryItems else {
            throw OAuthError.missingCode
        }
        let returnedState = items.first(where: { $0.name == "state" })?.value
        guard returnedState == state else { throw OAuthError.tokenExchange("State mismatch.") }
        guard let code = items.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.missingCode
        }

        return try await exchangeCode(code, verifier: verifier, base: config.baseURL)
    }

    /// Swaps a refresh token for a fresh access token. Used by APIClient on 401.
    func refresh(refreshToken: String) async throws -> AuthTokens {
        guard let config = SchoolConfigStore.load() else { throw OAuthError.missingSchool }
        let params: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": Self.clientID
        ]
        return try await postToken(params: params, base: config.baseURL)
    }

    private func exchangeCode(_ code: String, verifier: String, base: URL) async throws -> AuthTokens {
        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Self.redirectURI,
            "client_id": Self.clientID,
            "code_verifier": verifier
        ]
        return try await postToken(params: params, base: base)
    }

    private func postToken(params: [String: String], base: URL) async throws -> AuthTokens {
        guard let url = URL(string: "connect/token", relativeTo: base) else {
            throw OAuthError.tokenExchange("Invalid token URL.")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = Self.formEncode(params).data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw OAuthError.tokenExchange("No response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw OAuthError.tokenExchange(String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)")
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int
        }
        let parsed = try JSONDecoder().decode(TokenResponse.self, from: data)
        return AuthTokens(
            accessToken: parsed.access_token,
            refreshToken: parsed.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(parsed.expires_in))
        )
    }

    // MARK: - ASWebAuthenticationSession plumbing

    private func startWebAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "myportal"
            ) { callback, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: OAuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: OAuthError.missingCode)
                    return
                }
                continuation.resume(returning: callback)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    // MARK: - Helpers

    private static func buildAuthorizeURL(base: URL, challenge: String, state: String) throws -> URL {
        guard var components = URLComponents(url: base.appendingPathComponent("connect/authorize"), resolvingAgainstBaseURL: false) else {
            throw OAuthError.tokenExchange("Bad authorize URL.")
        }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let url = components.url else { throw OAuthError.tokenExchange("Bad authorize URL.") }
        return url
    }

    private static func randomURLSafeString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func formEncode(_ params: [String: String]) -> String {
        var cs = CharacterSet.urlQueryAllowed
        cs.remove(charactersIn: "+&=")
        return params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: cs) ?? "")" }
            .joined(separator: "&")
    }
}

extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            if let anchor = self.presentationAnchor { return anchor }
            // `signIn(presentationAnchor:)` always caches a real anchor before
            // starting the session, so this fallback only fires in pathological
            // states (e.g. the originating window scene was torn down mid-flow).
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first
            guard let scene else {
                preconditionFailure("No window scene available to anchor the OAuth flow.")
            }
            return UIWindow(windowScene: scene)
        }
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
