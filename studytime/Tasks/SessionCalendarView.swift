import SwiftUI

/// A month or a whole year at a time: how much was studied on each day, and —
/// for the day picked out — which tasks that time went to.
///
/// Left in the system appearance for the same reason as `TaskEditor` and
/// `SessionHistoryView`: it is its own sheet, not part of the timer window.
struct SessionCalendarView: View {
    let tasks: TaskList
    /// Supplies the colour days are shaded and selected in.
    var theme: BackgroundTheme = .system

    @Environment(\.calendar) private var calendar

    @State private var scope = CalendarScope.month
    /// The first of the month on show — or, in the year view, of a month in
    /// the year on show.
    @State private var visibleMonth = SessionCalendar.monthStart(containing: .now)
    /// Midnight of the day whose breakdown is listed, if one is picked.
    @State private var selectedDay: Date?

    /// Fixed for the lifetime of the sheet: the grid should not re-mark
    /// "today" underneath the user at midnight.
    private let today = Date.now

    private var month: CalendarMonth {
        SessionCalendar.month(containing: visibleMonth, from: tasks.tasks, calendar: calendar)
    }

    private var year: CalendarYear {
        SessionCalendar.year(containing: visibleMonth, from: tasks.tasks, calendar: calendar)
    }

    /// Every day on show that can be selected.
    private var visibleDays: [CalendarDay] {
        switch scope {
        case .month: month.daysInMonth
        case .year: year.daysInYear
        }
    }

