import Foundation
import Observation

@MainActor
@Observable
final class BulletinsViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    private(set) var state: LoadState = .idle
    private(set) var bulletins: [BulletinSummary] = []

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func reload() async {
        await load()
    }

    private func load() async {
        state = .loading
        do {
            let page: PageResult<BulletinSummary> = try await apiClient.get(
                "api/bulletins?page=1&pageSize=25"
            )
            bulletins = Self.sort(page.items)
            state = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }

    /// Pinned first (newest pin first), then most recent. Mirrors the SPA order
    /// so a staff user moving between web and mobile sees the same feed.
    private static func sort(_ items: [BulletinSummary]) -> [BulletinSummary] {
        items.sorted { lhs, rhs in
            switch (lhs.pinnedAt, rhs.pinnedAt) {
            case let (l?, r?): return l > r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
        }
    }
}
