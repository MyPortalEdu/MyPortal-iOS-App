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

    /// Convenience: the authenticated user (or nil if not signed in). Views
    /// reach for this to gate permission-sensitive UI without unwrapping `phase`.
    var me: UserInfo? {
        if case .authenticated(let user) = phase { return user }
        return nil
    }

    // MARK: - Services
    //
    // Exposed so views/view-models depend on domain methods rather than URL
    // strings. Default to Live implementations layered over the APIClient;
    // previews can swap in mock services via `AppSession.preview(...)`.

    let apiClient: APIClient
    let bulletinsService: BulletinsService
    let meService: MeService
    let serverIdentityService: ServerIdentityService
    let timetableService: TimetableService

    init(
        apiClient: APIClient? = nil,
        bulletinsService: BulletinsService? = nil,
        meService: MeService? = nil,
        serverIdentityService: ServerIdentityService? = nil,
        timetableService: TimetableService? = nil
    ) {
        let client = apiClient ?? LiveAPIClient.shared
        self.apiClient = client
        self.bulletinsService = bulletinsService ?? LiveBulletinsService(apiClient: client)
        self.meService = meService ?? LiveMeService(apiClient: client)
        self.serverIdentityService = serverIdentityService ?? LiveServerIdentityService()
        self.timetableService = timetableService ?? LiveTimetableService(apiClient: client)
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
            phase = .authenticated(try await meService.fetch())
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
        phase = .authenticated(try await meService.fetch())
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
    /// SwiftUI previews. Override individual services to script their behaviour
    /// (e.g. `bulletinsService: MockBulletinsService().withSummaries(...)`).
    static func preview(
        phase: Phase = .needsLogin,
        school: SchoolConfig? = .preview,
        apiClient: APIClient = MockAPIClient(),
        bulletinsService: BulletinsService? = nil,
        meService: MeService? = nil,
        serverIdentityService: ServerIdentityService? = nil,
        timetableService: TimetableService? = nil
    ) -> AppSession {
        let session = AppSession(
            apiClient: apiClient,
            bulletinsService: bulletinsService,
            meService: meService,
            serverIdentityService: serverIdentityService,
            timetableService: timetableService
        )
        session.school = school
        session.phase = phase
        return session
    }
    #endif
}