    var body: some View {
        // Built once per update and shared, rather than once for the grid
        // and again for the breakdown.
        let month = scope == .month ? self.month : nil
        let year = scope == .year ? self.year : nil

        return VStack(alignment: .leading, spacing: 14) {
            header

            // The picked day's tasks sit beside the grid rather than under
            // it, so the grid keeps its height and the list its own column.
            HStack(alignment: .top, spacing: 16) {
                // The same column for both, so the divider and the
                // breakdown stay put when switching between them.
                Group {
                    if let month {
                        monthView(month)
                    } else if let year {
                        yearView(year)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                Divider()

                breakdown(in: month?.daysInMonth ?? year?.daysInYear ?? [])
                    .frame(width: 240)
            }
        }
        .padding()
        // A fixed width rather than one fitted to the content: the month and
        // year grids want different widths, and the sheet would otherwise
        // resize — shifting everything in it — on every switch.
        .frame(width: 720)
        .frame(minHeight: 420)
        .onAppear(perform: selectTodayIfStudied)
        .onChange(of: scope) { _, scope in
            // Narrowing a year to a month opens on the month of the day
            // picked in it, so the pick stays on show.
            if scope == .month, let selectedDay, !calendar.isDate(selectedDay, equalTo: visibleMonth, toGranularity: .month) {
                visibleMonth = SessionCalendar.monthStart(containing: selectedDay, calendar: calendar)
            }
            if !visibleDays.contains(where: { $0.date == selectedDay }) { selectedDay = nil }
            selectTodayIfStudied()
        }
    }

    private func monthView(_ month: CalendarMonth) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            weekdayHeader

            grid(for: month)

            Text(summary(seconds: month.totalSeconds, days: month.studiedDayCount))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

/// An arrow for stepping between months or years, with a full square to
/// click rather than just the chevron — a borderless button only responds
/// where its label draws — and a chip under the pointer to show it.
private struct StepArrowLabel: View {
    let systemImage: String

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .frame(width: 28, height: 28)
            .background(
                Circle().fill(Color.secondary.opacity(isHovered && isEnabled ? 0.15 : 0))
            )
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}

/// Whether the calendar shows one month or a whole year.
enum CalendarScope: String, CaseIterable, Identifiable {
    case month
    case year

    var id: Self { self }

    var title: String {
        switch self {
        case .month: "Month"
        case .year: "Year"
        }
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

            Picker("View", selection: $scope) {
                ForEach(CalendarScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            Spacer()

            Button { step(by: -1) } label: {
                StepArrowLabel(systemImage: "chevron.left")
            }
            .help("Previous \(scope.rawValue)")
            .accessibilityLabel("Previous \(scope.rawValue)")

            Text(visibleTitle)
                .font(.headline)
                // A fixed slot, so the arrows do not shuffle as the month
                // name changes length.
                .frame(minWidth: 150)

            Button { step(by: 1) } label: {
                StepArrowLabel(systemImage: "chevron.right")
            }
            .help("Next \(scope.rawValue)")
            .accessibilityLabel("Next \(scope.rawValue)")
            // Nothing can have been studied in a month that has not started.
            .disabled(!canStepForward)

            Button("Today") {
                visibleMonth = currentMonth
                selectedDay = nil
                selectTodayIfStudied()
            }
            .disabled(calendar.isDate(visibleMonth, equalTo: today, toGranularity: granularity))
        }
        .buttonStyle(.borderless)
    }

    var visibleTitle: String {
        switch scope {
        case .month: SessionCalendar.title(forMonth: visibleMonth, calendar: calendar)
        case .year: SessionCalendar.title(forYear: visibleMonth, calendar: calendar)
        }
    }

    var granularity: Calendar.Component {
        scope == .month ? .month : .year
    }

    var currentMonth: Date {
        SessionCalendar.monthStart(containing: today, calendar: calendar)
    }

    var canStepForward: Bool {
        !calendar.isDate(visibleMonth, equalTo: today, toGranularity: granularity)
            && visibleMonth < currentMonth
    }

    func step(by steps: Int) {
        let months = scope == .month ? steps : steps * 12
        let stepped = SessionCalendar.month(offsetBy: months, from: visibleMonth, calendar: calendar)
        // A year on from a late month can overshoot this one; stop at today.
        visibleMonth = min(stepped, currentMonth)
        // The selection belongs to the month or year it was made in.
        selectedDay = nil
        selectTodayIfStudied()
    }

    /// Opens on today's tasks when there are any, so the sheet says something
    /// useful before anything is clicked.
    func selectTodayIfStudied() {
        let midnight = calendar.startOfDay(for: today)
        guard selectedDay == nil,
              visibleDays.contains(where: { $0.date == midnight && $0.hasStudy })
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
        let level = Self.shadingLevel(for: day, busiest: busiest)

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
    static func shadingLevel(for day: CalendarDay, busiest: Int) -> Int {
        guard day.hasStudy, busiest > 0 else { return 0 }
        let ratio = Double(day.totalSeconds) / Double(busiest)
        return min(4, max(1, Int((ratio * 4).rounded(.up))))
    }

    func fill(for day: CalendarDay, level: Int) -> Color {
        Self.fill(for: day, level: level, highlight: theme.highlight)
    }

    static func fill(for day: CalendarDay, level: Int, highlight: Color) -> Color {
        guard day.isInMonth else { return .clear }
        guard level > 0 else { return Color.secondary.opacity(0.08) }
        return highlight.opacity([0, 0.22, 0.42, 0.66, 0.9][level])
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
        Self.accessibilityLabel(for: day, calendar: calendar)
    }

    static func accessibilityLabel(for day: CalendarDay, calendar: Calendar) -> String {
        let title = SessionCalendar.title(forDay: day.date, calendar: calendar)
        guard day.hasStudy else { return "\(title), nothing studied" }
        return "\(title), \(day.totalSeconds.formatted(.compactDuration)) studied"
    }
}

// MARK: - Year

private extension SessionCalendarView {

    func yearView(_ year: CalendarYear) -> some View {
        let midnight = calendar.startOfDay(for: today)

        return VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(MiniMonthView.width), spacing: 12, alignment: .top),
                    count: 4
                ),
                alignment: .leading,
                spacing: 14
            ) {
                ForEach(year.months, id: \.start) { month in
                    MiniMonthView(
                        month: month,
                        busiest: year.busiestSeconds,
                        selectedDay: selectedDay.flatMap { day in
                            calendar.isDate(day, equalTo: month.start, toGranularity: .month) ? day : nil
                        },
                        today: midnight,
                        highlight: theme.highlight,
                        calendar: calendar,
                        onSelect: { selectedDay = $0 },
                        onOpen: {
                            visibleMonth = month.start
                            scope = .month
                        }
                    )
                    .equatable()
                }
            }

            Text(summary(seconds: year.totalSeconds, days: year.studiedDayCount))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

/// A month of the year view: a block of small squares, headed by its name —
/// which opens the month on its own.
///
/// Its own view, compared by value, so an update redraws only the months that
/// changed: the timer ticking every second touches today's month alone, and
/// picking a day only the months it moves between.
private struct MiniMonthView: View, Equatable {
    let month: CalendarMonth
    let busiest: Int
    /// Only when it falls in this month, so a pick elsewhere leaves it alone.
    let selectedDay: Date?
    /// Midnight today.
    let today: Date
    let highlight: Color
    let calendar: Calendar
    let onSelect: (Date) -> Void
    let onOpen: () -> Void

    private static let cellSize: CGFloat = 11
    private static let spacing: CGFloat = 2
    static let width = cellSize * 7 + spacing * 6

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.month == rhs.month
            && lhs.busiest == rhs.busiest
            && lhs.selectedDay == rhs.selectedDay
            && lhs.today == rhs.today
            && lhs.highlight == rhs.highlight
            && lhs.calendar == rhs.calendar
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: onOpen) {
                Text(SessionCalendar.shortTitle(forMonth: month.start, calendar: calendar))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrentMonth ? highlight : .primary)
            }
            .buttonStyle(.plain)
            .help("Show \(SessionCalendar.title(forMonth: month.start, calendar: calendar))")

            VStack(spacing: Self.spacing) {
                ForEach(month.weeks, id: \.self) { week in
                    HStack(spacing: Self.spacing) {
                        ForEach(week) { day in
                            cell(for: day)
                        }
                    }
                }
            }
        }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(month.start, equalTo: today, toGranularity: .month)
    }

