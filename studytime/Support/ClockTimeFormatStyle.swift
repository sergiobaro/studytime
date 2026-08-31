import Foundation

/// `25:00`, `59:59`, `1:00:00`.
struct ClockTimeFormatStyle: FormatStyle {
    static let secondsPerMinute = 60
    static let secondsPerHour = 3600

    func format(_ value: Int) -> String {
        // A timer should never render "-00:01" if it overshoots.
        let total = max(0, value)
        let hours = total / Self.secondsPerHour
        let minutes = (total % Self.secondsPerHour) / Self.secondsPerMinute
        let seconds = total % Self.secondsPerMinute

        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}

extension FormatStyle where Self == ClockTimeFormatStyle {
    
    static var clockTime: Self { ClockTimeFormatStyle() }
}
