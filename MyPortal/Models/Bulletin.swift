import Foundation

nonisolated struct BulletinSummary: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let expiresAt: Date?
    let pinnedAt: Date?
    let title: String
    let detail: String
    let createdByName: String
    let createdAt: Date?
    let categoryId: UUID
    let categoryName: String
    let categoryIcon: String
    let categoryColourCode: String
    let requiresAcknowledgement: Bool
    let hasAcknowledged: Bool?
    let attachmentCount: Int
}

extension BulletinSummary {
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var isPinned: Bool { pinnedAt != nil }
}

nonisolated struct BulletinCategory: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let icon: String
    let colourCode: String
    let displayOrder: Int
    let active: Bool
    let isSystem: Bool
    let version: Int
}

nonisolated enum BulletinAudienceKind: Int, Codable, Sendable {
    case allStaff = 1
    case allPupils = 2
    case allParents = 3
    case studentGroup = 4

    var displayName: String {
        switch self {
        case .allStaff:     return "All staff"
        case .allPupils:    return "All pupils"
        case .allParents:   return "All parents"
        case .studentGroup: return "Student group"
        }
    }
}

nonisolated struct BulletinAudience: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let audienceKind: BulletinAudienceKind
    let studentGroupId: UUID?
    let studentGroupName: String?

    var displayName: String {
        if audienceKind == .studentGroup, let groupName = studentGroupName {
            return groupName
        }
        return audienceKind.displayName
    }
}

nonisolated struct BulletinDetails: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let directoryId: UUID
    let expiresAt: Date?
    let pinnedAt: Date?
    let title: String
    let detail: String
    let requiresAcknowledgement: Bool
    let categoryId: UUID
    let categoryName: String
    let categoryIcon: String
    let categoryColourCode: String
    let createdById: UUID
    let createdByName: String
    let createdAt: Date
    let lastModifiedById: UUID
    let lastModifiedByName: String
    let lastModifiedAt: Date
    let version: Int
    let audiences: [BulletinAudience]
    let hasAcknowledged: Bool?
    let acknowledgedCount: Int?
    let attachmentCount: Int
}

extension BulletinDetails {
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var isPinned: Bool { pinnedAt != nil }
}
