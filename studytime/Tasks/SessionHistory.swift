import Foundation

/// A session paired with the task it was recorded against, so sessions from
/// different tasks can be listed together.
struct RecordedSession: Identifiable, Hashable {
    let taskName: String
    let session: StudySession

    var id: StudySession.ID { session.id }
}

/// The sessions recorded on one day.
struct SessionDay: Identifiable, Hashable {
    /// Midnight of the day, which also identifies it.
    let date: Date
    /// Newest first.
    let sessions: [RecordedSession]

    var id: Date { date }

    var totalSeconds: Int {
        sessions.reduce(0) { $0 + $1.session.seconds }
    }
}

/// Groups recorded sessions for display.
enum SessionHistory {

    /// Every session across every task, grouped by the day it started on:
    /// newest day first, and newest session first within a day.
    ///
    /// A session that runs past midnight belongs to the day it began on —
    /// splitting it would invent time that was never recorded as two runs.
    static func days(from tasks: [StudyTask], calendar: Calendar = .current) -> [SessionDay] {
        let recorded = tasks.flatMap { task in
            task.sessions.map { RecordedSession(taskName: task.name, session: $0) }
        }

        return Dictionary(grouping: recorded) { calendar.startOfDay(for: $0.session.startedAt) }
            .map { date, sessions in
                SessionDay(
                    date: date,
                    sessions: sessions.sorted { $0.session.startedAt > $1.session.startedAt }
                )
            }
            .sorted { $0.date > $1.date }
    }

    /// A day's heading: the recent days are named rather than dated, which is
    /// how someone thinks about the study they have just done.
    static func title(for day: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    /// When a session ran, as clock times: `14:05 – 14:35`.
    static func timeRange(of session: StudySession) -> String {
        let start = session.startedAt.formatted(date: .omitted, time: .shortened)
        let end = session.endedAt.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }
}
