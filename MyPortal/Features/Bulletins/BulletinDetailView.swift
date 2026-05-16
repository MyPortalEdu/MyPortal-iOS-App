import SwiftUI

struct BulletinDetailView: View {
    let summary: BulletinSummary
    /// Called whenever the bulletin's state changes (acknowledge / edit / delete)
    /// so the parent feed can refetch.
    let onChanged: () -> Void

    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    // Detail screen state lives directly on the view per Apple's MV pattern:
    // ephemeral UI state belongs to the view that owns the screen, not a
    // separate "ViewModel" type.
    @State private var details: BulletinDetails?
    @State private var loadState: LoadState = .idle
    @State private var ackInFlight = false
    @State private var ackError: String?
    @State private var deleteInFlight = false
    @State private var deleteError: String?
    @State private var showingEditForm = false
    @State private var showingDeleteConfirm = false

    enum LoadState: Equatable {
        case idle, loading, loaded
        case error(String)
    }

    init(summary: BulletinSummary, onChanged: @escaping () -> Void = {}) {
        self.summary = summary
        self.onChanged = onChanged
    }

    private var categoryColor: Color { Color(hex: summary.categoryColourCode) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                Divider()
                bodyText
                acknowledgeBlock
                audienceBlock
                attachmentsBlock
                deleteErrorBanner
                auditFooter
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bulletin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await loadIfNeeded() }
        .refreshable { await load() }
        .sheet(isPresented: $showingEditForm) {
            if let details {
                BulletinFormView(
                    mode: .edit(id: details.id, version: details.version),
                    service: session.bulletinsService,
                    prefill: details
                ) { _ in
                    Task {
                        await load()
                        onChanged()
                    }
                }
                .environment(session)
            }
        }
        .alert("Delete bulletin?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await performDelete() {
                        onChanged()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this bulletin?")
        }
    }

    // MARK: - Actions

    private func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await load()
    }

    private func load() async {
        loadState = .loading
        do {
            details = try await session.bulletinsService.details(id: summary.id)
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loadState = .error(message)
        }
    }

    private func acknowledge() async {
        guard let current = details, !ackInFlight else { return }
        ackInFlight = true
        ackError = nil
        defer { ackInFlight = false }
        do {
            try await session.bulletinsService.acknowledge(id: current.id)
            details = current.withAcknowledged()
        } catch {
            ackError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func performDelete() async -> Bool {
        guard !deleteInFlight else { return false }
        deleteInFlight = true
        deleteError = nil
        defer { deleteInFlight = false }
        do {
            try await session.bulletinsService.delete(id: summary.id)
            return true
        } catch {
            deleteError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    // MARK: - Toolbar / banners

    /// True once details have loaded AND the current user is allowed to edit
    /// or delete this bulletin. We don't show the menu before details land
    /// because the policy needs `createdById` to evaluate ownership.
    private var canEdit: Bool {
        guard let details else { return false }
        return BulletinAccessPolicy.canEdit(bulletin: details, me: session.me)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if canEdit {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditForm = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(deleteInFlight)
            }
        }
    }

    @ViewBuilder
    private var deleteErrorBanner: some View {
        if let deleteError {
            HStack(alignment: .top, spacing: Spacing.s) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                Text(deleteError).font(.footnote)
            }
            .padding(Spacing.m)
            .cardSurface(cornerRadius: CornerRadius.m, background: Color.orange.opacity(0.12))
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(spacing: Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.m, style: .continuous)
                        .fill(categoryColor.opacity(0.15))
                    Image(systemName: FontAwesomeMapping.sfSymbol(for: summary.categoryIcon))
                        .foregroundStyle(categoryColor)
                        .font(.title3.weight(.semibold))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(summary.categoryName.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(categoryColor)
                    Text(summary.title)
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: Spacing.s) {
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
                Spacer(minLength: Spacing.xs)
                if summary.isPinned {
                    Label("Pinned", systemImage: "bookmark.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.tint)
                }
            }

            if summary.isExpired {
                Label("This bulletin has expired", systemImage: "clock")
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.xs)
                    .background(Capsule().fill(Color(.tertiarySystemFill)))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var bodyText: some View {
        Text(details?.detail ?? summary.detail)
            .font(.body)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var acknowledgeBlock: some View {
        if summary.requiresAcknowledgement {
            let acknowledged = details?.hasAcknowledged ?? summary.hasAcknowledged ?? false
            let count = details?.acknowledgedCount

            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: acknowledged ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(acknowledged ? .green : .orange)
                    // Split branches so each string is a static LocalizedStringKey
                    // the String Catalog can extract — a ternary inside Text(_:)
                    // would collapse to a runtime `String` and bypass localisation.
                    if acknowledged {
                        Text("You've acknowledged this bulletin.")
                            .font(.subheadline)
                    } else {
                        Text("Please confirm you've read this bulletin.")
                            .font(.subheadline)
                    }
                }

                if let count {
                    Text("\(count) staff acknowledged")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !acknowledged {
                    Button {
                        Task { await acknowledge() }
                    } label: {
                        HStack {
                            if ackInFlight {
                                ProgressView().tint(.white)
                            }
                            Text("Acknowledge")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(ackInFlight)
                }

                if let ackError {
                    Text(ackError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(Spacing.m + Spacing.xs)
            .cardSurface(cornerRadius: CornerRadius.m)
        }
    }

    @ViewBuilder
    private var audienceBlock: some View {
        if let details, !details.audiences.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Audience")
                    .font(.headline)
                FlowLayout(spacing: Spacing.s) {
                    ForEach(details.audiences) { audience in
                        Text(audience.displayName)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.xs)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                            .foregroundStyle(.primary)
                    }
                }
            }
        } else if loadState == .loading {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Audience")
                    .font(.headline)
                HStack(spacing: Spacing.s) {
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
                // Catalog can hold a plural variation for this key ("%lld
                // attachments") via Xcode's editor — the literal stays a
                // LocalizedStringKey so it gets extracted.
                Text("\(summary.attachmentCount) attachments")
                Spacer()
                Text("Coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.m + Spacing.xs)
            .cardSurface(cornerRadius: CornerRadius.m)
        }
    }

    @ViewBuilder
    private var auditFooter: some View {
        if let details {
            VStack(alignment: .leading, spacing: 2) {
                Text("Last updated \(RelativeTime.string(for: details.lastModifiedAt)) by \(details.lastModifiedByName)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }
}

private extension BulletinDetails {
    func withAcknowledged() -> BulletinDetails {
        BulletinDetails(
            id: id,
            directoryId: directoryId,
            expiresAt: expiresAt,
            pinnedAt: pinnedAt,
            title: title,
            detail: detail,
            requiresAcknowledgement: requiresAcknowledgement,
            categoryId: categoryId,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColourCode: categoryColourCode,
            createdById: createdById,
            createdByName: createdByName,
            createdAt: createdAt,
            lastModifiedById: lastModifiedById,
            lastModifiedByName: lastModifiedByName,
            lastModifiedAt: lastModifiedAt,
            version: version,
            audiences: audiences,
            hasAcknowledged: true,
            acknowledgedCount: (acknowledgedCount ?? 0) + 1,
            attachmentCount: attachmentCount
        )
    }
}

/// Wrap-around horizontal stack used for the audience chip row. SwiftUI's
/// built-in `HStack` would just push everything onto one line and clip.
private struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.s

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
        bulletinsService: MockBulletinsService().withDetails(.previewUrgent)
    ))
}

#Preview("Already acknowledged") {
    NavigationStack {
        BulletinDetailView(summary: .previewAcknowledged)
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        bulletinsService: MockBulletinsService().withDetails(.previewAcknowledged)
    ))
}

#Preview("Expired") {
    NavigationStack {
        BulletinDetailView(summary: .previewExpired)
    }
    .environment(AppSession.preview(
        phase: .authenticated(.previewStaff),
        bulletinsService: MockBulletinsService().withDetails(.previewExpired)
    ))
}
#endif
