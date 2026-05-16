import SwiftUI

struct StudentPortalView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                PortalHomePlaceholder(title: "Student", subtitle: "Your timetable, homework, and grades will appear here.")
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#if DEBUG
#Preview {
    StudentPortalView()
        .environment(AppSession.preview(phase: .authenticated(.previewStudent)))
}
#endif
