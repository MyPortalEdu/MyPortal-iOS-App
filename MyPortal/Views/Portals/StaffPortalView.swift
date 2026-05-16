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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    HomeCard(title: "Bulletins", systemImage: "bell.fill") {
                        BulletinsFeedView()
                    }
                    // Future cards (timetable, attendance, etc.) slot in here
                    // — same HomeCard wrapper, content is the only variable.
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(session.school?.name.isEmpty == false ? session.school!.name : "Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: BulletinSummary.self) { summary in
                BulletinDetailView(summary: summary)
            }
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    StaffPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStaff),
            apiClient: MockAPIClient()
                .stubbingGet("api/bulletins?page=1&pageSize=25", with: PageResult(items: BulletinSummary.previewSet, totalItems: BulletinSummary.previewSet.count))
                .stubbingGet("api/bulletins/\(BulletinSummary.previewUrgent.id.uuidString.lowercased())", with: BulletinDetails.previewUrgent)
                .stubbingGet("api/bulletins/\(BulletinSummary.previewAcknowledged.id.uuidString.lowercased())", with: BulletinDetails.previewAcknowledged)
                .stubbingGet("api/bulletins/\(BulletinSummary.previewExpired.id.uuidString.lowercased())", with: BulletinDetails.previewExpired)
        ))
}

#Preview("Empty") {
    StaffPortalView()
        .environment(AppSession.preview(
            phase: .authenticated(.previewStaff),
            apiClient: MockAPIClient().stubbingGet(
                "api/bulletins?page=1&pageSize=25",
                with: PageResult<BulletinSummary>(items: [], totalItems: 0)
            )
        ))
}
#endif
