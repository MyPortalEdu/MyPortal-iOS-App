import SwiftUI

struct PortalHomePlaceholder: View {
    @Environment(AppSession.self) private var session
    let title: String
    let subtitle: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("\(title) Portal")
                    .font(.largeTitle.bold())
                if let name = session.school?.name, !name.isEmpty {
                    Text(name)
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Home")
        }
    }
}

#if DEBUG
#Preview {
    PortalHomePlaceholder(title: "Staff", subtitle: "Your timetable, classes, and admin tools will appear here.")
        .environment(AppSession.preview(phase: .authenticated(.previewStaff)))
}
#endif
