#if DEBUG
import Foundation

nonisolated extension TimetableEntry {
    /// A typical staff day used by previews — five lessons split around break
    /// and lunch, drawn from a fixed 08:45 anchor so the visuals are stable.
    static let previewToday: [TimetableEntry] = {
        let cal = Calendar(identifier: .iso8601)
        let dayStart = cal.startOfDay(for: Date())
        func slot(_ hour: Int, _ minute: Int, length: Int) -> (Date, Date) {
            let start = cal.date(byAdding: .minute, value: hour * 60 + minute, to: dayStart)!
            let end = cal.date(byAdding: .minute, value: length, to: start)!
            return (start, end)
        }
        let (s1, e1) = slot(8, 45, length: 55)
        let (s2, e2) = slot(9, 45, length: 55)
        let (s3, e3) = slot(11, 5, length: 55)
        let (s4, e4) = slot(13, 0, length: 55)
        let (s5, e5) = slot(14, 0, length: 55)
        return [
            TimetableEntry(
                id: UUID(uuidString: "55555555-1111-1111-1111-111111111111")!,
                periodName: "P1",
                startTime: s1, endTime: e1,
                subjectName: "Mathematics",
                classGroupName: "10X/Ma1",
                roomName: "M12"
            ),
            TimetableEntry(
                id: UUID(uuidString: "55555555-2222-2222-2222-222222222222")!,
                periodName: "P2",
                startTime: s2, endTime: e2,
                subjectName: "Mathematics",
                classGroupName: "8Y/Ma2",
                roomName: "M12"
            ),
            TimetableEntry(
                id: UUID(uuidString: "55555555-3333-3333-3333-333333333333")!,
                periodName: "P3",
                startTime: s3, endTime: e3,
                subjectName: "Form time",
                classGroupName: "10X",
                roomName: nil
            ),
            TimetableEntry(
                id: UUID(uuidString: "55555555-4444-4444-4444-444444444444")!,
                periodName: "P4",
                startTime: s4, endTime: e4,
                subjectName: "Further Mathematics",
                classGroupName: "12A/FMa",
                roomName: "M14"
            ),
            TimetableEntry(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                periodName: "P5",
                startTime: s5, endTime: e5,
                subjectName: nil,
                classGroupName: "Duty — North yard",
                roomName: nil
            )
        ]
    }()
}
#endif
