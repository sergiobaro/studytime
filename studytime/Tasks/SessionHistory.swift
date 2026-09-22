import Foundation

/// A session paired with the task it was recorded against, so sessions from
/// different tasks can be listed together.
struct RecordedSession: Identifiable, Hashable {
    let taskID: StudyTask.ID
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
    ///
    /// Passing a `taskID` narrows the history to that one task; the day
    /// totals then count only its sessions, which is the point of filtering.
    static func days(
        from tasks: [StudyTask],
        matching taskID: StudyTask.ID? = nil,
        calendar: Calendar = .current
    ) -> [SessionDay] {
        let matched = taskID.map { id in tasks.filter { $0.id == id } } ?? tasks
        let recorded = matched.flatMap { task in
            task.sessions.map { RecordedSession(taskID: task.id, taskName: task.name, session: $0) }
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

    /// The tasks a filter can usefully offer: one with no sessions would
    /// only ever select an empty list.
    static func tasksWithSessions(in tasks: [StudyTask]) -> [StudyTask] {
        tasks.filter { !$0.sessions.isEmpty }
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
