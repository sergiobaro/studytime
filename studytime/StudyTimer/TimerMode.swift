import Foundation

enum TimerMode: String, CaseIterable, Identifiable {
    case countdown /// Counts down from a chosen duration and stops at zero.
    case stopwatch /// Counts up from zero with no upper bound.

    var id: String { rawValue }

    var title: String {
        switch self {
        case .countdown: "Countdown"
        case .stopwatch: "Stopwatch"
        }
    }
}
