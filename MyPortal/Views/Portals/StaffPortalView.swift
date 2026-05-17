import SwiftUI

struct StaffPortalView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                StaffHomeView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

private struct StaffHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var bulletinsState: BulletinsLoadState = .idle
    @State private var bulletins: [BulletinSummary] = []
    @State private var showingForm = false

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
                    } trailing: {
                        if BulletinAccessPolicy.canPost(me: session.me) {
                            Button {
                                showingForm = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                            .accessibilityLabel("New bulletin")
                        }
                    }
                    // Future cards (timetable, attendance, etc.) slot in here
                    // — same HomeCard wrapper, content is the only variable.
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            // Force the ScrollView to always bounce so pull-to-refresh works
            // even when the content (e.g. just an error card) doesn't overflow
            // the viewport.
            .scrollBounceBehavior(.always)
            .navigationTitle(session.school?.name.isEmpty == false ? session.school!.name : "Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: BulletinSummary.self) { summary in
                BulletinDetailView(summary: summary) {
                    Task { await reloadBulletins() }
                }
            }
            .sheet(isPresented: $showingForm) {
                BulletinFormView(
                    mode: .create,
                    service: session.bulletinsService
                ) { _ in
                    Task { await reloadBulletins() }
                }
                .environment(session)
            }
            .onAppear {
                // `.task` ties the load to view lifetime — SwiftUI cancels it
                // if the view briefly unmounts (which can happen inside a
                // TabView), surfacing as URLError.cancelled. A self-managed
                // Task isn't tied to the view, so it runs to completion.
                guard bulletinsState == .idle else { return }
                Task { await reloadBulletins() }
            }
            .refreshable { await reloadBulletins() }
        }
    }

    private func reloadBulletins() async {
        bulletinsState = .loading
        do {
            let page = try await session.bulletinsService.list(page: 1, pageSize: 25)
            bulletins = Self.sort(page.items)
            bulletinsState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            bulletinsState = .error(message)
        }
    }

    /// Pinned first (newest pin first), then most recent. Mirrors the SPA order
    /// so a staff user moving between web and mobile sees the same feed.
    private static func sort(_ items: [BulletinSummary]) -> [BulletinSummary] {
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

#if DEBUG
private enum PreviewStubs {
    static let categories: [BulletinCategory] = [
        BulletinCategory(id: BulletinSummary.previewAnnouncement.categoryId,
                         name: "General",       icon: "fa-solid fa-bullhorn",
                         colourCode: "#0EA5E9", displayOrder: 1, active: true, isSystem: true, version: 1),
        BulletinCategory(id: BulletinSummary.previewUrgent.categoryId,
                         name: "Safeguarding",  icon: "fa-solid fa-triangle-exclamation",
                         colourCode: "#DC2626", displayOrder: 2, active: true, isSystem: true, version: 1),
        BulletinCategory(id: BulletinSummary.previewExpired.categoryId,
                         name: "Diary",         icon: "fa-solid fa-calendar-day",
                         colourCode: "#A855F7", displayOrder: 3, active: true, isSystem: true, version: 1),
        BulletinCategory(id: BulletinSummary.previewAcknowledged.categoryId,
                         name: "Curriculum",    icon: "fa-solid fa-book",
                         colourCode: "#16A34A", displayOrder: 4, active: true, isSystem: true, version: 1)
    ]

    static func service(items: [BulletinSummary]) -> MockBulletinsService {
        MockBulletinsService()
            .withSummaries(items)
            .withDetails(.previewUrgent, .previewAcknowledged, .previewExpired)
            .withCategories(categories)
    }
}

#Preview("Loaded") {
    StaffPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStaff),
            bulletinsService: PreviewStubs.service(items: BulletinSummary.previewSet)
        ))
}

#Preview("Empty") {
    StaffPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStaff),
            bulletinsService: PreviewStubs.service(items: [])
        ))
}
#endif
