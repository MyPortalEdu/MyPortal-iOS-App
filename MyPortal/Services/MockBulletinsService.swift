import Foundation

/// Canned-data implementation for previews and tests. Build with a chained
/// `with`-style API so call sites read like configuration rather than setup.
nonisolated struct MockBulletinsService: BulletinsService {
    var summaries: [BulletinSummary] = []
    var detailsByID: [UUID: BulletinDetails] = [:]
    var categoryList: [BulletinCategory] = []
    var attachmentsByBulletin: [UUID: [DocumentSummary]] = [:]
    var documentBytes: [UUID: Data] = [:]
    /// If set, every method throws this instead of returning data — useful for
    /// previewing error states.
    var error: APIError?

    // MARK: - Builders (preview-friendly, immutable chaining)

    func withSummaries(_ items: [BulletinSummary]) -> Self {
        var copy = self; copy.summaries = items; return copy
    }

    func withDetails(_ details: BulletinDetails...) -> Self {
        var copy = self
        for d in details { copy.detailsByID[d.id] = d }
        return copy
    }

    func withCategories(_ items: [BulletinCategory]) -> Self {
        var copy = self; copy.categoryList = items; return copy
    }

    func withAttachments(_ items: [DocumentSummary], for bulletinId: UUID) -> Self {
        var copy = self; copy.attachmentsByBulletin[bulletinId] = items; return copy
    }

    func withDocumentBytes(_ data: Data, for documentId: UUID) -> Self {
        var copy = self; copy.documentBytes[documentId] = data; return copy
    }

    func failing(with error: APIError) -> Self {
        var copy = self; copy.error = error; return copy
    }

    // MARK: - BulletinsService

    func list(page: Int, pageSize: Int) async throws -> PageResult<BulletinSummary> {
        try check()
        return PageResult(items: summaries, totalItems: summaries.count)
    }

    func details(id: UUID) async throws -> BulletinDetails {
        try check()
        guard let result = detailsByID[id] else {
            throw APIError.http(status: 404, body: "MockBulletinsService: no details for \(id)")
        }
        return result
    }

    func create(_ request: BulletinUpsertRequest) async throws -> UUID {
        try check()
        return UUID()
    }

    func update(id: UUID, _ request: BulletinUpsertRequest) async throws { try check() }
    func delete(id: UUID) async throws { try check() }
    func acknowledge(id: UUID) async throws { try check() }

    func categories(includeInactive: Bool) async throws -> [BulletinCategory] {
        try check()
        return categoryList
    }

    func attachments(bulletinId: UUID, directoryId: UUID) async throws -> [DocumentSummary] {
        try check()
        return attachmentsByBulletin[bulletinId] ?? []
    }

    func downloadAttachment(bulletinId: UUID, documentId: UUID) async throws -> Data {
        try check()
        guard let data = documentBytes[documentId] else {
            throw APIError.http(status: 404, body: "MockBulletinsService: no bytes for \(documentId)")
        }
        return data
    }

    private func check() throws {
        if let error { throw error }
    }
}
