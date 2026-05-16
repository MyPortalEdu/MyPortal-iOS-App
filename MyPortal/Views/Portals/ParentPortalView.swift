import SwiftUI

struct ParentPortalView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                PortalHomePlaceholder(title: "Parent", subtitle: "Your children's progress, attendance, and announcements will appear here.")
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#if DEBUG
#Preview {
    ParentPortalView()
        .environment(AppSession.preview(phase: .authenticated(.previewParent)))
}
#endif
