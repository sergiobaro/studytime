import Foundation
import Testing
@testable import studytime

struct SessionCalendarTests {

    /// A fixed calendar, so the grid does not depend on where or when the
    /// suite runs. Monday-first, as in most of Europe.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_GB")
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ day: Int, _ hour: Int = 9, month: Int = 3) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(identifier: "UTC"),
            year: 2026, month: month, day: day, hour: hour
        ).date!
    }

    private func session(day: Int, hour: Int = 9, month: Int = 3, seconds: Int) -> StudySession {
        let start = date(day, hour, month: month)
        return StudySession(
            startedAt: start,
            endedAt: start.addingTimeInterval(Double(seconds)),
            seconds: seconds
        )
    }

    private func day(_ month: CalendarMonth, _ number: Int) -> CalendarDay? {
        month.daysInMonth.first { calendar.component(.day, from: $0.date) == number }
    }

    // MARK: - The grid

    @Test func theGridIsWholeWeeksAroundTheMonth() {
        // 1 March 2026 is a Sunday, so a Monday-first grid opens with six
        // days of February and closes on 5 April.
        let month = SessionCalendar.month(containing: date(15), from: [], calendar: calendar)
        let cells = month.weeks.flatMap { $0 }

        #expect(month.weeks.allSatisfy { $0.count == 7 })
        #expect(cells.count % 7 == 0)
        #expect(month.daysInMonth.count == 31)
        #expect(cells.first?.date == calendar.startOfDay(for: date(23, month: 2)))
        #expect(cells.first?.isInMonth == false)
        #expect(cells.last?.isInMonth == false)
        // Every cell is the day after the one before it.
        for (earlier, later) in zip(cells, cells.dropFirst()) {
            #expect(calendar.date(byAdding: .day, value: 1, to: earlier.date) == later.date)
        }
    }

    @Test func theFirstColumnIsTheCalendarsFirstWeekday() {
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1

        let month = SessionCalendar.month(containing: date(15), from: [], calendar: sundayFirst)

        // 1 March 2026 is itself a Sunday, so nothing pads the front.
        #expect(month.weeks.first?.first?.date == calendar.startOfDay(for: date(1)))
        #expect(SessionCalendar.weekdaySymbols(calendar: sundayFirst).first == "S")
        #expect(SessionCalendar.weekdaySymbols(calendar: calendar).first == "M")
        #expect(SessionCalendar.weekdaySymbols(calendar: calendar).count == 7)
    }

    // MARK: - Totals

    @Test func aDaySplitsItsTimeByTask() {
        let tasks = [
            StudyTask(name: "Maths", sessions: [
                session(day: 4, hour: 9, seconds: 600),
                session(day: 4, hour: 15, seconds: 300),
            ]),
            StudyTask(name: "Reading", sessions: [session(day: 4, hour: 11, seconds: 1_800)]),
        ]

        let month = SessionCalendar.month(containing: date(4), from: tasks, calendar: calendar)
        let fourth = day(month, 4)

        #expect(fourth?.totalSeconds == 2_700)
        // Longest first, and the two Maths sessions are summed into one row.
        #expect(fourth?.taskTotals.map(\.taskName) == ["Reading", "Maths"])
        #expect(fourth?.taskTotals.map(\.seconds) == [1_800, 900])
    }

    @Test func tiedTasksAreOrderedByName() {
        let tasks = [
            StudyTask(name: "Reading", sessions: [session(day: 4, seconds: 600)]),
            StudyTask(name: "Maths", sessions: [session(day: 4, seconds: 600)]),
        ]

        let month = SessionCalendar.month(containing: date(4), from: tasks, calendar: calendar)

        #expect(day(month, 4)?.taskTotals.map(\.taskName) == ["Maths", "Reading"])
    }

    @Test func aDayWithNothingOnItIsEmptyRatherThanMissing() {
        let tasks = [StudyTask(name: "Maths", sessions: [session(day: 4, seconds: 600)])]

        let month = SessionCalendar.month(containing: date(4), from: tasks, calendar: calendar)

        #expect(day(month, 5)?.hasStudy == false)
        #expect(day(month, 5)?.totalSeconds == 0)
        #expect(day(month, 4)?.hasStudy == true)
    }

    @Test func onlyTheMonthsOwnSessionsAreCounted() {
        let tasks = [
            StudyTask(name: "Maths", sessions: [
                session(day: 28, month: 2, seconds: 600),
                session(day: 4, month: 3, seconds: 900),
                session(day: 2, month: 4, seconds: 1_200),
            ])
        ]

        let month = SessionCalendar.month(containing: date(4), from: tasks, calendar: calendar)

        #expect(month.totalSeconds == 900)
        #expect(month.studiedDayCount == 1)
        #expect(month.busiestSeconds == 900)
        // February's session still shows in the padding cell it falls on,
        // but it is not part of March's totals.
        let padding = month.weeks.flatMap { $0 }.first { !$0.isInMonth && $0.hasStudy }
        #expect(padding?.totalSeconds == 600)
    }

    @Test func aSessionRunningPastMidnightCountsOnTheDayItBegan() {
        let start = date(4, 23)
        let overnight = StudySession(
            startedAt: start,
            endedAt: start.addingTimeInterval(2 * 3_600),
            seconds: 3_600
        )
        let tasks = [StudyTask(name: "Maths", sessions: [overnight])]

        let month = SessionCalendar.month(containing: start, from: tasks, calendar: calendar)

        #expect(day(month, 4)?.totalSeconds == 3_600)
        #expect(day(month, 5)?.hasStudy == false)
    }

    @Test func anEmptyMonthSummarisesAsZero() {
        let month = SessionCalendar.month(containing: date(15), from: [], calendar: calendar)

        #expect(month.totalSeconds == 0)
        #expect(month.studiedDayCount == 0)
        #expect(month.busiestSeconds == 0)
    }

    // MARK: - Navigation

    @Test func aMonthStartsAtMidnightOnItsFirst() {
        let start = SessionCalendar.monthStart(containing: date(17, 14), calendar: calendar)

        #expect(start == calendar.startOfDay(for: date(1)))
        #expect(SessionCalendar.month(containing: date(17, 14), from: [], calendar: calendar).start == start)
    }

    @Test func steppingMovesWholeMonthsAndWrapsTheYear() {
        let march = SessionCalendar.monthStart(containing: date(17), calendar: calendar)

        let next = SessionCalendar.month(offsetBy: 1, from: march, calendar: calendar)
        let back = SessionCalendar.month(offsetBy: -3, from: march, calendar: calendar)

        #expect(calendar.component(.month, from: next) == 4)
        #expect(calendar.component(.month, from: back) == 12)
        #expect(calendar.component(.year, from: back) == 2025)
        // Stepping from mid-month still lands on the first.
        #expect(SessionCalendar.month(offsetBy: 0, from: date(17), calendar: calendar) == march)
    }

    // MARK: - Titles

    @Test func aMonthIsNamedAndADayIsDated() {
        #expect(SessionCalendar.title(forMonth: date(1), calendar: calendar).contains("March"))
        #expect(SessionCalendar.title(forMonth: date(1), calendar: calendar).contains("2026"))
        #expect(SessionCalendar.title(forDay: date(4), calendar: calendar).contains("March"))
    }

    @Test func recentDaysAreNamedRatherThanDated() {
        let today = Date.now

        #expect(SessionCalendar.title(forDay: today) == "Today")
        #expect(SessionCalendar.title(forDay: today.addingTimeInterval(-24 * 3_600)) == "Yesterday")
    }
}

