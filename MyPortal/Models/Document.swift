import Foundation

/// Subset of `DocumentDetailsResponse` we render in the bulletin detail view.
/// Add fields here as the UI needs them — keep the model lean.
nonisolated struct DocumentSummary: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let fileName: String
    let contentType: String?
    let sizeBytes: Int64?
    let title: String?
}

/// Wrapper around the `GET …/contents` response. We only consume the
/// documents list for bulletin attachments — nested directories aren't part
/// of the iOS v1 UI.
nonisolated struct DirectoryContents: Codable, Sendable {
    let documents: [DocumentSummary]
}
