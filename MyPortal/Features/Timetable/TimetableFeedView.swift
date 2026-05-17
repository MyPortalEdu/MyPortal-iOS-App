import SwiftUI

/// Load state for the timetable card. Mirrors `BulletinsLoadState` so both
/// cards on the home screen feel consistent (skeleton → list/empty → error).
enum TimetableLoadState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// Today's lessons — presentational only. Designed to sit inside a `HomeCard`.
struct TimetableFeedView: View {
    let state: TimetableLoadState
    let entries: [TimetableEntry]
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            loadingSkeleton
        case .loaded:
            if entries.isEmpty {
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
                HStack(spacing: Spacing.m) {
                    RoundedRectangle(cornerRadius: CornerRadius.s, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 56, height: 36)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill))
                            .frame(height: 12).frame(maxWidth: 180, alignment: .leading)
                        RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill))
                            .frame(height: 10).frame(maxWidth: 120, alignment: .leading)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading timetable")
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "calendar.badge.checkmark")
                .foregroundStyle(.secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing scheduled today")
                    .font(.subheadline.weight(.medium))
                Text("You don't have any lessons on your timetable for today.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.s)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                TimetableRow(entry: entry, isCurrent: Self.isCurrent(entry))
                if index < entries.count - 1 {
                    Divider().padding(.leading, 72)
                }
            }
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Couldn't load timetable")
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

    /// "Now" badge logic — pulled out so previews are deterministic regardless
    /// of wall-clock time (rows the preview lays out won't necessarily be live).
    private static func isCurrent(_ entry: TimetableEntry) -> Bool {
        let now = Date()
        return entry.startTime <= now && now < entry.endTime
    }
}

private struct TimetableRow: View {
    let entry: TimetableEntry
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            VStack(alignment: .center, spacing: 2) {
                Text(entry.periodName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(timeRange)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(width: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.subjectName ?? entry.classGroupName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: Spacing.xs) {
                    if entry.subjectName != nil {
                        Text(entry.classGroupName)
                    }
                    if let room = entry.roomName, !room.isEmpty {
                        if entry.subjectName != nil {
                            Text("·").foregroundStyle(.tertiary)
                        }
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(room)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: Spacing.xs)

            if isCurrent {
                Text("Now")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Currently in progress")
            }
        }
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return "\(f.string(from: entry.startTime))"
    }
}

#if DEBUG
#Preview("Loaded") {
    TimetableFeedView(
        state: .loaded,
        entries: TimetableEntry.previewToday,
        onRetry: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    TimetableFeedView(state: .loaded, entries: [], onRetry: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Loading") {
    TimetableFeedView(state: .loading, entries: [], onRetry: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Error") {
    TimetableFeedView(
        state: .error("The server returned a 500."),
        entries: [],
        onRetry: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
