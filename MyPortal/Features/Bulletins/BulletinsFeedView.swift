import SwiftUI

/// State of the bulletins fetch. Lives at the top level of this file so the
/// host view (`StaffHomeView`) and this presentational view share one type.
enum BulletinsLoadState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// Bulletins list — presentational only. Owned state (load state, items,
/// reload action) lives in the host view; this view just renders whatever
/// it's given. Designed to live inside a `HomeCard`.
struct BulletinsFeedView: View {
    let state: BulletinsLoadState
    let bulletins: [BulletinSummary]
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            loadingSkeleton
        case .loaded:
            if bulletins.isEmpty {
                emptyState
            } else {
                list
            }
        case .error(let message):
            errorState(message: message)
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: Spacing.s) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(alignment: .top, spacing: Spacing.m) {
                    RoundedRectangle(cornerRadius: CornerRadius.s, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 10).frame(maxWidth: 120, alignment: .leading)
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 14).frame(maxWidth: 220, alignment: .leading)
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 12)
                    }
                }
                .padding(.vertical, Spacing.s)
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading bulletins")
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "bell.slash")
                .foregroundStyle(.secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("No bulletins")
                    .font(.subheadline.weight(.medium))
                Text("New school bulletins will appear here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.s)
    }

    private var list: some View {
        LazyVStack(spacing: Spacing.s) {
            ForEach(bulletins) { bulletin in
                NavigationLink(value: bulletin) {
                    BulletinRow(bulletin: bulletin)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Couldn't load bulletins")
                    .font(.subheadline.weight(.medium))
            }
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again", action: onRetry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
    }
}

#if DEBUG
#Preview("Loaded") {
    BulletinsFeedView(
        state: .loaded,
        bulletins: BulletinSummary.previewSet,
        onRetry: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    BulletinsFeedView(state: .loaded, bulletins: [], onRetry: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Loading") {
    BulletinsFeedView(state: .loading, bulletins: [], onRetry: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Error") {
    BulletinsFeedView(
        state: .error("The server returned a 500."),
        bulletins: [],
        onRetry: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
