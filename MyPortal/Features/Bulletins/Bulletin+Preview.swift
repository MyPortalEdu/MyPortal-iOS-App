#if DEBUG
import Foundation

nonisolated extension BulletinSummary {
    static let previewAnnouncement = BulletinSummary(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        expiresAt: nil,
        pinnedAt: nil,
        title: "Welcome back!",
        detail: "Term starts on Monday at 8:45am. Please ensure students arrive in full uniform with their planner and PE kit.",
        createdByName: "Mr Stevens",
        createdAt: Date().addingTimeInterval(-3600 * 4),
        categoryId: UUID(uuidString: "AAAAAAAA-1111-1111-1111-111111111111")!,
        categoryName: "General",
        categoryIcon: "fa-solid fa-bullhorn",
        categoryColourCode: "#0EA5E9",
        requiresAcknowledgement: false,
        hasAcknowledged: nil,
        attachmentCount: 0
    )

    static let previewUrgent = BulletinSummary(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        expiresAt: Date().addingTimeInterval(3600 * 24 * 7),
        pinnedAt: Date().addingTimeInterval(-3600 * 2),
        title: "Safeguarding training — sign-off required",
        detail: "All teaching staff must complete the updated safeguarding module before the end of the week. Acknowledge once you've finished.",
        createdByName: "Mrs Patel",
        createdAt: Date().addingTimeInterval(-3600 * 6),
        categoryId: UUID(uuidString: "BBBBBBBB-2222-2222-2222-222222222222")!,
        categoryName: "Safeguarding",
        categoryIcon: "fa-solid fa-triangle-exclamation",
        categoryColourCode: "#DC2626",
        requiresAcknowledgement: true,
        hasAcknowledged: false,
        attachmentCount: 2
    )

    static let previewExpired = BulletinSummary(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        expiresAt: Date().addingTimeInterval(-3600 * 24),
        pinnedAt: nil,
        title: "INSET day reminder",
        detail: "School closed to pupils on Friday for staff training. Onsite arrival 9am.",
        createdByName: "Admin Office",
        createdAt: Date().addingTimeInterval(-3600 * 24 * 5),
        categoryId: UUID(uuidString: "CCCCCCCC-3333-3333-3333-333333333333")!,
        categoryName: "Diary",
        categoryIcon: "fa-solid fa-calendar-day",
        categoryColourCode: "#A855F7",
        requiresAcknowledgement: false,
        hasAcknowledged: nil,
        attachmentCount: 0
    )

    static let previewAcknowledged = BulletinSummary(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        expiresAt: nil,
        pinnedAt: nil,
        title: "Updated marking policy",
        detail: "Please review the changes to formative marking and apply them from next half-term.",
        createdByName: "Mr Okafor",
        createdAt: Date().addingTimeInterval(-3600 * 36),
        categoryId: UUID(uuidString: "DDDDDDDD-4444-4444-4444-444444444444")!,
        categoryName: "Curriculum",
        categoryIcon: "fa-solid fa-book",
        categoryColourCode: "#16A34A",
        requiresAcknowledgement: true,
        hasAcknowledged: true,
        attachmentCount: 1
    )

    static let previewSet: [BulletinSummary] = [
        previewUrgent,
        previewAnnouncement,
        previewAcknowledged,
        previewExpired
    ]
}

