import SwiftUI

/// Reusable home-screen widget container. Provides a consistent title row,
/// background, padding, and corner radius across every card on the home
/// screen so individual features only have to provide their content.
struct HomeCard<Content: View, Trailing: View>: View {
    let title: String
    let systemImage: String?
    @ViewBuilder let content: () -> Content
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        systemImage: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.tint)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
                Spacer(minLength: 4)
                trailing()
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HomeCard(title: "Bulletins", systemImage: "bell.fill") {
                Text("Card content goes here.")
                    .foregroundStyle(.secondary)
            } trailing: {
                Text("3 new")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .foregroundStyle(.tint)
            }

            HomeCard(title: "Today's timetable", systemImage: "calendar") {
                Text("Period 1 · Maths · Room 12")
                    .font(.subheadline)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
#endif