    /// Only a studied day is a button: the rest have nothing to show, and
    /// hundreds of buttons, each with a tooltip, were slow to lay out.
    @ViewBuilder
    private func cell(for day: CalendarDay) -> some View {
        let square = square(for: day)

        if day.isInMonth && day.hasStudy {
            let label = SessionCalendarView.accessibilityLabel(for: day, calendar: calendar)
            Button { onSelect(day.date) } label: { square }
                .buttonStyle(.plain)
                .help(label)
                .accessibilityLabel(label)
        } else if day.isInMonth {
            square
                .accessibilityLabel(SessionCalendarView.accessibilityLabel(for: day, calendar: calendar))
        } else {
            square.accessibilityHidden(true)
        }
    }

    private func square(for day: CalendarDay) -> some View {
        let level = SessionCalendarView.shadingLevel(for: day, busiest: busiest)
        let isSelected = day.isInMonth && day.date == selectedDay

        return RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(SessionCalendarView.fill(for: day, level: level, highlight: highlight))
            .overlay(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .strokeBorder(border(for: day, isSelected: isSelected), lineWidth: isSelected ? 1.5 : 1)
            )
            .frame(width: Self.cellSize, height: Self.cellSize)
    }

    private func border(for day: CalendarDay, isSelected: Bool) -> Color {
        if isSelected { return highlight }
        if day.isInMonth && day.date == today { return Color.secondary.opacity(0.7) }
        return .clear
    }
}

// MARK: - The selected day

private extension SessionCalendarView {

    @ViewBuilder
    func breakdown(in days: [CalendarDay]) -> some View {
        let day = days.first { $0.date == selectedDay }

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
                Text(placeholder(hasStudy: days.contains(where: \.hasStudy)))
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

    func placeholder(hasStudy: Bool) -> String {
        hasStudy
            ? "Pick a day to see which tasks its time went to."
            : "Nothing studied this \(scope.rawValue)."
    }

    func summary(seconds: Int, days: Int) -> String {
        guard days > 0 else { return "No study recorded" }
        let dayCount = days == 1 ? "1 day" : "\(days) days"
        return "\(seconds.formatted(.clockTime)) across \(dayCount)"
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
