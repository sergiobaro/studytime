import Foundation
import Testing
@testable import studytime

struct StudyTimerTests {
    
    let store: InMemoryKeyValueStore
    let timer: StudyTimer

    /// Swift Testing builds a fresh instance per test, so each case gets its
    /// own empty store.
    init() {
        self.store = InMemoryKeyValueStore()
        self.timer = StudyTimer(store: store)
    }

    @Test func countdownStartsAtDurationAndCountsDown() {
        timer.durationMinutes = 25

        #expect(timer.mode == .countdown)
        #expect(timer.seconds == 25 * 60)

        timer.toggle()
        timer.tick()

        #expect(timer.isRunning)
        #expect(timer.seconds == 25 * 60 - 1)
    }

    @Test func countdownStopsAtZero() {
        timer.durationMinutes = 1
        timer.toggle()

        for _ in 0..<60 { timer.tick() }

        #expect(timer.seconds == 0)
        #expect(!timer.isRunning)
        #expect(timer.isFinished)

        // Further ticks must not drive it negative.
        timer.tick()
        #expect(timer.seconds == 0)
    }

    @Test func finishedCountdownCannotRestartUntilReset() {
        timer.durationMinutes = 1
        timer.toggle()
        for _ in 0..<60 { timer.tick() }

        timer.toggle()
        #expect(!timer.isRunning)
        #expect(!timer.canStart)

        timer.reset()
        #expect(timer.seconds == 60)
        #expect(timer.canStart)
    }

    @Test func stopwatchStartsAtZeroAndCountsUp() {
        timer.mode = .stopwatch

        #expect(timer.seconds == 0)
        #expect(!timer.isFinished)

        timer.toggle()
        for _ in 0..<3 { timer.tick() }

        #expect(timer.seconds == 3)
        #expect(timer.isRunning)
    }

    @Test func stopwatchRunsPastAnHour() {
        timer.mode = .stopwatch
        timer.toggle()

        for _ in 0..<3661 { timer.tick() }

        #expect(timer.seconds == 3661)
        #expect(timer.isRunning)
        #expect(timer.displayTime == "1:01:01")
    }

    @Test func switchingModeStopsAndResets() {
        timer.durationMinutes = 10
        timer.toggle()
        timer.tick()
        #expect(timer.isRunning)

        timer.mode = .stopwatch
        #expect(!timer.isRunning)
        #expect(timer.seconds == 0)

        timer.toggle()
        timer.tick()
        timer.mode = .countdown
        #expect(!timer.isRunning)
        #expect(timer.seconds == 10 * 60)
    }

    @Test func pauseHoldsTheClock() {
        timer.mode = .stopwatch
        timer.toggle()
        timer.tick()
        timer.toggle()

        #expect(!timer.isRunning)
        timer.tick()
        #expect(timer.seconds == 1)
    }

    @Test func changingDurationResetsOnlyTheCountdown() {
        timer.durationMinutes = 30
        #expect(timer.seconds == 30 * 60)

        timer.mode = .stopwatch
        timer.toggle()
        timer.tick()
        timer.durationMinutes = 45

        #expect(timer.seconds == 1)
        #expect(timer.isRunning)
    }

    @Test func durationIsClampedToSupportedRange() {
        timer.durationMinutes = 0
        #expect(timer.durationMinutes == StudyTimer.durationRange.lowerBound)

        timer.durationMinutes = 9_999
        #expect(timer.durationMinutes == StudyTimer.durationRange.upperBound)
    }

    @Test func modeAndDurationSurviveRelaunch() {
        timer.durationMinutes = 42
        timer.mode = .stopwatch

        // A second timer over the same store stands in for a relaunch.
        let relaunched = StudyTimer(store: store)
        #expect(relaunched.mode == .stopwatch)
        #expect(relaunched.durationMinutes == 42)
    }

    @Test func anEmptyStoreFallsBackToTheDefaults() {
        #expect(timer.mode == StudyTimer.defaultMode)
        #expect(timer.durationMinutes == StudyTimer.defaultDurationMinutes)
        #expect(store.object(forKey: "timerMode") == nil)
        #expect(store.object(forKey: "durationMinutes") == nil)
    }

    @Test func anUnrecognisedStoredModeFallsBackToTheDefault() {
        let loaded = StudyTimer(store: InMemoryKeyValueStore(["timerMode": "hourglass"]))

        #expect(loaded.mode == StudyTimer.defaultMode)
    }

    @Test func aStoredValueOfTheWrongTypeFallsBackToTheDefault() {
        let loaded = StudyTimer(store: InMemoryKeyValueStore(["durationMinutes": "forty-two"]))

        #expect(loaded.durationMinutes == StudyTimer.defaultDurationMinutes)
    }

    @Test func anOutOfRangeStoredDurationIsClampedOnLoad() {
        let loaded = StudyTimer(store: InMemoryKeyValueStore(["durationMinutes": 9_999]))

        #expect(loaded.durationMinutes == StudyTimer.durationRange.upperBound)
        #expect(loaded.seconds == StudyTimer.durationRange.upperBound * 60)
    }
}
