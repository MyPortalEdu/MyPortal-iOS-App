import Foundation
import Testing
@testable import MyPortal

/// Locks in the bulletin feed order so it stays consistent across portals and
/// matches the SPA. Re-ordering a feed in subtle ways is the kind of bug
/// nobody files — it just feels wrong — so a unit test is the place to catch it.
@Suite("BulletinSummary.feedOrder")
struct BulletinFeedOrderTests {

    @Test func pinned_appear_before_unpinned_regardless_of_age() {
        let oldPinned = makeSummary(title: "old pinned",
                                    pinnedAt: ago(hours: 48),
                                    createdAt: ago(hours: 72))
        let recentUnpinned = makeSummary(title: "recent unpinned",
                                         pinnedAt: nil,
                                         createdAt: ago(minutes: 5))
        let sorted = BulletinSummary.feedOrder([recentUnpinned, oldPinned])
        #expect(sorted.map(\.title) == ["old pinned", "recent unpinned"])
    }

    @Test func multiple_pinned_sorted_by_pin_date_newest_first() {
        let pinnedYesterday = makeSummary(title: "yesterday", pinnedAt: ago(hours: 24))
        let pinnedJustNow   = makeSummary(title: "just now",  pinnedAt: ago(minutes: 1))
        let pinnedLastWeek  = makeSummary(title: "last week", pinnedAt: ago(hours: 24 * 7))
        let sorted = BulletinSummary.feedOrder([pinnedYesterday, pinnedLastWeek, pinnedJustNow])
        #expect(sorted.map(\.title) == ["just now", "yesterday", "last week"])
    }

    @Test func unpinned_sorted_by_created_date_newest_first() {
        let day = makeSummary(title: "day", pinnedAt: nil, createdAt: ago(hours: 24))
        let hour = makeSummary(title: "hour", pinnedAt: nil, createdAt: ago(hours: 1))
        let week = makeSummary(title: "week", pinnedAt: nil, createdAt: ago(hours: 24 * 7))
        let sorted = BulletinSummary.feedOrder([day, week, hour])
        #expect(sorted.map(\.title) == ["hour", "day", "week"])
    }

    @Test func unpinned_with_nil_createdAt_sorts_to_the_bottom() {
        // Defensive: the API shouldn't ever omit createdAt, but if it does,
        // the bulletin shouldn't elbow newer items out of the top.
        let undated = makeSummary(title: "undated", pinnedAt: nil, createdAt: nil)
        let recent  = makeSummary(title: "recent",  pinnedAt: nil, createdAt: ago(hours: 1))
        let sorted = BulletinSummary.feedOrder([undated, recent])
        #expect(sorted.map(\.title) == ["recent", "undated"])
    }

    @Test func empty_input_returns_empty() {
        #expect(BulletinSummary.feedOrder([]).isEmpty)
    }

    // MARK: - Fixtures

    private func makeSummary(title: String,
                             pinnedAt: Date?,
                             createdAt: Date? = ago(hours: 1)) -> BulletinSummary {
        BulletinSummary(
            id: UUID(),
            expiresAt: nil,
            pinnedAt: pinnedAt,
            title: title,
            detail: "",
            createdByName: "",
            createdAt: createdAt,
            categoryId: UUID(),
            categoryName: "",
            categoryIcon: "",
            categoryColourCode: "#000",
            requiresAcknowledgement: false,
            hasAcknowledged: nil,
            attachmentCount: 0
        )
    }
}

private func ago(hours: Int = 0, minutes: Int = 0) -> Date {
    Date().addingTimeInterval(-Double(hours * 3600 + minutes * 60))
}