struct SessionCalendarYearTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_GB")
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(month: Int, day: Int, year: Int = 2026) -> Date {
        DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day, hour: 9).date!
    }

    private func task(_ name: String, sessions: [(Date, Int)]) -> StudyTask {
        var task = StudyTask(name: name)
        task.sessions = sessions.map { StudySession(startedAt: $0, endedAt: $0.addingTimeInterval(Double($1)), seconds: $1) }
        return task
    }

    @Test func aYearIsTwelveMonthsFromJanuary() {
        let year = SessionCalendar.year(containing: date(month: 7, day: 14), from: [], calendar: calendar)

        #expect(year.start == calendar.startOfDay(for: date(month: 1, day: 1)))
        #expect(year.months.count == 12)
        #expect(year.months.map { calendar.component(.month, from: $0.start) } == Array(1...12))
        #expect(year.daysInYear.count == 365)
    }

    @Test func yearTotalsAddUpItsMonthsAndLeaveOutOtherYears() {
        let maths = task("Maths", sessions: [
            (date(month: 1, day: 5), 600),
            (date(month: 1, day: 5), 300),
            (date(month: 11, day: 20), 1_800),
            (date(month: 12, day: 31, year: 2025), 3_600),
        ])

        let year = SessionCalendar.year(containing: date(month: 3, day: 1), from: [maths], calendar: calendar)

        #expect(year.totalSeconds == 2_700)
        #expect(year.studiedDayCount == 2)
        #expect(year.busiestSeconds == 1_800)
    }

    @Test func theYearTitleIsTheYear() {
        #expect(SessionCalendar.title(forYear: date(month: 5, day: 1), calendar: calendar) == "2026")
        #expect(SessionCalendar.shortTitle(forMonth: date(month: 5, day: 1), calendar: calendar) == "May")
    }
}
