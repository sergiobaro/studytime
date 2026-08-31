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
    
    var displayTime: String {
        seconds.formatted(.clockTime)
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
