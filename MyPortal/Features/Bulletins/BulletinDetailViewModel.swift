import Foundation
import Observation

@MainActor
@Observable
final class BulletinDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    let bulletinId: UUID

    private(set) var state: LoadState = .idle
    private(set) var details: BulletinDetails?
    private(set) var acknowledgementInFlight = false
    private(set) var acknowledgementError: String?

    private let apiClient: APIClient

    init(bulletinId: UUID, apiClient: APIClient) {
        self.bulletinId = bulletinId
        self.apiClient = apiClient
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func reload() async { await load() }

    private func load() async {
        state = .loading
        do {
            let result: BulletinDetails = try await apiClient.get("api/bulletins/\(bulletinId.uuidString.lowercased())")
            details = result
            state = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .error(message)
        }
    }

    func acknowledge() async {
        guard let current = details, !acknowledgementInFlight else { return }
        acknowledgementInFlight = true
        acknowledgementError = nil
        defer { acknowledgementInFlight = false }
        do {
            let _: EmptyResponse = try await apiClient.post(
                "api/bulletins/\(current.id.uuidString.lowercased())/acknowledge",
                body: nil,
                contentType: "application/json",
                authenticated: true
            )
            details = current.withAcknowledged()
        } catch {
            acknowledgementError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private extension BulletinDetails {
    func withAcknowledged() -> BulletinDetails {
        BulletinDetails(
            id: id,
            directoryId: directoryId,
            expiresAt: expiresAt,
            pinnedAt: pinnedAt,
            title: title,
            detail: detail,
            requiresAcknowledgement: requiresAcknowledgement,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColourCode: categoryColourCode,
            createdById: createdById,
            createdByName: createdByName,
            createdAt: createdAt,
            lastModifiedById: lastModifiedById,
            lastModifiedByName: lastModifiedByName,
            lastModifiedAt: lastModifiedAt,
            version: version,
            audiences: audiences,
            hasAcknowledged: true,
            acknowledgedCount: (acknowledgedCount ?? 0) + 1,
            attachmentCount: attachmentCount
        )
    }
}
