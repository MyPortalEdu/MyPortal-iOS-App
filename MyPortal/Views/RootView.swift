import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ProgressView()
                    .controlSize(.large)
            case .needsSchool:
                SchoolSetupView()
            case .needsLogin:
                LoginView()
            case .authenticated(let user):
                PortalRouter(user: user)
            }
        }
        .task { await session.bootstrap() }
    }
}

#if DEBUG
#Preview("Loading") {
    RootView()
        .environment(AppSession.preview(phase: .loading, school: nil))
}

#Preview("Needs school") {
    RootView()
        .environment(AppSession.preview(phase: .needsSchool, school: nil))
}

#Preview("Needs login") {
    RootView()
        .environment(AppSession.preview(phase: .needsLogin))
}

#Preview("Authenticated — Staff") {
    RootView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStaff),
            apiClient: MockAPIClient().stubbingGet(
                "api/v1/bulletins?page=1&pageSize=25",
                with: PageResult(items: BulletinSummary.previewSet, totalItems: BulletinSummary.previewSet.count)
            )
        ))
}

#Preview("Authenticated — Student") {
    RootView()
        .environment(AppSession.preview(phase: .authenticated(.previewStudent)))
}

#Preview("Authenticated — Parent") {
    RootView()
        .environment(AppSession.preview(phase: .authenticated(.previewParent)))
}
#endif
