import Foundation

/// Domain service for the bulletins feature. Wraps the API in typed methods
/// so view models depend on bulletin operations, not URL strings.
///
/// Two implementations:
/// - `LiveBulletinsService` — hits the real API via `APIClient`.
/// - `MockBulletinsService` — in-memory canned responses for previews + tests.
protocol BulletinsService: Sendable {
    func list(page: Int, pageSize: Int) async throws -> PageResult<BulletinSummary>
    func details(id: UUID) async throws -> BulletinDetails
    func create(_ request: BulletinUpsertRequest) async throws -> UUID
    func update(id: UUID, _ request: BulletinUpsertRequest) async throws
    func delete(id: UUID) async throws
    func acknowledge(id: UUID) async throws
    func categories(includeInactive: Bool) async throws -> [BulletinCategory]
}

extension BulletinsService {
    func categories() async throws -> [BulletinCategory] {
        try await categories(includeInactive: false)
    }
}
