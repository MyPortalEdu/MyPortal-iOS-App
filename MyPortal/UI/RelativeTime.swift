import Foundation

enum RelativeTime {
    private static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    static func string(for date: Date, reference: Date = Date()) -> String {
        formatter.localizedString(for: date, relativeTo: reference)
    }
}
