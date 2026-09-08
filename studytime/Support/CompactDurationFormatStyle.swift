import Foundation

/// `45m`, `1h`, `2h 15m` — a duration short enough to sit inside a calendar
/// cell, where `ClockTimeFormatStyle`'s `02:15:00` would not fit.
///
/// Seconds are dropped rather than rounded up: a day summed from whole
/// sessions is never interesting to the second, and `<1m` says plainly that
/// something was recorded without claiming a minute that was not studied.
struct CompactDurationFormatStyle: FormatStyle {

    func format(_ value: Int) -> String {
        let total = max(0, value)
        let hours = total / ClockTimeFormatStyle.secondsPerHour
        let minutes = (total % ClockTimeFormatStyle.secondsPerHour)
            / ClockTimeFormatStyle.secondsPerMinute

        switch (hours, minutes) {
        case (0, 0): return total == 0 ? "0m" : "<1m"
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(minutes)m"
        }
    }
}

extension FormatStyle where Self == CompactDurationFormatStyle {

    static var compactDuration: Self { CompactDurationFormatStyle() }
}
