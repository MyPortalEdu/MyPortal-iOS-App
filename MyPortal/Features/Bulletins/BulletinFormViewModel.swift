import Foundation
import Observation

@MainActor
@Observable
final class BulletinFormViewModel {
    enum Mode: Equatable {
        case create
        case edit(id: UUID, version: Int)

        var isEdit: Bool { if case .edit = self { true } else { false } }
    }

    enum CategoryLoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    // Form fields
    var title: String = ""
    var detail: String = ""
    var selectedCategoryId: UUID?
    var requiresAcknowledgement: Bool = false
    var isPinned: Bool = false
    var expiresAt: Date?
    var selectedAudiences: Set<BulletinAudienceKind> = []

    // Sub-state
    private(set) var categories: [BulletinCategory] = []
    private(set) var categoryState: CategoryLoadState = .idle
    private(set) var saveInFlight = false
    private(set) var saveError: String?

    let mode: Mode
    private let service: BulletinsService

    init(mode: Mode, service: BulletinsService, prefill: BulletinDetails? = nil) {
        self.mode = mode
        self.service = service
        if let prefill {
            title = prefill.title
            detail = prefill.detail
            selectedCategoryId = prefill.categoryId
            requiresAcknowledgement = prefill.requiresAcknowledgement
            isPinned = prefill.isPinned
            expiresAt = prefill.expiresAt
            selectedAudiences = Set(
                prefill.audiences
                    .map(\.audienceKind)
                    .filter { $0 != .studentGroup }   // v1: only "All X" supported in the form
            )
        }
    }

    // MARK: - Categories

    func loadCategoriesIfNeeded() async {
        guard categoryState == .idle else { return }
        categoryState = .loading
        do {
            let result = try await service.categories()
            categories = result.sorted { $0.displayOrder < $1.displayOrder }
            categoryState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            categoryState = .error(message)
        }
    }

    // MARK: - Validation

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedDetail: String { detail.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canSubmit: Bool {
        !trimmedTitle.isEmpty
            && !trimmedDetail.isEmpty
            && selectedCategoryId != nil
            && !selectedAudiences.isEmpty
            && !saveInFlight
    }

    // MARK: - Submit

    /// Returns the bulletin id on success (the existing one for edit, the
    /// freshly-minted one for create) so callers can navigate / refresh.
    @discardableResult
    func submit() async -> UUID? {
        guard canSubmit, let categoryId = selectedCategoryId else { return nil }
        saveInFlight = true
        saveError = nil
        defer { saveInFlight = false }

        let request = BulletinUpsertRequest(
            expiresAt: expiresAt,
            categoryId: categoryId,
            title: trimmedTitle,
            detail: trimmedDetail,
            requiresAcknowledgement: requiresAcknowledgement,
            isPinned: isPinned,
            audiences: selectedAudiences.sorted(by: { $0.rawValue < $1.rawValue }).map {
                BulletinAudienceRequest(audienceKind: $0, studentGroupId: nil)
            },
            expectedVersion: {
                if case .edit(_, let version) = mode { return version }
                return 0
            }()
        )

        do {
            switch mode {
            case .create:
                return try await service.create(request)
            case .edit(let id, _):
                try await service.update(id: id, request)
                return id
            }
        } catch {
            saveError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }
}
