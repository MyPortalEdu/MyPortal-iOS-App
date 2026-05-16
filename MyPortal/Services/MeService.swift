import Foundation

/// Fetches the current user's profile + permissions from `/api/me`. Replaces
/// scattered `apiClient.get("api/me")` calls so AppSession has a typed handle.
protocol MeService: Sendable {
    func fetch() async throws -> UserInfo
}

nonisolated struct LiveMeService: MeService {
    let apiClient: APIClient
    func fetch() async throws -> UserInfo {
        try await apiClient.get("api/me")
    }
}

nonisolated struct MockMeService: MeService {
    var result: Result<UserInfo, APIError>

    init(_ user: UserInfo) { self.result = .success(user) }
    init(failing error: APIError) { self.result = .failure(error) }

    func fetch() async throws -> UserInfo {
        try result.get()
    }
}
