import Foundation

/// The two ways the app can measure a study session.
enum TimerMode: String, CaseIterable, Identifiable {
    /// Counts down from a chosen duration and stops at zero.
    case countdown
    /// Counts up from zero with no upper bound.
    case stopwatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countdown: "Countdown"
        case .stopwatch: "Stopwatch"
        }
    }
}
