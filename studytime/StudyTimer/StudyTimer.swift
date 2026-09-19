import Foundation

@Observable
final class StudyTimer {
    static let durationRange = 1...180
    static let defaultMode = TimerMode.countdown
    static let defaultDurationMinutes = 25
    
    private enum Key {
        static let mode = "timerMode"
        static let durationMinutes = "durationMinutes"
    }
    
    private var storedMode: TimerMode
    private var storedDurationMinutes: Int
    
    /// Seconds remaining in `.countdown`, seconds elapsed in `.stopwatch`.
    private(set) var seconds: Int
    private(set) var isRunning = false
    /// How long the current pause has lasted, or how long ago a countdown ran
    /// out. Zero whenever the timer is neither paused nor finished.
    private(set) var pausedSeconds = 0
    private let store: KeyValueStore
    
    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
        
        let storedMode: String? = store.value(forKey: Key.mode)
        let storedDuration: Int? = store.value(forKey: Key.durationMinutes)
        
        let mode = storedMode.flatMap(TimerMode.init(rawValue:)) ?? Self.defaultMode
        let durationMinutes = Self.clampDuration(storedDuration ?? Self.defaultDurationMinutes)
        
        self.storedMode = mode
        self.storedDurationMinutes = durationMinutes
        self.seconds = Self.startingSeconds(for: mode, durationMinutes: durationMinutes)
    }
}

extension StudyTimer {
    
    // Switching modes stops the clock and resets it to the new mode's starting value
    var mode: TimerMode {
        get { storedMode }
        set {
            guard newValue != storedMode else { return }
            storedMode = newValue
            store.set(newValue.rawValue, forKey: Key.mode)
            reset()
        }
    }
    
    var durationMinutes: Int {
        get { storedDurationMinutes }
        set {
            let clamped = Self.clampDuration(newValue)
            guard clamped != storedDurationMinutes else { return }
            storedDurationMinutes = clamped
            store.set(clamped, forKey: Key.durationMinutes)
            if storedMode == .countdown { reset() }
        }
    }
    
    var isFinished: Bool {
        switch mode {
        case .stopwatch: return false // a stopwarch never finishes
        case .countdown: return (seconds == 0)
        }
    }
    
    var canStart: Bool {
        isRunning || !isFinished
    }

    /// True while there is a session to finish: the clock is running, paused
    /// mid-session, or sitting on a countdown that has run out. A timer still
    /// on its starting value has nothing to finish.
    var isActive: Bool {
        isRunning || isPaused || isFinished
    }

    /// True once the clock has moved away from its starting value but has not
    /// been reset, so the next start continues the session rather than opening one.
    var isPaused: Bool {
        !isRunning && !isFinished && seconds != Self.startingSeconds(for: mode, durationMinutes: durationMinutes)
    }
    
    var displayTime: String {
        seconds.formatted(.clockTime)
    }

    var pausedTime: String {
        pausedSeconds.formatted(.clockTime)
    }
    
    func toggle() {
        if isRunning {
            isRunning = false
        } else if !isFinished {
            isRunning = true
        } else {
            // A finished countdown can't restart, and keeps counting the time
            // since it ran out.
            return
        }
        // Each pause is timed on its own, from the moment it starts.
        pausedSeconds = 0
    }

    func reset() {
        isRunning = false
        seconds = Self.startingSeconds(for: mode, durationMinutes: durationMinutes)
        pausedSeconds = 0
    }

    /// Advances the clock by one second. While paused, or once a countdown
    /// has run out, the second goes to `pausedSeconds` instead.
    ///
    /// Returns whether a second of study was actually counted, so the caller
    /// can credit it to the selected task.
    @discardableResult
    func tick() -> Bool {
        guard isRunning else {
            if isPaused || isFinished { pausedSeconds += 1 }
            return false
        }
        
        switch mode {
        case .countdown:
            guard seconds > 0 else {
                isRunning = false
                return false
            }
            seconds -= 1
            if seconds == 0 {
                isRunning = false
            }
            return true
        case .stopwatch:
            seconds += 1
            return true
        }
    }
}

private extension StudyTimer {

    static func startingSeconds(for mode: TimerMode, durationMinutes: Int) -> Int {
        switch mode {
        case .countdown: durationMinutes * 60
        case .stopwatch: 0
        }
    }

    static func clampDuration(_ minutes: Int) -> Int {
        min(max(minutes, durationRange.lowerBound), durationRange.upperBound)
    }
}
