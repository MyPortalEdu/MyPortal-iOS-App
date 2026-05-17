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
    @State private var timetableState: TimetableLoadState = .idle
    @State private var timetable: [TimetableEntry] = []
    @State private var showingForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.l) {
                    HomeCard(title: "Today", systemImage: "calendar") {
                        TimetableFeedView(
                            state: timetableState,
                            entries: timetable,
                            onRetry: { Task { await reloadTimetable() } }
                        )
                    }
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
                if bulletinsState == .idle { Task { await reloadBulletins() } }
                if timetableState == .idle { Task { await reloadTimetable() } }
            }
            .refreshable {
                async let b: Void = reloadBulletins()
                async let t: Void = reloadTimetable()
                _ = await (b, t)
            }
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

    private func reloadTimetable() async {
        timetableState = .loading
        do {
            let entries = try await session.timetableService.sessions(on: Date())
            timetable = entries.sorted { $0.startTime < $1.startTime }
            timetableState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            timetableState = .error(message)
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
            bulletinsService: PreviewStubs.service(items: BulletinSummary.previewSet),
            timetableService: MockTimetableService().withEntries(TimetableEntry.previewToday)
        ))
}

#Preview("Empty") {
    StaffPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStaff),
            bulletinsService: PreviewStubs.service(items: []),
            timetableService: MockTimetableService()
        ))
}
#endif
