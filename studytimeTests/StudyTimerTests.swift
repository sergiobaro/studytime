import Foundation
import Testing
@testable import studytime

struct StudyTimerTests {

    /// Each test gets an isolated defaults suite so persistence never leaks
    /// between cases or into the real app domain.
    private static func makeTimer() -> StudyTimer {
        let suiteName = "StudyTimerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return StudyTimer(defaults: defaults)
    }

    @Test func countdownStartsAtDurationAndCountsDown() {
        let timer = Self.makeTimer()
        timer.durationMinutes = 25

        #expect(timer.mode == .countdown)
        #expect(timer.seconds == 25 * 60)

        timer.toggle()
        timer.tick()

        #expect(timer.isRunning)
        #expect(timer.seconds == 25 * 60 - 1)
    }

    @Test func countdownStopsAtZero() {
        let timer = Self.makeTimer()
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
        let timer = Self.makeTimer()
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
        let timer = Self.makeTimer()
        timer.mode = .stopwatch

        #expect(timer.seconds == 0)
        #expect(!timer.isFinished)

        timer.toggle()
        for _ in 0..<3 { timer.tick() }

        #expect(timer.seconds == 3)
        #expect(timer.isRunning)
    }

    @Test func stopwatchRunsPastAnHour() {
        let timer = Self.makeTimer()
        timer.mode = .stopwatch
        timer.toggle()

        for _ in 0..<3661 { timer.tick() }

        #expect(timer.seconds == 3661)
        #expect(timer.isRunning)
        #expect(timer.displayTime == "1:01:01")
    }

    @Test func switchingModeStopsAndResets() {
        let timer = Self.makeTimer()
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
        let timer = Self.makeTimer()
        timer.mode = .stopwatch
        timer.toggle()
        timer.tick()
        timer.toggle()

        #expect(!timer.isRunning)
        timer.tick()
        #expect(timer.seconds == 1)
    }

    @Test func changingDurationResetsOnlyTheCountdown() {
        let timer = Self.makeTimer()
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
        let timer = Self.makeTimer()

        timer.durationMinutes = 0
        #expect(timer.durationMinutes == StudyTimer.durationRange.lowerBound)

        timer.durationMinutes = 9_999
        #expect(timer.durationMinutes == StudyTimer.durationRange.upperBound)
    }

    @Test(arguments: [
        (0, "00:00"),
        (59, "00:59"),
        (60, "01:00"),
        (1500, "25:00"),
        (3599, "59:59"),
        (3600, "1:00:00"),
        (10_800, "3:00:00"),
    ])
    func formattingSwitchesToHoursPastAnHour(seconds: Int, expected: String) {
        #expect(StudyTimer.formatted(seconds) == expected)
    }

    @Test func modeAndDurationSurviveRelaunch() {
        let suiteName = "StudyTimerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let first = StudyTimer(defaults: defaults)
        first.durationMinutes = 42
        first.mode = .stopwatch

        let second = StudyTimer(defaults: defaults)
        #expect(second.mode == .stopwatch)
        #expect(second.durationMinutes == 42)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
