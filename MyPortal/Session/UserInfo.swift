import Foundation

nonisolated enum UserType: String, Codable, Sendable {
    case staff = "Staff"
    case student = "Student"
    case parent = "Parent"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = UserType(rawValue: raw) ?? .unknown
    }
}

nonisolated struct UserInfo: Codable, Equatable, Sendable {
    let userId: String
    let userType: UserType

    private enum CodingKeys: String, CodingKey {
        case userId
        case userType
    }
}

#if DEBUG
nonisolated extension UserInfo {
    static let previewStaff   = UserInfo(userId: "demo-staff",   userType: .staff)
    static let previewStudent = UserInfo(userId: "demo-student", userType: .student)
    static let previewParent  = UserInfo(userId: "demo-parent",  userType: .parent)
}
#endif
