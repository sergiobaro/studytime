import Foundation
import Testing
@testable import studytime

struct SessionHistoryTests {

    /// A fixed calendar and clock, so grouping does not depend on when the
    /// suite runs or where it runs.
    let calendar = Calendar(identifier: .gregorian)

    private func date(_ day: Int, _ hour: Int) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(identifier: "UTC"),
            year: 2026, month: 3, day: day, hour: hour
        ).date!
    }

    private func session(day: Int, hour: Int, seconds: Int) -> StudySession {
        let start = date(day, hour)
        return StudySession(
            startedAt: start,
            endedAt: start.addingTimeInterval(Double(seconds)),
            seconds: seconds
        )
    }

    private var utcCalendar: Calendar {
        var calendar = self.calendar
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test func noSessionsMakesNoDays() {
        let tasks = [StudyTask(name: "Maths"), StudyTask(name: "Reading")]

        #expect(SessionHistory.days(from: tasks, calendar: utcCalendar).isEmpty)
    }

    @Test func sessionsAreGroupedByTheDayTheyStarted() {
        let tasks = [
            StudyTask(name: "Maths", sessions: [
                session(day: 1, hour: 9, seconds: 600),
                session(day: 2, hour: 10, seconds: 300),
            ])
        ]

        let days = SessionHistory.days(from: tasks, calendar: utcCalendar)

        #expect(days.count == 2)
        // Newest day first.
        #expect(days.first?.date == utcCalendar.startOfDay(for: date(2, 10)))
        #expect(days.last?.date == utcCalendar.startOfDay(for: date(1, 9)))
    }

    @Test func aDaySumsTheTimeCountedAcrossTasks() {
        let tasks = [
            StudyTask(name: "Maths", sessions: [session(day: 1, hour: 9, seconds: 600)]),
            StudyTask(name: "Reading", sessions: [session(day: 1, hour: 14, seconds: 900)]),
        ]

        let days = SessionHistory.days(from: tasks, calendar: utcCalendar)

        #expect(days.count == 1)
        #expect(days.first?.totalSeconds == 1500)
        // Newest session first, and each keeps its task's name.
        #expect(days.first?.sessions.map(\.taskName) == ["Reading", "Maths"])
    }

    @Test func aSessionRunningPastMidnightBelongsToTheDayItBegan() {
        let start = date(1, 23)
        let overnight = StudySession(
            startedAt: start,
            endedAt: start.addingTimeInterval(2 * 3600),
            seconds: 3600
        )
        let tasks = [StudyTask(name: "Maths", sessions: [overnight])]

        let days = SessionHistory.days(from: tasks, calendar: utcCalendar)

        #expect(days.count == 1)
        #expect(days.first?.date == utcCalendar.startOfDay(for: start))
    }

    @Test func filteringNarrowsTheHistoryToOneTask() {
        let maths = StudyTask(name: "Maths", sessions: [session(day: 1, hour: 9, seconds: 600)])
        let reading = StudyTask(name: "Reading", sessions: [session(day: 1, hour: 14, seconds: 900)])

        let days = SessionHistory.days(from: [maths, reading], matching: reading.id, calendar: utcCalendar)

        #expect(days.count == 1)
        #expect(days.first?.sessions.map(\.taskName) == ["Reading"])
        // The day total counts only the filtered task, not the 1500 of both.
        #expect(days.first?.totalSeconds == 900)
    }

    @Test func filteringByATaskThatIsNotThereShowsNothing() {
        let tasks = [StudyTask(name: "Maths", sessions: [session(day: 1, hour: 9, seconds: 600)])]

        let days = SessionHistory.days(from: tasks, matching: UUID(), calendar: utcCalendar)

        #expect(days.isEmpty)
    }

    @Test func notFilteringKeepsEveryTask() {
        let tasks = [
            StudyTask(name: "Maths", sessions: [session(day: 1, hour: 9, seconds: 600)]),
            StudyTask(name: "Reading", sessions: [session(day: 1, hour: 14, seconds: 900)]),
        ]

        let days = SessionHistory.days(from: tasks, matching: nil, calendar: utcCalendar)

        #expect(days.first?.sessions.count == 2)
    }

    @Test func onlyTasksWithSessionsAreWorthFiltering() {
        let maths = StudyTask(name: "Maths", sessions: [session(day: 1, hour: 9, seconds: 600)])
        // Studied time but no recorded sessions: stored before sessions existed.
        let legacy = StudyTask(name: "German", studiedSeconds: 600)
        let fresh = StudyTask(name: "Reading")

        let options = SessionHistory.tasksWithSessions(in: [maths, legacy, fresh])

        #expect(options.map(\.name) == ["Maths"])
    }

    @Test func recentDaysAreNamedRatherThanDated() {
        let today = Date()
        let yesterday = today.addingTimeInterval(-24 * 3600)
        let older = today.addingTimeInterval(-10 * 24 * 3600)

        #expect(SessionHistory.title(for: today) == "Today")
        #expect(SessionHistory.title(for: yesterday) == "Yesterday")
        #expect(SessionHistory.title(for: older) != "Today")
        #expect(SessionHistory.title(for: older) != "Yesterday")
    }

    @Test func everySessionKeepsItsOwnIdentity() {
        let tasks = [
            StudyTask(name: "Maths", sessions: [
                session(day: 1, hour: 9, seconds: 600),
                session(day: 1, hour: 11, seconds: 600),
            ])
        ]

        let recorded = SessionHistory.days(from: tasks, calendar: utcCalendar).flatMap(\.sessions)

        #expect(Set(recorded.map(\.id)).count == recorded.count)
    }
}
