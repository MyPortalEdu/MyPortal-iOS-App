import SwiftUI

struct ParentPortalView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                ParentHomeView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

private struct ParentHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var bulletinsState: BulletinsLoadState = .idle
    @State private var bulletins: [BulletinSummary] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.l) {
                    HomeCard(title: "Bulletins", systemImage: "bell.fill") {
                        BulletinsFeedView(
                            state: bulletinsState,
                            bulletins: bulletins,
                            onRetry: { Task { await reloadBulletins() } }
                        )
                    }
                    // Future: children summary card. The wire format / endpoint
                    // doesn't exist yet, so we hold off rather than build UI
                    // against a contract that hasn't been agreed.
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .scrollBounceBehavior(.always)
            .navigationTitle(session.school?.name.isEmpty == false ? session.school!.name : "Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: BulletinSummary.self) { summary in
                BulletinDetailView(summary: summary) {
                    Task { await reloadBulletins() }
                }
            }
            .onAppear {
                if bulletinsState == .idle { Task { await reloadBulletins() } }
            }
            .refreshable { await reloadBulletins() }
        }
    }

    private func reloadBulletins() async {
        bulletinsState = .loading
        do {
            let page = try await session.bulletinsService.list(page: 1, pageSize: 25)
            bulletins = BulletinSummary.feedOrder(page.items)
            bulletinsState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            bulletinsState = .error(message)
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    ParentPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewParent),
            bulletinsService: MockBulletinsService()
                .withSummaries(BulletinSummary.previewSet)
                .withDetails(.previewUrgent, .previewAcknowledged, .previewExpired)
        ))
}

#Preview("Empty") {
    ParentPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewParent),
            bulletinsService: MockBulletinsService()
        ))
}
#endif
