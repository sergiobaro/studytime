import Foundation
import Synchronization

/// One task's share of a single day's study.
struct TaskTotal: Identifiable, Hashable {
    let taskName: String
    let taskIcon: TaskIcon
    let taskColor: TaskColor
    let seconds: Int

    var id: String { taskName }
}

/// One cell of the month grid: a day, and what was studied on it.
struct CalendarDay: Identifiable, Hashable {
    /// Midnight of the day, which also identifies it.
    let date: Date
    /// `false` for the days of the neighbouring months that pad the grid out
    /// to whole weeks.
    let isInMonth: Bool
    /// Longest first; empty on a day with nothing recorded.
    let taskTotals: [TaskTotal]

    var id: Date { date }

    var totalSeconds: Int {
        taskTotals.reduce(0) { $0 + $1.seconds }
    }

    var hasStudy: Bool { !taskTotals.isEmpty }
}

/// A month laid out as whole weeks, so it can be drawn as a grid directly.
struct CalendarMonth: Hashable {
    /// Midnight on the first of the month.
    let start: Date
    /// Rows of seven days, each starting on the calendar's first weekday.
    let weeks: [[CalendarDay]]

    /// Only the days belonging to this month — the padding is another
    /// month's business.
    var daysInMonth: [CalendarDay] {
        weeks.flatMap { $0 }.filter(\.isInMonth)
    }

    var totalSeconds: Int {
        daysInMonth.reduce(0) { $0 + $1.totalSeconds }
    }

    /// How many days of the month have any study on them.
    var studiedDayCount: Int {
        daysInMonth.count(where: \.hasStudy)
    }

    /// The busiest day's total, which the shading of every other day is
    /// measured against. Zero when the month is empty.
    var busiestSeconds: Int {
        daysInMonth.map(\.totalSeconds).max() ?? 0
    }
}

/// A year as its twelve months, for the year view.
struct CalendarYear: Hashable {
    /// Midnight on the first of January.
    let start: Date
    /// January to December, each laid out as its own grid.
    let months: [CalendarMonth]

    var daysInYear: [CalendarDay] {
        months.flatMap(\.daysInMonth)
    }

    var totalSeconds: Int {
        months.reduce(0) { $0 + $1.totalSeconds }
    }

    var studiedDayCount: Int {
        months.reduce(0) { $0 + $1.studiedDayCount }
    }

    /// The busiest day of the whole year, so every month is shaded on the
    /// same scale and a busy month looks busier than a quiet one.
    var busiestSeconds: Int {
        months.map(\.busiestSeconds).max() ?? 0
    }
}

/// Arranges recorded sessions into months of days.
///
/// The companion to `SessionHistory`: the same sessions, grouped for a grid
/// rather than a list, and split by task within each day.
enum SessionCalendar {

    /// The month `date` falls in, with every day's per-task totals filled in.
    ///
    /// A session counts towards the day it began on, matching
    /// `SessionHistory` — the two would otherwise disagree about a run that
    /// crossed midnight.
    static func month(
        containing date: Date,
        from tasks: [StudyTask],
        calendar: Calendar = .current
    ) -> CalendarMonth {
        month(
            startingOn: monthStart(containing: date, calendar: calendar),
            totals: totalsByDay(from: tasks, calendar: calendar),
            calendar: calendar
        )
    }

    /// The year `date` falls in, month by month.
    static func year(
        containing date: Date,
        from tasks: [StudyTask],
        calendar: Calendar = .current
    ) -> CalendarYear {
        let start = yearStart(containing: date, calendar: calendar)
        // Totalled once and shared, rather than once for every month.
        let totals = totalsByDay(from: tasks, calendar: calendar)
        let months = (0..<12).compactMap { offset -> CalendarMonth? in
            guard let first = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            return month(startingOn: first, totals: totals, calendar: calendar)
        }
        return CalendarYear(start: start, months: months)
    }

