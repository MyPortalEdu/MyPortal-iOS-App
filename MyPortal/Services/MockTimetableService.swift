import Foundation

/// Canned timetable for previews + tests. Builder pattern matches the rest
/// of the service mocks so preview call sites read like configuration.
nonisolated struct MockTimetableService: TimetableService {
    var entries: [TimetableEntry] = []
    var error: APIError?

    func withEntries(_ items: [TimetableEntry]) -> Self {
        var copy = self; copy.entries = items; return copy
    }

    func failing(with error: APIError) -> Self {
        var copy = self; copy.error = error; return copy
    }

    func sessions(on date: Date) async throws -> [TimetableEntry] {
        if let error { throw error }
        return entries
    }
}
