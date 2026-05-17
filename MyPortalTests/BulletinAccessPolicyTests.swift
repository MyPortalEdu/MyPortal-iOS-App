import Foundation
import Testing
@testable import MyPortal

/// Pins the iOS-side mirror of the server's BulletinAccessPolicy in place.
/// A drift here means students/parents see staff-only actions, or staff get
/// silent 403s — both surface late in manual testing, so we lock it down.
@Suite("BulletinAccessPolicy")
struct BulletinAccessPolicyTests {

    // MARK: canPost

    @Test func canPost_requires_staff_with_edit_permission() {
        #expect(BulletinAccessPolicy.canPost(me: staff(.viewBulletins, .editBulletins)))
    }

    @Test func canPost_denies_staff_without_edit_permission() {
        #expect(!BulletinAccessPolicy.canPost(me: staff(.viewBulletins)))
    }

    @Test func canPost_denies_students_even_with_edit_permission() {
        // The "even with edit permission" case is the interesting one — the
        // server gates on userType too, and the iOS mirror has to as well.
        #expect(!BulletinAccessPolicy.canPost(me: student(.editBulletins)))
    }

    @Test func canPost_denies_parents() {
        #expect(!BulletinAccessPolicy.canPost(me: parent(.viewBulletins)))
    }

    @Test func canPost_denies_unauthenticated() {
        #expect(!BulletinAccessPolicy.canPost(me: nil))
    }

    // MARK: canPin

    @Test func canPin_requires_staff_with_pin_permission() {
        #expect(BulletinAccessPolicy.canPin(me: staff(.pinBulletins)))
        #expect(!BulletinAccessPolicy.canPin(me: staff(.editBulletins)))
        #expect(!BulletinAccessPolicy.canPin(me: student(.pinBulletins)))
    }

    // MARK: canEdit

    @Test func canEdit_pinner_can_edit_anyone() {
        let bulletin = details(createdById: UUID())
        #expect(BulletinAccessPolicy.canEdit(bulletin: bulletin, me: staff(.pinBulletins)))
    }

    @Test func canEdit_editor_can_edit_own_bulletin() {
        let author = UUID()
        let me = staff(.editBulletins, id: author)
        let bulletin = details(createdById: author)
        #expect(BulletinAccessPolicy.canEdit(bulletin: bulletin, me: me))
    }

    @Test func canEdit_editor_cannot_edit_others_bulletins() {
        let me = staff(.editBulletins, id: UUID())
        let bulletin = details(createdById: UUID())  // different author
        #expect(!BulletinAccessPolicy.canEdit(bulletin: bulletin, me: me))
    }

    @Test func canEdit_denies_non_staff_even_when_author() {
        let author = UUID()
        let me = student(.editBulletins, id: author)
        let bulletin = details(createdById: author)
        #expect(!BulletinAccessPolicy.canEdit(bulletin: bulletin, me: me))
    }

    // MARK: canDelete (mirrors canEdit per server policy)

    @Test func canDelete_mirrors_canEdit() {
        let author = UUID()
        let bulletin = details(createdById: author)
        let editor = staff(.editBulletins, id: author)
        #expect(BulletinAccessPolicy.canDelete(bulletin: bulletin, me: editor))
        let pinner = staff(.pinBulletins)
        #expect(BulletinAccessPolicy.canDelete(bulletin: bulletin, me: pinner))
        #expect(!BulletinAccessPolicy.canDelete(bulletin: bulletin, me: student(.editBulletins)))
    }

    // MARK: - Fixtures

    private func staff(_ perms: String..., id: UUID = UUID()) -> UserInfo {
        UserInfo(id: id, username: "s", email: nil, userType: .staff,
                 isEnabled: true, isSystem: false, displayName: "Staff", permissions: perms)
    }

    private func student(_ perms: String..., id: UUID = UUID()) -> UserInfo {
        UserInfo(id: id, username: "p", email: nil, userType: .student,
                 isEnabled: true, isSystem: false, displayName: "Student", permissions: perms)
    }

    private func parent(_ perms: String..., id: UUID = UUID()) -> UserInfo {
        UserInfo(id: id, username: "g", email: nil, userType: .parent,
                 isEnabled: true, isSystem: false, displayName: "Parent", permissions: perms)
    }

    private func details(createdById: UUID) -> BulletinDetails {
        BulletinDetails(
            id: UUID(),
            directoryId: UUID(),
            expiresAt: nil,
            pinnedAt: nil,
            title: "T",
            detail: "D",
            requiresAcknowledgement: false,
            categoryId: UUID(),
            categoryName: "General",
            categoryIcon: "",
            categoryColourCode: "#000",
            createdById: createdById,
            createdByName: "Author",
            createdAt: Date(),
            lastModifiedById: createdById,
            lastModifiedByName: "Author",
            lastModifiedAt: Date(),
            version: 1,
            audiences: [],
            hasAcknowledged: nil,
            acknowledgedCount: nil,
            attachmentCount: 0
        )
    }
}

/// Test-only shorthand for permission strings, so call sites read as
/// `staff(.editBulletins)` rather than `staff(Permissions.School.editSchoolBulletins)`.
private extension String {
    static let viewBulletins = Permissions.School.viewSchoolBulletins
    static let editBulletins = Permissions.School.editSchoolBulletins
    static let pinBulletins  = Permissions.School.pinSchoolBulletins
}
