import SwiftUI

struct PortalRouter: View {
    let user: UserInfo

    var body: some View {
        switch user.userType {
        case .staff:   StaffPortalView()
        case .student: StudentPortalView()
        case .parent:  ParentPortalView()
        case .unknown: UnknownUserTypeView()
        }
    }
}

#if DEBUG
#Preview("Staff") {
    PortalRouter(user: .previewStaff)
        .environment(AppSession.preview(phase: .authenticated(.previewStaff)))
}

#Preview("Student") {
    PortalRouter(user: .previewStudent)
        .environment(AppSession.preview(phase: .authenticated(.previewStudent)))
}

#Preview("Parent") {
    PortalRouter(user: .previewParent)
        .environment(AppSession.preview(phase: .authenticated(.previewParent)))
}

#Preview("Unknown type") {
    PortalRouter(user: UserInfo(userId: "x", userType: .unknown))
        .environment(AppSession.preview(phase: .authenticated(UserInfo(userId: "x", userType: .unknown))))
}
#endif

private struct UnknownUserTypeView: View {
    @Environment(AppSession.self) private var session
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("This account isn't recognised as Staff, Student, or Parent.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Sign out") { session.signOut() }
                .buttonStyle(.bordered)
        }
    }
}
