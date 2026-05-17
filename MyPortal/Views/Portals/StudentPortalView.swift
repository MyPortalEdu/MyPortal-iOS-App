import SwiftUI

struct StudentPortalView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                StudentHomeView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

private struct StudentHomeView: View {
    @Environment(AppSession.self) private var session
    @State private var bulletinsState: BulletinsLoadState = .idle
    @State private var bulletins: [BulletinSummary] = []
    @State private var timetableState: TimetableLoadState = .idle
    @State private var timetable: [TimetableEntry] = []

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
                    }
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
            bulletins = Self.sort(page.items)
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
#Preview("Loaded") {
    StudentPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStudent),
            bulletinsService: MockBulletinsService()
                .withSummaries(BulletinSummary.previewSet)
                .withDetails(.previewUrgent, .previewAcknowledged, .previewExpired),
            timetableService: MockTimetableService().withEntries(TimetableEntry.previewToday)
        ))
}

#Preview("Empty") {
    StudentPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStudent),
            bulletinsService: MockBulletinsService(),
            timetableService: MockTimetableService()
        ))
}
#endif
