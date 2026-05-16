import Foundation

/// Client-side mirror of `BulletinAccessPolicy` on the server. The server is
/// still the authority; this just keeps non-editors from seeing actions that
/// would 403, so the UI feels right rather than punishing.
nonisolated enum BulletinAccessPolicy {
    /// Create a new bulletin. Staff with `EditSchoolBulletins` — what gates the
    /// "+ New" button on Staff Home.
    static func canPost(me: UserInfo?) -> Bool {
        guard let me, me.userType == .staff else { return false }
        return me.hasPermission(Permissions.School.editSchoolBulletins)
    }

    /// Pin/unpin a bulletin (covers both the upsert-form pin toggle and the
    /// standalone pin action, if/when we add it).
    static func canPin(me: UserInfo?) -> Bool {
        guard let me, me.userType == .staff else { return false }
        return me.hasPermission(Permissions.School.pinSchoolBulletins)
    }

    /// Edit an existing bulletin. Mirrors the server policy: staff only;
    /// pinners can edit anyone's bulletin, otherwise the caller needs
    /// `EditSchoolBulletins` and must be the author.
    static func canEdit(bulletin: BulletinDetails, me: UserInfo?) -> Bool {
        guard let me, me.userType == .staff else { return false }
        if me.hasPermission(Permissions.School.pinSchoolBulletins) { return true }
        return me.hasPermission(Permissions.School.editSchoolBulletins)
            && bulletin.createdById == me.id
    }

    /// Delete an existing bulletin. Same gate as edit per server policy.
    static func canDelete(bulletin: BulletinDetails, me: UserInfo?) -> Bool {
        canEdit(bulletin: bulletin, me: me)
    }
}
