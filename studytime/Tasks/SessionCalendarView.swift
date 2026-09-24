import SwiftUI

/// A month at a time: how much was studied on each day, and — for the day
/// picked out — which tasks that time went to.
///
/// Left in the system appearance for the same reason as `TaskEditor` and
/// `SessionHistoryView`: it is its own sheet, not part of the timer window.
struct SessionCalendarView: View {
    let tasks: TaskList
    /// Supplies the colour days are shaded and selected in.
    var theme: BackgroundTheme = .system

    @Environment(\.calendar) private var calendar

    /// The first of the month on show.
    @State private var visibleMonth = SessionCalendar.monthStart(containing: .now)
    /// Midnight of the day whose breakdown is listed, if one is picked.
    @State private var selectedDay: Date?

    /// Fixed for the lifetime of the sheet: the grid should not re-mark
    /// "today" underneath the user at midnight.
    private let today = Date.now

    private var month: CalendarMonth {
        SessionCalendar.month(containing: visibleMonth, from: tasks.tasks, calendar: calendar)
    }

    var body: some View {
        let month = self.month

        return VStack(alignment: .leading, spacing: 14) {
            header

            // The picked day's tasks sit beside the month rather than under
            // it, so the grid keeps its height and the list its own column.
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    weekdayHeader

                    grid(for: month)

                    Text(summary(of: month))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 420)

                Divider()

                breakdown(in: month)
                    .frame(width: 240)
            }
        }
        .padding()
        .frame(minWidth: 720, minHeight: 420)
        .onAppear(perform: selectTodayIfStudied)
    }
}

// MARK: - Month navigation

private extension SessionCalendarView {

