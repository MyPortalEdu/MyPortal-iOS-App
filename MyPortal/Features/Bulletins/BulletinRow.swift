import SwiftUI

struct BulletinRow: View {
    let bulletin: BulletinSummary

    private var categoryColor: Color {
        Color(hex: bulletin.categoryColourCode)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconSquare

            VStack(alignment: .leading, spacing: 4) {
                metaRow
                Text(bulletin.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(bulletin.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(categoryColor, lineWidth: 0)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(categoryColor)
                .frame(width: 4)
                .clipShape(RoundedCornerShape(radius: 12, corners: [.topLeft, .bottomLeft]))
        }
        .opacity(bulletin.isExpired ? 0.55 : 1)
    }

    private var iconSquare: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(categoryColor.opacity(0.15))
            Image(systemName: FontAwesomeMapping.sfSymbol(for: bulletin.categoryIcon))
                .foregroundStyle(categoryColor)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(width: 36, height: 36)
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            Text(bulletin.categoryName.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(categoryColor)
                .lineLimit(1)

            if let createdAt = bulletin.createdAt {
                Text("·").foregroundStyle(.secondary)
                Text(RelativeTime.string(for: createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text("·").foregroundStyle(.secondary)
            Text(bulletin.createdByName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 6)

            badges
        }
    }

    @ViewBuilder
    private var badges: some View {
        HStack(spacing: 8) {
            if bulletin.attachmentCount > 0 {
                Label("\(bulletin.attachmentCount)", systemImage: "paperclip")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if bulletin.isExpired {
                Label("Expired", systemImage: "clock")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            } else {
                if bulletin.requiresAcknowledgement {
                    if bulletin.hasAcknowledged == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                if bulletin.isPinned {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.tint)
                        .font(.caption)
                }
            }
        }
    }
}

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#if DEBUG
#Preview("Default") {
    BulletinRow(bulletin: .previewAnnouncement)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Pinned + ack required") {
    BulletinRow(bulletin: .previewUrgent)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Expired") {
    BulletinRow(bulletin: .previewExpired)
        .padding()
        .background(Color(.systemGroupedBackground))
}
#endif
