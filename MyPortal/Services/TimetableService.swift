import Foundation

/// Domain service for the timetable feature. Returns a staff member's lessons
/// for a given calendar day — the home-screen card shows "today", but the
/// API is date-parameterised so a future "tomorrow" / week view can reuse it.
///
/// Wire contract (backend not yet implemented):
/// `GET /api/me/sessions?date=YYYY-MM-DD` → `[TimetableEntry]`.
protocol TimetableService: Sendable {
    func sessions(on date: Date) async throws -> [TimetableEntry]
}
