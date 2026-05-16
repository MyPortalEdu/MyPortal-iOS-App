import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
final class AppSession {
    enum Phase: Equatable {
        case loading
        case needsSchool
        case needsLogin
        case authenticated(UserInfo)
    }

    private(set) var phase: Phase = .loading
    private(set) var school: SchoolConfig?

    let apiClient: APIClient

    // Default expression is `nil` rather than `LiveAPIClient.shared` because
    // default-arg expressions are evaluated nonisolated regardless of the
    // enclosing init's isolation, and `LiveAPIClient.shared` is MainActor.
    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? LiveAPIClient.shared
    }

    func bootstrap() async {
        // Re-entry guard: views fire `.task` on every appearance; previews seed
        // a non-loading phase up front, and either way we don't want to clobber it.
        guard phase == .loading else { return }

        school = SchoolConfigStore.load()

        guard school != nil else {
            phase = .needsSchool
            return
        }

        guard TokenStore.load() != nil else {
            phase = .needsLogin
            return
        }

        do {
            let me: UserInfo = try await apiClient.get("connect/userinfo")
            phase = .authenticated(me)
        } catch {
            phase = .needsLogin
        }
    }

    func setSchool(_ config: SchoolConfig) {
        SchoolConfigStore.save(config)
        school = config
        phase = .needsLogin
    }

    func signIn(presentationAnchor: ASPresentationAnchor) async throws {
        let tokens = try await OAuthService.shared.signIn(presentationAnchor: presentationAnchor)
        try TokenStore.save(tokens)
        let me: UserInfo = try await apiClient.get("connect/userinfo")
        phase = .authenticated(me)
    }

    func signOut() {
        TokenStore.clear()
        phase = .needsLogin
    }

    func forgetSchool() {
        TokenStore.clear()
        SchoolConfigStore.clear()
        school = nil
        phase = .needsSchool
    }

    #if DEBUG
    /// Build a session pre-loaded into a specific phase, with no networking, for
    /// SwiftUI previews. The mock client only answers paths you've explicitly stubbed.
    static func preview(
        phase: Phase = .needsLogin,
        school: SchoolConfig? = .preview,
        apiClient: APIClient = MockAPIClient()
    ) -> AppSession {
        let session = AppSession(apiClient: apiClient)
        session.school = school
        session.phase = phase
        return session
    }
    #endif
}
