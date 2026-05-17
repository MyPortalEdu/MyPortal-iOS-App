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

    /// Attachments live under `…/attachments/directories/{directoryId}/contents`
    /// keyed by the bulletin's `directoryId`. Returns documents only — we
    /// don't navigate nested directories on iOS.
    func attachments(bulletinId: UUID, directoryId: UUID) async throws -> [DocumentSummary]

    /// Returns the data for a single attachment. The caller can write it to
    /// a temp file and hand it to QLPreviewController / a share sheet.
    func downloadAttachment(bulletinId: UUID, documentId: UUID) async throws -> Data
}

extension BulletinsService {
    func categories() async throws -> [BulletinCategory] {
        try await categories(includeInactive: false)
    }
}
