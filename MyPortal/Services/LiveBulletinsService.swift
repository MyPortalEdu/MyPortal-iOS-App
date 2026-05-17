import Foundation

nonisolated struct LiveBulletinsService: BulletinsService {
    let apiClient: APIClient

    func list(page: Int, pageSize: Int) async throws -> PageResult<BulletinSummary> {
        try await apiClient.get("api/bulletins?page=\(page)&pageSize=\(pageSize)")
    }

    func details(id: UUID) async throws -> BulletinDetails {
        try await apiClient.get("api/bulletins/\(id.uuidString.lowercased())")
    }

    func create(_ request: BulletinUpsertRequest) async throws -> UUID {
        let body = try Self.encoder.encode(request)
        let response: IdResponse = try await apiClient.post(
            "api/bulletins",
            body: body,
            contentType: "application/json"
        )
        return response.id
    }

    func update(id: UUID, _ request: BulletinUpsertRequest) async throws {
        let body = try Self.encoder.encode(request)
        let _: EmptyResponse = try await apiClient.put(
            "api/bulletins/\(id.uuidString.lowercased())",
            body: body,
            contentType: "application/json"
        )
    }

    func delete(id: UUID) async throws {
        let _: EmptyResponse = try await apiClient.delete(
            "api/bulletins/\(id.uuidString.lowercased())"
        )
    }

    func acknowledge(id: UUID) async throws {
        let _: EmptyResponse = try await apiClient.post(
            "api/bulletins/\(id.uuidString.lowercased())/acknowledge",
            body: nil,
            contentType: "application/json"
        )
    }

    func categories(includeInactive: Bool) async throws -> [BulletinCategory] {
        let path = includeInactive
            ? "api/bulletincategories?includeInactive=true"
            : "api/bulletincategories"
        return try await apiClient.get(path)
    }

    func attachments(bulletinId: UUID, directoryId: UUID) async throws -> [DocumentSummary] {
        let bid = bulletinId.uuidString.lowercased()
        let did = directoryId.uuidString.lowercased()
        let contents: DirectoryContents = try await apiClient.get(
            "api/bulletins/\(bid)/attachments/directories/\(did)/contents"
        )
        return contents.documents
    }

    func downloadAttachment(bulletinId: UUID, documentId: UUID) async throws -> Data {
        let bid = bulletinId.uuidString.lowercased()
        let did = documentId.uuidString.lowercased()
        return try await apiClient.get(
            "api/bulletins/\(bid)/attachments/documents/\(did)/download"
        )
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
