import Foundation

/// Drives the session clock for both timer modes.
///
/// The view owns one of these and calls `tick()` once a second; every state
/// transition lives here so it can be exercised without a running app.
@Observable
final class StudyTimer {
    static let durationRange = 1...180

    private enum Key {
        static let mode = "timerMode"
        static let durationMinutes = "durationMinutes"
    }

    // `mode` and `durationMinutes` are computed over private storage rather
    // than stored properties with `didSet`. The @Observable macro rewrites
    // stored properties into computed ones, so assigning to a property inside
    // its own `didSet` re-enters the generated setter and recurses forever.
    private var storedMode: TimerMode
    private var storedDurationMinutes: Int

    /// Switching modes stops the clock and resets it to the new mode's
    /// starting value, so a half-finished countdown never keeps running
    /// unseen behind the stopwatch.
    var mode: TimerMode {
        get { storedMode }
        set {
            guard newValue != storedMode else { return }
            storedMode = newValue
            defaults.set(newValue.rawValue, forKey: Key.mode)
            reset()
        }
    }

    var durationMinutes: Int {
        get { storedDurationMinutes }
        set {
            let clamped = Self.clampDuration(newValue)
            guard clamped != storedDurationMinutes else { return }
            storedDurationMinutes = clamped
            defaults.set(clamped, forKey: Key.durationMinutes)
            if storedMode == .countdown { reset() }
        }
    }

    /// Seconds remaining in `.countdown`, seconds elapsed in `.stopwatch`.
    private(set) var seconds: Int
    private(set) var isRunning = false

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedMode = defaults.string(forKey: Key.mode).flatMap(TimerMode.init(rawValue:))
        let storedDuration = defaults.object(forKey: Key.durationMinutes) as? Int

        let mode = storedMode ?? .countdown
        let durationMinutes = Self.clampDuration(storedDuration ?? 25)

        self.storedMode = mode
        self.storedDurationMinutes = durationMinutes
        self.seconds = Self.startingSeconds(for: mode, durationMinutes: durationMinutes)
    }

    /// A finished countdown has nothing left to run; a stopwatch never finishes.
    var isFinished: Bool {
        mode == .countdown && seconds == 0
    }

    var canStart: Bool {
        isRunning || !isFinished
    }

    var displayTime: String {
        Self.formatted(seconds)
    }

    func toggle() {
        if isRunning {
            isRunning = false
        } else if !isFinished {
            isRunning = true
        }
    }

    func reset() {
        isRunning = false
        seconds = Self.startingSeconds(for: mode, durationMinutes: durationMinutes)
    }

    /// Advances the clock by one second. Ignored while paused.
    func tick() {
        guard isRunning else { return }

        switch mode {
        case .countdown:
            guard seconds > 0 else {
                isRunning = false
                return
            }
            seconds -= 1
            if seconds == 0 {
                isRunning = false
            }
        case .stopwatch:
            seconds += 1
        }
    }

    private static func startingSeconds(for mode: TimerMode, durationMinutes: Int) -> Int {
        switch mode {
        case .countdown: durationMinutes * 60
        case .stopwatch: 0
        }
    }

    private static func clampDuration(_ minutes: Int) -> Int {
        min(max(minutes, durationRange.lowerBound), durationRange.upperBound)
    }

    /// `MM:SS` under an hour, `H:MM:SS` at or above it — the stopwatch and a
    /// long countdown both run past 60 minutes.
    static func formatted(_ totalSeconds: Int) -> String {
        let total = max(0, totalSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}
