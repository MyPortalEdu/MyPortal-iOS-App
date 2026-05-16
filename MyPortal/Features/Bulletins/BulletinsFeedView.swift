import SwiftUI

/// Bulletins list. Designed to live inside a `HomeCard` — no outer ScrollView,
/// no own background. The parent owns vertical scrolling.
struct BulletinsFeedView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: BulletinsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = BulletinsViewModel(apiClient: session.apiClient)
            }
            await viewModel?.loadIfNeeded()
        }
    }

    @ViewBuilder
    private func content(viewModel: BulletinsViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingSkeleton
        case .loaded:
            if viewModel.bulletins.isEmpty {
                emptyState
            } else {
                list(items: viewModel.bulletins)
            }
        case .error(let message):
            errorState(message: message) {
                Task { await viewModel.reload() }
            }
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 10).frame(maxWidth: 120, alignment: .leading)
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 14).frame(maxWidth: 220, alignment: .leading)
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill)).frame(height: 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading bulletins")
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
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
        .padding(.vertical, 8)
    }

    private func list(items: [BulletinSummary]) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(items) { bulletin in
                NavigationLink(value: bulletin) {
                    BulletinRow(bulletin: bulletin)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func errorState(message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Couldn't load bulletins")
                    .font(.subheadline.weight(.medium))
            }
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#if DEBUG
#Preview("Loaded") {
    NavigationStack {
        ScrollView {
            HomeCard(title: "Bulletins", systemImage: "bell.fill") {
                BulletinsFeedView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: BulletinSummary.self) { summary in
            BulletinDetailView(summary: summary)
        }
    }
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
    NavigationStack {
        ScrollView {
            HomeCard(title: "Bulletins", systemImage: "bell.fill") {
                BulletinsFeedView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        apiClient: MockAPIClient().stubbingGet(
            "api/bulletins?page=1&pageSize=25",
            with: PageResult<BulletinSummary>(items: [], totalItems: 0)
        )
    ))
}

#Preview("Error") {
    NavigationStack {
        ScrollView {
            HomeCard(title: "Bulletins", systemImage: "bell.fill") {
                BulletinsFeedView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        apiClient: MockAPIClient()
    ))
}
#endif