nonisolated extension BulletinDetails {
    private static let demoStaffAudience = BulletinAudience(
        id: UUID(uuidString: "FFFFFFFF-1111-1111-1111-111111111111")!,
        audienceKind: .allStaff,
        studentGroupId: nil,
        studentGroupName: nil
    )
    private static let demoY11Audience = BulletinAudience(
        id: UUID(uuidString: "FFFFFFFF-2222-2222-2222-222222222222")!,
        audienceKind: .studentGroup,
        studentGroupId: UUID(uuidString: "EEEEEEEE-2222-2222-2222-222222222222")!,
        studentGroupName: "Year 11"
    )

    static let previewUrgent = BulletinDetails(
        id: BulletinSummary.previewUrgent.id,
        directoryId: UUID(uuidString: "DEADBEEF-2222-2222-2222-222222222222")!,
        expiresAt: BulletinSummary.previewUrgent.expiresAt,
        pinnedAt: BulletinSummary.previewUrgent.pinnedAt,
        title: BulletinSummary.previewUrgent.title,
        detail: """
        All teaching staff must complete the updated safeguarding module before the end of the week.

        The module covers the revised reporting flow introduced this term — please pay particular attention to the section on disclosures during off-site visits.

        Acknowledge below once you've finished so we can track completion.
        """,
        requiresAcknowledgement: true,
        categoryId: BulletinSummary.previewUrgent.categoryId,
        categoryName: BulletinSummary.previewUrgent.categoryName,
        categoryIcon: BulletinSummary.previewUrgent.categoryIcon,
        categoryColourCode: BulletinSummary.previewUrgent.categoryColourCode,
        createdById: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        createdByName: BulletinSummary.previewUrgent.createdByName,
        createdAt: BulletinSummary.previewUrgent.createdAt ?? Date(),
        lastModifiedById: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        lastModifiedByName: BulletinSummary.previewUrgent.createdByName,
        lastModifiedAt: Date().addingTimeInterval(-1800),
        version: 2,
        audiences: [demoStaffAudience],
        hasAcknowledged: false,
        acknowledgedCount: 17,
        attachmentCount: BulletinSummary.previewUrgent.attachmentCount
    )

    static let previewAcknowledged = BulletinDetails(
        id: BulletinSummary.previewAcknowledged.id,
        directoryId: UUID(uuidString: "DEADBEEF-4444-4444-4444-444444444444")!,
        expiresAt: nil,
        pinnedAt: nil,
        title: BulletinSummary.previewAcknowledged.title,
        detail: "Please review the changes to formative marking and apply them from next half-term. The updated rubric is attached and there's a short briefing video on the staff portal.",
        requiresAcknowledgement: true,
        categoryId: BulletinSummary.previewAcknowledged.categoryId,
        categoryName: BulletinSummary.previewAcknowledged.categoryName,
        categoryIcon: BulletinSummary.previewAcknowledged.categoryIcon,
        categoryColourCode: BulletinSummary.previewAcknowledged.categoryColourCode,
        createdById: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        createdByName: BulletinSummary.previewAcknowledged.createdByName,
        createdAt: BulletinSummary.previewAcknowledged.createdAt ?? Date(),
        lastModifiedById: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        lastModifiedByName: BulletinSummary.previewAcknowledged.createdByName,
        lastModifiedAt: Date().addingTimeInterval(-3600 * 30),
        version: 1,
        audiences: [demoStaffAudience, demoY11Audience],
        hasAcknowledged: true,
        acknowledgedCount: 42,
        attachmentCount: BulletinSummary.previewAcknowledged.attachmentCount
    )

    static let previewExpired = BulletinDetails(
        id: BulletinSummary.previewExpired.id,
        directoryId: UUID(uuidString: "DEADBEEF-3333-3333-3333-333333333333")!,
        expiresAt: BulletinSummary.previewExpired.expiresAt,
        pinnedAt: nil,
        title: BulletinSummary.previewExpired.title,
        detail: "School closed to pupils on Friday for staff training. Onsite arrival 9am.",
        requiresAcknowledgement: false,
        categoryId: BulletinSummary.previewExpired.categoryId,
        categoryName: BulletinSummary.previewExpired.categoryName,
        categoryIcon: BulletinSummary.previewExpired.categoryIcon,
        categoryColourCode: BulletinSummary.previewExpired.categoryColourCode,
        createdById: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
        createdByName: BulletinSummary.previewExpired.createdByName,
        createdAt: BulletinSummary.previewExpired.createdAt ?? Date(),
        lastModifiedById: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
        lastModifiedByName: BulletinSummary.previewExpired.createdByName,
        lastModifiedAt: BulletinSummary.previewExpired.createdAt ?? Date(),
        version: 1,
        audiences: [demoStaffAudience],
        hasAcknowledged: nil,
        acknowledgedCount: nil,
        attachmentCount: 0
    )
}
#endif
