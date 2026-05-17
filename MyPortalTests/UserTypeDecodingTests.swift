import Foundation
import Testing
@testable import MyPortal

/// `UserType` has a custom decoder because two different server endpoints
/// serialise it two different ways (`/connect/userinfo` uses the enum name,
/// `/api/me` uses the int value). A regression here puts every authenticated
/// user into `.unknown` and we silently lose role-based routing.
@Suite("UserType decoding")
struct UserTypeDecodingTests {

    @Test func decodes_string_form_from_userinfo_endpoint() throws {
        #expect(try decode("\"Staff\"") == .staff)
        #expect(try decode("\"Student\"") == .student)
        #expect(try decode("\"Parent\"") == .parent)
    }

    @Test func decodes_int_form_from_api_me_endpoint() throws {
        #expect(try decode("1") == .staff)
        #expect(try decode("2") == .student)
        #expect(try decode("3") == .parent)
    }

    @Test func unknown_string_falls_back_to_unknown() throws {
        #expect(try decode("\"NotARole\"") == .unknown)
    }

    @Test func unknown_int_falls_back_to_unknown() throws {
        #expect(try decode("99") == .unknown)
    }

    @Test func non_string_non_int_falls_back_to_unknown() throws {
        // Decoding a bool isn't realistic from this API, but the decoder
        // shouldn't throw — UI gating treats `.unknown` as "no portal".
        #expect(try decode("true") == .unknown)
    }

    private func decode(_ json: String) throws -> UserType {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(UserType.self, from: data)
    }
}