    /// Midnight on the first of January of the year `date` falls in.
    static func yearStart(containing date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    /// `2026`, in the calendar's own locale.
    static func title(forYear year: Date, calendar: Calendar = .current) -> String {
        formatter(for: calendar, template: "y").string(from: year)
    }

    /// `March`, for a month's heading in the year view.
    static func shortTitle(forMonth month: Date, calendar: Calendar = .current) -> String {
        formatter(for: calendar, template: "MMMM").string(from: month)
    }

    private static func month(
        startingOn start: Date,
        totals: [Date: [TaskTotal]],
        calendar: Calendar
    ) -> CalendarMonth {
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 0

        // The grid opens on the first weekday of the week the 1st falls in,
        // and runs on to the end of the week the last day falls in.
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let cellCount = Int((Double(leading + dayCount) / 7).rounded(.up)) * 7

        let days = (0..<cellCount).compactMap { offset -> CalendarDay? in
            guard let date = calendar.date(byAdding: .day, value: offset - leading, to: start)
            else { return nil }

            // Adding days can land off midnight across a DST change, so the
            // day is normalised before it is used as a key.
            let midnight = calendar.startOfDay(for: date)
            return CalendarDay(
                date: midnight,
                isInMonth: calendar.isDate(midnight, equalTo: start, toGranularity: .month),
                taskTotals: totals[midnight] ?? []
            )
        }

        return CalendarMonth(start: start, weeks: stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        })
    }

    /// Midnight on the first of the month `date` falls in.
    static func monthStart(containing date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }

    /// The start of the month `months` away from the one `date` falls in.
    static func month(
        offsetBy months: Int,
        from date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let start = monthStart(containing: date, calendar: calendar)
        return calendar.date(byAdding: .month, value: months, to: start) ?? start
    }

    /// `March 2026`, in the calendar's own locale.
    static func title(forMonth month: Date, calendar: Calendar = .current) -> String {
        formatter(for: calendar, template: "MMMM y").string(from: month)
    }

    /// The weekday initials, rotated so the first column is the calendar's
    /// first weekday — Monday in most of Europe, Sunday in the US.
    static func weekdaySymbols(calendar: Calendar = .current) -> [String] {
        let symbols = formatter(for: calendar, template: "EEEEE").veryShortStandaloneWeekdaySymbols
            ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// A day's heading, named for the recent days as in the history list.
    static func title(forDay day: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return formatter(for: calendar, template: "EEEE d MMMM").string(from: day)
    }
}

private extension SessionCalendar {

    /// Every task's seconds on every day that has any, keyed by midnight.
    static func totalsByDay(from tasks: [StudyTask], calendar: Calendar) -> [Date: [TaskTotal]] {
        var secondsByDay: [Date: [String: Int]] = [:]
        // Names are unique, so they are enough to find a task's style again.
        let tasksByName = Dictionary(tasks.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

        for task in tasks {
            for session in task.sessions {
                let day = calendar.startOfDay(for: session.startedAt)
                secondsByDay[day, default: [:]][task.name, default: 0] += session.seconds
            }
        }

        return secondsByDay.mapValues { seconds in
            seconds
                .map { name, seconds in
                    TaskTotal(
                        taskName: name,
                        taskIcon: tasksByName[name]?.icon ?? .default,
                        taskColor: tasksByName[name]?.color ?? .blue,
                        seconds: seconds
                    )
                }
                // Longest first, and by name where two tasks tie, so the
                // order does not shuffle between reads of the dictionary.
                .sorted {
                    $0.seconds == $1.seconds ? $0.taskName < $1.taskName : $0.seconds > $1.seconds
                }
        }
    }

    /// Formats against the given calendar rather than the current one, so a
    /// caller passing a fixed calendar gets fixed output.
    ///
    /// Kept once made: building one from a template is slow enough that the
    /// year view, labelling every day, stalled on it.
    static func formatter(for calendar: Calendar, template: String) -> DateFormatter {
        let key = FormatterKey(calendar: calendar, template: template)
        return formatters.withLock { formatters in
            if let formatter = formatters[key] { return formatter }

            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = calendar.locale ?? .current
            formatter.setLocalizedDateFormatFromTemplate(template)
            formatters[key] = formatter
            return formatter
        }
    }
}

private struct FormatterKey: Hashable {
    let calendar: Calendar
    let template: String
}

/// Shared across threads, as the tests format in parallel.
private let formatters = Mutex<[FormatterKey: DateFormatter]>([:])
