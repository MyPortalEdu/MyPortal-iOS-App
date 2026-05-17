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
        case .allStaff:     return String(localized: "All staff")
        case .allPupils:    return String(localized: "All pupils")
        case .allParents:   return String(localized: "All parents")
        case .studentGroup: return String(localized: "Student group")
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

nonisolated extension BulletinSummary {
    /// Build a summary from a freshly-loaded `BulletinDetails`. Useful when a
    /// view holds onto a summary (the row tapped to navigate in) but wants to
    /// refresh its rendering once details land.
    init(from details: BulletinDetails) {
        self.init(
            id: details.id,
            expiresAt: details.expiresAt,
            pinnedAt: details.pinnedAt,
            title: details.title,
            detail: details.detail,
            createdByName: details.createdByName,
            createdAt: details.createdAt,
            categoryId: details.categoryId,
            categoryName: details.categoryName,
            categoryIcon: details.categoryIcon,
            categoryColourCode: details.categoryColourCode,
            requiresAcknowledgement: details.requiresAcknowledgement,
            hasAcknowledged: details.hasAcknowledged,
            attachmentCount: details.attachmentCount
        )
    }
}

// MARK: - Upsert request shapes

nonisolated struct BulletinAudienceRequest: Codable, Equatable, Sendable {
    let audienceKind: BulletinAudienceKind
    let studentGroupId: UUID?
}

nonisolated struct BulletinUpsertRequest: Codable, Sendable {
    let expiresAt: Date?
    let categoryId: UUID
    let title: String
    let detail: String
    let requiresAcknowledgement: Bool
    let isPinned: Bool
    let audiences: [BulletinAudienceRequest]
    let expectedVersion: Int
}

nonisolated struct IdResponse: Codable, Sendable {
    let id: UUID
}
