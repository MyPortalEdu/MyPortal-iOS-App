import SwiftUI

struct BulletinDetailView: View {
    let summary: BulletinSummary
    @Environment(AppSession.self) private var session
    @State private var viewModel: BulletinDetailViewModel?

    private var categoryColor: Color { Color(hex: summary.categoryColourCode) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Divider()
                bodyText
                acknowledgeBlock
                audienceBlock
                attachmentsBlock
                auditFooter
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bulletin")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = BulletinDetailViewModel(bulletinId: summary.id, apiClient: session.apiClient)
            }
            await viewModel?.loadIfNeeded()
        }
        .refreshable { await viewModel?.reload() }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(categoryColor.opacity(0.15))
                    Image(systemName: FontAwesomeMapping.sfSymbol(for: summary.categoryIcon))
                        .foregroundStyle(categoryColor)
                        .font(.title3.weight(.semibold))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.categoryName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(categoryColor)
                    Text(summary.title)
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(.secondary)
                Text(summary.createdByName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let createdAt = summary.createdAt {
                    Text("·").foregroundStyle(.secondary)
                    Text(RelativeTime.string(for: createdAt))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if summary.isPinned {
                    Label("Pinned", systemImage: "bookmark.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.tint)
                }
            }

            if summary.isExpired {
                Label("This bulletin has expired", systemImage: "clock")
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.tertiarySystemFill)))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var bodyText: some View {
        Text((viewModel?.details?.detail) ?? summary.detail)
            .font(.body)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var acknowledgeBlock: some View {
        if summary.requiresAcknowledgement {
            let details = viewModel?.details
            let acknowledged = details?.hasAcknowledged ?? summary.hasAcknowledged ?? false
            let count = details?.acknowledgedCount

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: acknowledged ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(acknowledged ? .green : .orange)
                    Text(acknowledged ? "You've acknowledged this bulletin." : "Please confirm you've read this bulletin.")
                        .font(.subheadline)
                }

                if let count {
                    Text("\(count) staff acknowledged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !acknowledged {
                    Button {
                        Task { await viewModel?.acknowledge() }
                    } label: {
                        HStack {
                            if viewModel?.acknowledgementInFlight == true {
                                ProgressView().tint(.white)
                            }
                            Text("Acknowledge")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel?.acknowledgementInFlight == true)
                }

                if let error = viewModel?.acknowledgementError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    @ViewBuilder
    private var audienceBlock: some View {
        if let details = viewModel?.details, !details.audiences.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Audience")
                    .font(.headline)
                FlowLayout(spacing: 8) {
                    ForEach(details.audiences) { audience in
                        Text(audience.displayName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                            .foregroundStyle(.primary)
                    }
                }
            }
        } else if viewModel?.state == .loading {
            VStack(alignment: .leading, spacing: 8) {
                Text("Audience")
                    .font(.headline)
                HStack(spacing: 8) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(width: 80, height: 24)
                    Capsule().fill(Color(.tertiarySystemFill)).frame(width: 110, height: 24)
                }
                .redacted(reason: .placeholder)
            }
        }
    }

    @ViewBuilder
    private var attachmentsBlock: some View {
        if summary.attachmentCount > 0 {
            HStack {
                Image(systemName: "paperclip")
                Text("\(summary.attachmentCount) attachment\(summary.attachmentCount == 1 ? "" : "s")")
                Spacer()
                Text("Coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    @ViewBuilder
    private var auditFooter: some View {
        if let details = viewModel?.details {
            VStack(alignment: .leading, spacing: 2) {
                Text("Last updated \(RelativeTime.string(for: details.lastModifiedAt)) by \(details.lastModifiedByName)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }
}

/// Wrap-around horizontal stack used for the audience chip row. SwiftUI's
/// built-in `HStack` would just push everything onto one line and clip.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRow: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRow + size.width > maxWidth, currentRow > 0 {
                totalHeight += rowHeight + spacing
                currentRow = 0
                rowHeight = 0
            }
            currentRow += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#if DEBUG
#Preview("Pinned + ack required") {
    NavigationStack {
        BulletinDetailView(summary: .previewUrgent)
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        apiClient: MockAPIClient()
            .stubbingGet("api/bulletins/\(BulletinSummary.previewUrgent.id.uuidString.lowercased())", with: BulletinDetails.previewUrgent)
            .stubbingPost("api/bulletins/\(BulletinSummary.previewUrgent.id.uuidString.lowercased())/acknowledge", with: EmptyResponseStub())
    ))
}

#Preview("Already acknowledged") {
    NavigationStack {
        BulletinDetailView(summary: .previewAcknowledged)
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        apiClient: MockAPIClient()
            .stubbingGet("api/bulletins/\(BulletinSummary.previewAcknowledged.id.uuidString.lowercased())", with: BulletinDetails.previewAcknowledged)
    ))
}

#Preview("Expired") {
    NavigationStack {
        BulletinDetailView(summary: .previewExpired)
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        apiClient: MockAPIClient()
            .stubbingGet("api/bulletins/\(BulletinSummary.previewExpired.id.uuidString.lowercased())", with: BulletinDetails.previewExpired)
    ))
}

/// EmptyResponse can't be auto-encoded — it has no stored properties and is
/// only used as a "I don't care about the body" marker. Encode any small JSON
/// object as a stand-in for stubbing 204-style endpoints.
private struct EmptyResponseStub: Encodable {}
#endif
