import Foundation

nonisolated struct LiveTimetableService: TimetableService {
    let apiClient: APIClient

    func sessions(on date: Date) async throws -> [TimetableEntry] {
        let day = Self.dayFormatter.string(from: date)
        return try await apiClient.get("api/me/sessions?date=\(day)")
    }

    /// Server expects a calendar-day key, not an instant — strip the time
    /// component so a 23:30 local "today" doesn't accidentally request
    /// tomorrow's sessions in UTC.
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
