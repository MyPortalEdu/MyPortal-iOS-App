import Foundation

/// Permission string constants mirroring `MyPortal.Auth.Constants.Permissions`
/// on the server. Add new entries here as we use them in the iOS app — there's
/// no automated sync, so the discipline is "match the string exactly."
nonisolated enum Permissions {
    enum School {
        static let viewSchoolBulletins = "School.ViewSchoolBulletins"
        static let editSchoolBulletins = "School.EditSchoolBulletins"
        static let pinSchoolBulletins  = "School.PinSchoolBulletins"
    }
}
