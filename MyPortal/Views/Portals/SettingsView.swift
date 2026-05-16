import SwiftUI

struct SettingsView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        NavigationStack {
            Form {
                if let school = session.school {
                    Section("School") {
                        LabeledContent("Name", value: school.name.isEmpty ? "—" : school.name)
                        LabeledContent("URL", value: school.baseURL.absoluteString)
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) { session.signOut() }
                    Button("Switch school", role: .destructive) { session.forgetSchool() }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#if DEBUG
#Preview {
    SettingsView()
        .environment(AppSession.preview(phase: .authenticated(.previewStaff)))
}
#endif
