import Foundation

/// One lesson on a staff member's timetable.
///
/// Wire contract (to be implemented backend-side):
/// `GET /api/me/sessions?date=YYYY-MM-DD` → `[TimetableEntry]`.
nonisolated struct TimetableEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let periodName: String
    let startTime: Date
    let endTime: Date
    let subjectName: String?
    let classGroupName: String
    let roomName: String?
}
