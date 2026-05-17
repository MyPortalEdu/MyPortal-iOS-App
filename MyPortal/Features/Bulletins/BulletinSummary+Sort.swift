import Foundation

nonisolated extension BulletinSummary {
    /// Canonical feed order: pinned first (newest pin first), then everything
    /// else newest-first. Shared by every portal's home screen so a user moving
    /// between web and mobile, or staff and student, sees the same order.
    static func feedOrder(_ items: [BulletinSummary]) -> [BulletinSummary] {
        items.sorted { lhs, rhs in
            switch (lhs.pinnedAt, rhs.pinnedAt) {
            case let (l?, r?): return l > r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil):
                return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
        }
    }
}
