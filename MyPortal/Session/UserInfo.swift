import Foundation

nonisolated enum UserType: String, Codable, Sendable {
    case staff = "Staff"
    case student = "Student"
    case parent = "Parent"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // `/connect/userinfo` returns the enum name ("Staff"), but `/api/me`
        // returns the int value (1/2/3) by default ASP.NET enum serialization.
        // Accept both so we don't depend on the backend serializer config.
        if let raw = try? container.decode(String.self) {
            self = UserType(rawValue: raw) ?? .unknown
            return
        }
        if let int = try? container.decode(Int.self) {
            switch int {
            case 1: self = .staff
            case 2: self = .student
            case 3: self = .parent
            default: self = .unknown
            }
            return
        }
        self = .unknown
    }
}

/// Mirrors `UserInfoResponse` on the server (the `/api/me` payload).
/// Carries everything the iOS app needs to render the right portal and gate
/// permission-sensitive UI without round-tripping the server.
nonisolated struct UserInfo: Codable, Equatable, Sendable {
    let id: UUID
    let username: String?
    let email: String?
    let userType: UserType
    let isEnabled: Bool
    let isSystem: Bool
    let displayName: String
    let permissions: [String]

    func hasPermission(_ key: String) -> Bool {
        permissions.contains(key)
    }
}

#if DEBUG
nonisolated extension UserInfo {
    /// Staff member with full bulletin permissions — the "happy path" preview.
    static let previewStaff = UserInfo(
        id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
        username: "demo.staff",
        email: "staff@demo.school",
        userType: .staff,
        isEnabled: true,
        isSystem: false,
        displayName: "Demo Staff",
        permissions: [
            Permissions.School.viewSchoolBulletins,
            Permissions.School.editSchoolBulletins,
            Permissions.School.pinSchoolBulletins
        ]
    )

    /// Staff member who can view but not edit. Use to preview the read-only
    /// shape of the staff portal (no Edit/Delete menu, no pin toggle).
    static let previewStaffViewer = UserInfo(
        id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
        username: "viewer.staff",
        email: "viewer@demo.school",
        userType: .staff,
        isEnabled: true,
        isSystem: false,
        displayName: "Read-Only Staff",
        permissions: [Permissions.School.viewSchoolBulletins]
    )

    static let previewStudent = UserInfo(
        id: UUID(uuidString: "00000002-0000-0000-0000-000000000001")!,
        username: "demo.student",
        email: nil,
        userType: .student,
        isEnabled: true,
        isSystem: false,
        displayName: "Demo Student",
        permissions: [Permissions.School.viewSchoolBulletins]
    )

    static let previewParent = UserInfo(
        id: UUID(uuidString: "00000003-0000-0000-0000-000000000001")!,
        username: "demo.parent",
        email: nil,
        userType: .parent,
        isEnabled: true,
        isSystem: false,
        displayName: "Demo Parent",
        permissions: [Permissions.School.viewSchoolBulletins]
    )
}
#endif