    var header: some View {
        HStack(spacing: 8) {
            SheetCloseButton()

            Text("Calendar")
                .font(.headline)

            Spacer()

            Button { step(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            .help("Previous month")
            .accessibilityLabel("Previous month")

            Text(SessionCalendar.title(forMonth: visibleMonth, calendar: calendar))
                .font(.headline)
                // A fixed slot, so the arrows do not shuffle as the month
                // name changes length.
                .frame(minWidth: 150)

            Button { step(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
            .help("Next month")
            .accessibilityLabel("Next month")
            // Nothing can have been studied in a month that has not started.
            .disabled(!canStepForward)

            Button("Today") {
                visibleMonth = SessionCalendar.monthStart(containing: today, calendar: calendar)
                selectTodayIfStudied()
            }
            .disabled(calendar.isDate(visibleMonth, equalTo: today, toGranularity: .month))
        }
        .buttonStyle(.borderless)
    }

    var canStepForward: Bool {
        visibleMonth < SessionCalendar.monthStart(containing: today, calendar: calendar)
    }

    func step(by months: Int) {
        visibleMonth = SessionCalendar.month(offsetBy: months, from: visibleMonth, calendar: calendar)
        // The selection belongs to the month it was made in.
        selectedDay = nil
        selectTodayIfStudied()
    }

    /// Opens on today's tasks when there are any, so the sheet says something
    /// useful before anything is clicked.
    func selectTodayIfStudied() {
        let midnight = calendar.startOfDay(for: today)
        guard calendar.isDate(midnight, equalTo: visibleMonth, toGranularity: .month),
              month.daysInMonth.contains(where: { $0.date == midnight && $0.hasStudy })
        else { return }

        selectedDay = midnight
    }
}

// MARK: - Grid

private extension SessionCalendarView {

    var weekdayHeader: some View {
        HStack(spacing: 4) {
            // The symbols repeat across the week (S, T), so the index has to
            // carry the identity.
            ForEach(Array(SessionCalendar.weekdaySymbols(calendar: calendar).enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    func grid(for month: CalendarMonth) -> some View {
        VStack(spacing: 4) {
            ForEach(month.weeks, id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(week) { day in
                        cell(for: day, busiest: month.busiestSeconds)
                    }
                }
            }
        }
    }

    func cell(for day: CalendarDay, busiest: Int) -> some View {
        let level = shadingLevel(for: day, busiest: busiest)

        return Button {
            // Only a day of the month on show, and only one with something
            // to break down, is worth selecting.
            selectedDay = (day.isInMonth && day.hasStudy) ? day.date : nil
        } label: {
            VStack(spacing: 1) {
                Text(dayNumber(of: day))
                    .font(.system(size: 13, weight: isToday(day) ? .bold : .regular))

                Text(day.hasStudy ? day.totalSeconds.formatted(.compactDuration) : " ")
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(foreground(for: day, level: level))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(fill(for: day, level: level))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(border(for: day), lineWidth: isSelected(day) ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!day.isInMonth || !day.hasStudy)
        .help(day.isInMonth ? accessibilityLabel(for: day) : "")
        .accessibilityLabel(accessibilityLabel(for: day))
    }

    func dayNumber(of day: CalendarDay) -> String {
        "\(calendar.component(.day, from: day.date))"
    }

    func isToday(_ day: CalendarDay) -> Bool {
        calendar.isDate(day.date, inSameDayAs: today)
    }

    func isSelected(_ day: CalendarDay) -> Bool {
        day.isInMonth && day.date == selectedDay
    }

    /// 0 for a day with nothing on it, then 1–4 by how the day compares with
    /// the busiest one in the month — the shading is relative, so a quiet
    /// month still reads as a range rather than as one flat block.
    func shadingLevel(for day: CalendarDay, busiest: Int) -> Int {
        guard day.hasStudy, busiest > 0 else { return 0 }
        let ratio = Double(day.totalSeconds) / Double(busiest)
        return min(4, max(1, Int((ratio * 4).rounded(.up))))
    }

    func fill(for day: CalendarDay, level: Int) -> Color {
        guard day.isInMonth else { return .clear }
        guard level > 0 else { return Color.secondary.opacity(0.08) }
        return theme.highlight.opacity([0, 0.22, 0.42, 0.66, 0.9][level])
    }

    func foreground(for day: CalendarDay, level: Int) -> Color {
        guard day.isInMonth else { return Color.secondary.opacity(0.45) }
        // The darkest two fills need light text on top of them.
        return level >= 3 ? .white : .primary
    }

    func border(for day: CalendarDay) -> Color {
        if isSelected(day) { return theme.highlight }
        if isToday(day) && day.isInMonth { return Color.secondary.opacity(0.7) }
        return .clear
    }

    func accessibilityLabel(for day: CalendarDay) -> String {
        let title = SessionCalendar.title(forDay: day.date, calendar: calendar)
        guard day.hasStudy else { return "\(title), nothing studied" }
        return "\(title), \(day.totalSeconds.formatted(.compactDuration)) studied"
    }
}

// MARK: - The selected day

private extension SessionCalendarView {

    @ViewBuilder
    func breakdown(in month: CalendarMonth) -> some View {
        let day = month.daysInMonth.first { $0.date == selectedDay }

        VStack(alignment: .leading, spacing: 8) {
            if let day {
                HStack {
                    Text(SessionCalendar.title(forDay: day.date, calendar: calendar))
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(day.totalSeconds.formatted(.clockTime))
                        .font(.subheadline)
                        .monospacedDigit()
                }

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(day.taskTotals) { total in
                            taskRow(total, of: day.totalSeconds)
                        }
                    }
                }
            } else {
                Text(placeholder(for: month))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    /// A task's time, with a bar behind it for its share of the day.
    func taskRow(_ total: TaskTotal, of dayTotal: Int) -> some View {
        let share = dayTotal > 0 ? Double(total.seconds) / Double(dayTotal) : 0

        return HStack {
            TaskIconView(icon: total.taskIcon, color: total.taskColor)
                .frame(width: 16)

            Text(total.taskName)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(total.seconds.formatted(.clockTime))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(alignment: .leading) {
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(total.taskColor.color.opacity(0.22))
                    .frame(width: proxy.size.width * share)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.secondary.opacity(0.07))
        )
        .accessibilityElement(children: .combine)
    }

    func placeholder(for month: CalendarMonth) -> String {
        month.studiedDayCount == 0
            ? "Nothing studied this month."
            : "Pick a day to see which tasks its time went to."
    }

    func summary(of month: CalendarMonth) -> String {
        guard month.studiedDayCount > 0 else { return "No study recorded" }
        let days = month.studiedDayCount == 1 ? "1 day" : "\(month.studiedDayCount) days"
        return "\(month.totalSeconds.formatted(.clockTime)) across \(days)"
    }
}

#Preview {
    let clock = PreviewClock()
    let tasks = TaskList(store: CalendarPreviewStore(), now: { clock.now })

    tasks.add(named: "Maths")
    tasks.add(named: "Reading")

    for (offset, minutes) in [(0, 45), (1, 90), (3, 25), (6, 120), (9, 60)] {
        clock.now = Date.now.addingTimeInterval(-Double(offset) * 24 * 3600)
        for task in tasks.tasks {
            tasks.selectedTaskID = task.id
            tasks.recordStudied(seconds: minutes * 60)
            tasks.endSession()
        }
    }

    return SessionCalendarView(tasks: tasks)
}

/// A mutable clock, so the preview can record sessions on past days.
private final class PreviewClock {
    var now = Date.now
}

/// Keeps previews out of the real `UserDefaults`.
private final class CalendarPreviewStore: KeyValueStore {
    private var storage: [String: Any] = [:]

    func object(forKey key: String) -> Any? { storage[key] }

    func set(_ value: Any?, forKey key: String) {
        if let value { storage[key] = value } else { storage.removeValue(forKey: key) }
    }

    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}
